package org.glavbot.codecs.gsmfr {

	import flash.geom.Point;
	import flash.utils.ByteArray;

	/**
	 * GSM-FR Decoder
	 * 
	 * @author Vasiliy Vasilyev developer@flashgate.org
	 */
	public class GSMDecoder {

		private var dp: Vector.<int> = new Vector.<int>(280, true);
		private var larp: Vector.<int> = new Vector.<int>(8, true);
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
		private var wt: Vector.<int> = new Vector.<int>(160, true);
		private var samples: Vector.<int> = new Vector.<int>(160, true);
		private var mantis: Point = new Point();
		private var nrp: int;
		private var msr: int;
		private var j: int;

		public function GSMDecoder() {
			super();
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
				for (k = 0; k < 160; k++) {
					samples[k] = 0;
				}
				return samples;
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

			shortTermSynthesis(larc, wt, samples);
			postprocessing(samples);

			return samples;
		}

		private function postprocessing(s: Vector.<int>): void {
			var i: int = 0;

			for (var k: int = 160; k-- > 0;) {
				var tmp: int = GSM.mult_r(msr, 28180);
				msr = GSM.add(s[i], tmp);
				s[i] = GSM.saturate(GSM.add(msr, msr) & -8);
				i++;
			}
		}

		private function shortTermSynthesis(larc: Vector.<int>, wt: Vector.<int>, s: Vector.<int>): void {
			var larpp0: Vector.<int> = j ? this.larpp0 : this.larpp1;
			var larpp1: Vector.<int> = j ? this.larpp1 : this.larpp0;
			j ^= 1;

			decodeLAR(larc, larpp0);
			GSM.coefficients_0_12(larpp1, larpp0, larp);
			GSM.normalize(larp);
			shortTermSynthesisFiltering(larp, 13, wt, s, 0);
			GSM.coefficients_13_26(larpp1, larpp0, larp);
			GSM.normalize(larp);
			shortTermSynthesisFiltering(larp, 14, wt, s, 13);
			GSM.coefficients_27_39(larpp1, larpp0, larp);
			GSM.normalize(larp);
			shortTermSynthesisFiltering(larp, 13, wt, s, 27);
			GSM.coefficients_40_159(larpp0, larp);
			GSM.normalize(larp);
			shortTermSynthesisFiltering(larp, 120, wt, s, 40);
		}

		private function shortTermSynthesisFiltering(rrp: Vector.<int>, k: int, wt: Vector.<int>, samples: Vector.<int>, offset: int): void {
			var woff: int = offset;
			var soff: int = offset;

			while (k-- > 0) {
				var sri: int = wt[woff++];

				for (var i: int = 8; i-- > 0;) {
					var r: int = rrp[i];
					var value: int = v[i];

					value = r != -32768 || value != -32768 ? GSM.saturate(r * value + 16384 >> 15) : 32767;
					sri = GSM.sub(sri, value);
					r = r != -32768 || sri != -32768 ? GSM.saturate(r * sri + 16384 >> 15) : 32767;
					v[i + 1] = GSM.add(v[i], r);
				}

				samples[soff++] = v[0] = sri;
			}
		}

		private function decodeLAR(larc: Vector.<int>, larpp: Vector.<int>): void {
			var value: int = GSM.add(larc[0], -32) << 10;
			value = GSM.mult_r(13107, value);
			larpp[0] = GSM.add(value, value);
			value = GSM.add(larc[1], -32) << 10;
			value = GSM.mult_r(13107, value);
			larpp[1] = GSM.add(value, value);
			value = GSM.add(larc[2], -16) << 10;
			value = GSM.sub(value, 4096);
			value = GSM.mult_r(13107, value);
			larpp[2] = GSM.add(value, value);
			value = GSM.add(larc[3], -16) << 10;
			value = GSM.sub(value, -5120);
			value = GSM.mult_r(13107, value);
			larpp[3] = GSM.add(value, value);
			value = GSM.add(larc[4], -8) << 10;
			value = GSM.sub(value, 188);
			value = GSM.mult_r(19223, value);
			larpp[4] = GSM.add(value, value);
			value = GSM.add(larc[5], -8) << 10;
			value = GSM.sub(value, -3584);
			value = GSM.mult_r(17476, value);
			larpp[5] = GSM.add(value, value);
			value = GSM.add(larc[6], -4) << 10;
			value = GSM.sub(value, -682);
			value = GSM.mult_r(31454, value);
			larpp[6] = GSM.add(value, value);
			value = GSM.add(larc[7], -4) << 10;
			value = GSM.sub(value, -2288);
			value = GSM.mult_r(29708, value);
			larpp[7] = GSM.add(value, value);
		}

		private function longTermSynthesis(ncr: int, bcr: int, erp: Vector.<int>): void {
			var nr: int = (ncr >= 40 && ncr <= 120) ? ncr : nrp;
			var brp: int = GSM.QLB[bcr];
			var k: int;

			nrp = nr;

			for (k = 0; k <= 39; k++) {
				var drpp: int = GSM.mult_r(brp, dp[120 + (k - nr)]);
				dp[120 + k] = GSM.add(erp[k], drpp);
			}

			for (k = 0; k <= 119; k++) {
				dp[k] = dp[40 + k];
			}
		}

		private function predecode(xmaxc: int, mc: int, xmc: Vector.<int>, offset: Number, erp: Vector.<int>): void {
			GSM.fraction(xmaxc, mantis);
			GSM.dequantization(xmc, xmp, offset, mantis.x, mantis.y);
			positioning(mc, xmp, erp);
		}

		public static function positioning(mc: int, xmp: Vector.<int>, ep: Vector.<int>): void {
			var i: int = 13;
			var index: int = 0;
			var offset: int = 0;

			switch (mc) {
				case 3:
					ep[index++] = 0;
				case 2:
					ep[index++] = 0;
				case 1:
					ep[index++] = 0;
				case 0:
					ep[index++] = xmp[offset++];
					i--;
			}

			do {
				ep[index++] = 0;
				ep[index++] = 0;
				ep[index++] = xmp[offset++];
				i--;
			} while (i > 0);

			while (++mc < 4) {
				ep[index++] = 0;
			}
		}

	}
}
