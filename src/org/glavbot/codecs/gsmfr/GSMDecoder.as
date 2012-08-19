package org.glavbot.codecs.gsmfr {

	import flash.utils.ByteArray;

	/**
	 * GSM-FR Decoder
	 * 
	 * @author Vasiliy Vasilyev developer@flashgate.org
	 */
	public class GSMDecoder {

		private static const FAC: Vector.<int> = new <int>[18431, 20479, 22527, 24575, 26623, 28671, 30719, 32767];
		private static const QLB: Vector.<int> = new <int>[3277, 11469, 21299, 32767];

		private var dp: Vector.<int> = new Vector.<int>(280, true);
		private var larpp0: Vector.<int> = new Vector.<int>(8, true);
		private var larpp1: Vector.<int> = new Vector.<int>(8, true);
		private var v: Vector.<int> = new Vector.<int>(9, true);
		private var larc: Vector.<int> = new Vector.<int>(8, true);
		private var nc: Vector.<int> = new Vector.<int>(4, true);
		private var mc: Vector.<int> = new Vector.<int>(4, true);
		private var bc: Vector.<int> = new Vector.<int>(4, true);
		private var xmaxc: Vector.<int> = new Vector.<int>(4, true);
		private var xmc: Vector.<int> = new Vector.<int>(52, true);
		private var erp: Vector.<int> = new Vector.<int>(40, true);
		private var xmp: Vector.<int> = new Vector.<int>(13, true);
		private var larp: Vector.<int> = new Vector.<int>(8, true);
		
		private var wt: Vector.<int> = new Vector.<int>(GSM.FRAME_SAMPLES, true);
		private var s: Vector.<int> = new Vector.<int>(GSM.FRAME_SAMPLES, true);

		private var nrp: int;
		private var msr: int;
		private var j: int;

		public function GSMDecoder() {
		}

		/**
		 * @param frame		33 bytes of GSM-FR encoded data
		 * @return			160 samples of PCM 8000Hz 16bit
		 */
		public function decode(frame: ByteArray): Vector.<int> {
			var i: int = frame.position;
			var j: int;
			var k: int;

			if ((frame[i] >> 4 & 0xf) != 13) {
				throw new GSMError(GSMError.BAD_FRAME_DATA);
			}

			larc[0] = (frame[i++] & 0xf) << 2 | frame[i] >> 6 & 3;
			larc[1] = frame[i++] & 0x3f;
			larc[2] = frame[i] >> 3 & 0x1f;
			larc[3] = (frame[i++] & 7) << 2 | frame[i] >> 6 & 3;
			larc[4] = frame[i] >> 2 & 0xf;
			larc[5] = (frame[i++] & 3) << 2 | frame[i] >> 6 & 3;
			larc[6] = frame[i] >> 3 & 7;
			larc[7] = frame[i++] & 7;

			for (j = 0; j < 4; j++) {
				nc[j] = frame[i] >> 1 & 0x7f;
				bc[j] = (frame[i++] & 1) << 1 | frame[i] >> 7 & 1;
				mc[j] = frame[i] >> 5 & 3;
				xmaxc[j] = (frame[i++] & 0x1f) << 1 | frame[i] >> 7 & 1;
				xmc[k++] = frame[i] >> 4 & 7;
				xmc[k++] = frame[i] >> 1 & 7;
				xmc[k++] = (frame[i++] & 1) << 2 | frame[i] >> 6 & 3;
				xmc[k++] = frame[i] >> 3 & 7;
				xmc[k++] = frame[i++] & 7;
				xmc[k++] = frame[i] >> 5 & 7;
				xmc[k++] = frame[i] >> 2 & 7;
				xmc[k++] = (frame[i++] & 3) << 1 | frame[i] >> 7 & 1;
				xmc[k++] = frame[i] >> 4 & 7;
				xmc[k++] = frame[i] >> 1 & 7;
				xmc[k++] = (frame[i++] & 1) << 2 | frame[i] >> 6 & 3;
				xmc[k++] = frame[i] >> 3 & 7;
				xmc[k++] = frame[i++] & 7;
			}

			frame.position += GSM.FRAME_SIZE;

			for (j = 0; j < 4; j++) {
				predecode(xmaxc[j], mc[j], xmc, j * 13, erp);
				longTermSynthesis(nc[j], bc[j], erp);

				for (k = 0; k < 40; k++) {
					wt[j * 40 + k] = dp[120 + k];
				}
			}

			shortTermSynthesis(larc, wt, s);
			postprocessing(s);

			return s;
		}

		private function postprocessing(s: Vector.<int>): void {
			var i: int = 0;

			for (var k: int = 160; k-- > 0;) {
				var tmp: int = mult_r(msr, 28180);
				msr = add(s[i], tmp);
				s[i] = saturate(add(msr, msr) & -8);
				i++;
			}
		}

		private function shortTermSynthesis(larc: Vector.<int>, wt: Vector.<int>, s: Vector.<int>): void {
			var larpp0: Vector.<int> = j ? this.larpp0 : this.larpp1;
			var larpp1: Vector.<int> = j ? this.larpp1 : this.larpp0;
			j ^= 1;

			decodingOfTheCodedLogAreaRatios(larc, larpp0);
			coefficients_0_12(larpp1, larpp0, larp);
			normalize(larp);
			shortTermSynthesisFiltering(larp, 13, wt, s, 0);
			coefficients_13_26(larpp1, larpp0, larp);
			normalize(larp);
			shortTermSynthesisFiltering(larp, 14, wt, s, 13);
			coefficients_27_39(larpp1, larpp0, larp);
			normalize(larp);
			shortTermSynthesisFiltering(larp, 13, wt, s, 27);
			coefficients_40_159(larpp0, larp);
			normalize(larp);
			shortTermSynthesisFiltering(larp, 120, wt, s, 40);
		}

		private function shortTermSynthesisFiltering(rrp: Vector.<int>, k: int, wt: Vector.<int>, sr: Vector.<int>, off: int): void {
			var woff: int = off;
			var soff: int = off;

			while (k-- > 0) {
				var sri: int = wt[woff++];

				for (var i: int = 8; i-- > 0;) {
					var tmp1: int = rrp[i];
					var tmp2: int = v[i];

					tmp2 = tmp1 != -32768 || tmp2 != -32768 ? saturate(tmp1 * tmp2 + 16384 >> 15) : 32767;
					sri = sub(sri, tmp2);
					tmp1 = tmp1 != -32768 || sri != -32768 ? saturate(tmp1 * sri + 16384 >> 15) : 32767;
					v[i + 1] = add(v[i], tmp1);
				}

				sr[soff++] = v[0] = sri;
			}
		}

		private function normalize(larp: Vector.<int>): void {
			var value: int;

			for (var i: int = 0; i < 8; i++) {
				if (larp[i] < 0) {
					value = larp[i] != -32768 ? -larp[i] : 32767;
					larp[i] = -(value >= 11059 ? value >= 20070 ? add(value >> 2, 26112) : value + 11059 : value << 1);
				} else {
					value = larp[i];
					larp[i] = value >= 11059 ? value >= 20070 ? add(value >> 2, 26112) : value + 11059 : value << 1;
				}
			}
		}

		private function coefficients_0_12(larpp0: Vector.<int>, larpp1: Vector.<int>, larp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				larp[i] = add(larpp0[i] >> 2, larpp1[i] >> 2);
				larp[i] = add(larp[i], larpp0[i] >> 1);
			}
		}

		private function coefficients_13_26(larpp0: Vector.<int>, larpp1: Vector.<int>, larp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				larp[i] = add(larpp0[i] >> 1, larpp1[i] >> 1);
			}
		}

		private function coefficients_27_39(larpp0: Vector.<int>, larpp1: Vector.<int>, larp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				larp[i] = add(larpp0[i] >> 2, larpp1[i] >> 2);
				larp[i] = add(larp[i], larpp1[i] >> 1);
			}
		}

		private function coefficients_40_159(larpp: Vector.<int>, larp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				larp[i] = larpp[i];
			}
		}

		private function decodingOfTheCodedLogAreaRatios(larc: Vector.<int>, larpp: Vector.<int>): void {
			var value: int = add(larc[0], -32) << 10;
			value = mult_r(13107, value);
			larpp[0] = add(value, value);
			value = add(larc[1], -32) << 10;
			value = mult_r(13107, value);
			larpp[1] = add(value, value);
			value = add(larc[2], -16) << 10;
			value = sub(value, 4096);
			value = mult_r(13107, value);
			larpp[2] = add(value, value);
			value = add(larc[3], -16) << 10;
			value = sub(value, -5120);
			value = mult_r(13107, value);
			larpp[3] = add(value, value);
			value = add(larc[4], -8) << 10;
			value = sub(value, 188);
			value = mult_r(19223, value);
			larpp[4] = add(value, value);
			value = add(larc[5], -8) << 10;
			value = sub(value, -3584);
			value = mult_r(17476, value);
			larpp[5] = add(value, value);
			value = add(larc[6], -4) << 10;
			value = sub(value, -682);
			value = mult_r(31454, value);
			larpp[6] = add(value, value);
			value = add(larc[7], -4) << 10;
			value = sub(value, -2288);
			value = mult_r(29708, value);
			larpp[7] = add(value, value);
		}

		private function longTermSynthesis(ncr: int, bcr: int, erp: Vector.<int>): void {
			var nr: int = (ncr >= 40 && ncr <= 120) ? ncr : nrp;
			var brp: int = QLB[bcr];
			var k: int;

			nrp = nr;

			for (k = 0; k <= 39; k++) {
				var drpp: int = mult_r(brp, dp[120 + (k - nr)]);
				dp[120 + k] = add(erp[k], drpp);
			}

			for (k = 0; k <= 119; k++) {
				dp[k] = dp[40 + k];
			}
		}

		private function predecode(xmaxc: int, mc: int, xmc: Vector.<int>, offset: Number, erp: Vector.<int>): void {
			var exp: int = 0;

			if (xmaxc > 15) {
				exp = (xmaxc >> 3) - 1;
			}

			var mant: int = xmaxc - (exp << 3);

			if (mant == 0) {
				exp = -4;
				mant = 7;
			} else {
				while (mant <= 7) {
					mant = mant << 1 | 1;
					exp--;
				}
				mant -= 8;
			}

			dequantization(xmc, offset, exp, mant, xmp);
			positioning(mc, xmp, erp);
		}

		private function positioning(mc: int, xmp: Vector.<int>, ep: Vector.<int>): void {
			var i: int = 13;
			var epo: int = 0;
			var po: int = 0;

			switch (mc) {
				case 3:
					ep[(epo++)] = 0;
				case 2:
					ep[(epo++)] = 0;
				case 1:
					ep[(epo++)] = 0;
				case 0:
					ep[(epo++)] = xmp[(po++)];
					i--;
			}

			do {
				ep[epo++] = 0;
				ep[epo++] = 0;
				ep[epo++] = xmp[po++];
				i--;
			} while (i > 0);

			while (++mc < 4) {
				ep[epo++] = 0;
			}
		}

		private function dequantization(xmc: Vector.<int>, offset: Number, exp: int, mant: int, xmp: Vector.<int>): void {
			var temp1: int = FAC[mant];
			var temp2: int = sub(6, exp);
			var temp3: int = asl(1, sub(temp2, 1));
			var p: int = 0;

			for (var i: int = 13; i-- > 0;) {
				var temp: int = (xmc[offset++] << 1) - 7;
				temp <<= 12;
				temp = mult_r(temp1, temp);
				temp = add(temp, temp3);
				xmp[p++] = asr(temp, temp2);
			}
		}

		private static function saturate(x: int): int {
			return x >= -32768 ? x <= 32767 ? x : 32767 : -32768;
		}

		private static function sub(a: int, b: int): int {
			return saturate(a - b);
		}

		private static function add(a: int, b: int): int {
			return saturate(a + b);
		}

		private static function asl(a: int, n: int): int {
			if (n >= 16)
				return 0;
			if (n <= -16)
				return a >= 0 ? 0 : -1;
			if (n < 0)
				return asr(a, -n);
			else
				return a << n;
		}

		private static function asr(a: int, n: int): int {
			if (n >= 16)
				return a >= 0 ? 0 : -1;
			if (n <= -16)
				return 0;
			if (n < 0)
				return a << -n;
			else
				return a >> n;
		}

		private static function mult_r(a: int, b: int): int {
			if (b == -32768 && a == -32768) {
				return 32767;
			} else {
				var prod: int = a * b + 16384;
				return saturate(prod >> 15);
			}
		}

	}
}
