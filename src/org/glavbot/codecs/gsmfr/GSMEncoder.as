package org.glavbot.codecs.gsmfr {

	import flash.geom.Point;
	import flash.utils.ByteArray;

	/**
	 * @author Vasiliy Vasilyev developer@flashgate.org
	 */
	public class GSMEncoder {

		private var dp: Vector.<int> = new Vector.<int>(280, true);
		private var larp: Vector.<int> = new Vector.<int>(8, true);
		private var larpp0: Vector.<int> = new Vector.<int>(8, true);
		private var larpp1: Vector.<int> = new Vector.<int>(8, true);
		private var u: Vector.<int> = new Vector.<int>(8, true);
		private var larc: Vector.<int> = new Vector.<int>(8, true);
		private var lacf: Vector.<int> = new Vector.<int>(9, true);
		private var wt: Vector.<int> = new Vector.<int>(160, true);
		private var p: Vector.<int> = new Vector.<int>(9, true);
		private var k: Vector.<int> = new Vector.<int>(9, true);
		private var erp: Vector.<int> = new Vector.<int>(50, true);
		private var nc: Vector.<int> = new Vector.<int>(4, true);
		private var mc: Vector.<int> = new Vector.<int>(4, true);
		private var bc: Vector.<int> = new Vector.<int>(4, true);
		private var xmaxc: Vector.<int> = new Vector.<int>(4, true);
		private var xmc: Vector.<int> = new Vector.<int>(52, true);
		private var xmp: Vector.<int> = new Vector.<int>(13, true);
		private var xm: Vector.<int> = new Vector.<int>(13, true);
		private var x: Vector.<int> = new Vector.<int>(40, true);
		private var mantis: Point = new Point;
		private var frame: ByteArray = new ByteArray;
		private var z: int;
		private var lz: int;
		private var mp: int;
		private var j: int;

		public function GSMEncoder() {
			super();
		}

		/**
		 * @param samples	160 samples of PCM 8000Hz 16bit
		 * @return			33 s of GSM-FR encoded data
		 */
		public function encode(samples: Vector.<int>): ByteArray {
			preprocess(samples);
			lpc(samples);
			shortTermAnalysis(samples, larc);

			var index: int;
			var offset: int = 120;
			var i: int;

			for (var k: int = 0; k < 4; k++, index += 13) {
				longTermAnalysis(samples, k * 40, erp, dp, offset, nc, bc, k);
				preencoding(erp, xmaxc, mc, k, xmc, index);
				
				for (i = 0; i < 40; i++) {
					dp[int(i + offset)] = GSM.add(erp[int(5 + i)], dp[int(i + offset)]);
				}				
				offset += 40;
			}

			for (i = 0; i < 120; i++) {
				dp[i] = dp[160 + i];
			}

			i = 0;

			frame.length = GSM.FRAME_SIZE;
			frame.position = 0;
			
			frame[i++] = 0xd0 | larc[0] >> 2 & 0xf;
			frame[i++] = (larc[0] & 0x3) << 6 | larc[1] & 0x3f;
			frame[i++] = (larc[2] & 0x1f) << 3 | larc[3] >> 2 & 0x7;
			frame[i++] = (larc[3] & 0x3) << 6 | (larc[4] & 0xf) << 2 | larc[5] >> 2 & 0x3;
			frame[i++] = (larc[5] & 0x3) << 6 | (larc[6] & 0x7) << 3 | larc[7] & 0x7;
			frame[i++] = (nc[0] & 0x7f) << 1 | bc[0] >> 1 & 0x1;
			frame[i++] = (bc[0] & 0x1) << 7 | (mc[0] & 0x3) << 5 | xmaxc[0] >> 1 & 0x1f;
			frame[i++] = (xmaxc[0] & 0x1) << 7 | (xmc[0] & 0x7) << 4 | (xmc[1] & 0x7) << 1 | xmc[2] >> 2 & 0x1;
			frame[i++] = (xmc[2] & 0x3) << 6 | (xmc[3] & 0x7) << 3 | xmc[4] & 0x7;
			frame[i++] = (xmc[5] & 0x7) << 5 | (xmc[6] & 0x7) << 2 | xmc[7] >> 1 & 0x3;
			frame[i++] = (xmc[7] & 0x1) << 7 | (xmc[8] & 0x7) << 4 | (xmc[9] & 0x7) << 1 | xmc[10] >> 2 & 0x1;
			frame[i++] = (xmc[10] & 0x3) << 6 | (xmc[11] & 0x7) << 3 | xmc[12] & 0x7;
			frame[i++] = (nc[1] & 0x7f) << 1 | bc[1] >> 1 & 0x1;
			frame[i++] = (bc[1] & 0x1) << 7 | (mc[1] & 0x3) << 5 | xmaxc[1] >> 1 & 0x1f;
			frame[i++] = (xmaxc[1] & 0x1) << 7 | (xmc[13] & 0x7) << 4 | (xmc[14] & 0x7) << 1 | xmc[15] >> 2 & 0x1;
			frame[i++] = (xmc[15] & 0x3) << 6 | (xmc[16] & 0x7) << 3 | xmc[17] & 0x7;
			frame[i++] = (xmc[18] & 0x7) << 5 | (xmc[19] & 0x7) << 2 | xmc[20] >> 1 & 0x3;
			frame[i++] = (xmc[20] & 0x1) << 7 | (xmc[21] & 0x7) << 4 | (xmc[22] & 0x7) << 1 | xmc[23] >> 2 & 0x1;
			frame[i++] = (xmc[23] & 0x3) << 6 | (xmc[24] & 0x7) << 3 | xmc[25] & 0x7;
			frame[i++] = (nc[2] & 0x7f) << 1 | bc[2] >> 1 & 0x1;
			frame[i++] = (bc[2] & 0x1) << 7 | (mc[2] & 0x3) << 5 | xmaxc[2] >> 1 & 0x1f;
			frame[i++] = (xmaxc[2] & 0x1) << 7 | (xmc[26] & 0x7) << 4 | (xmc[27] & 0x7) << 1 | xmc[28] >> 2 & 0x1;
			frame[i++] = (xmc[28] & 0x3) << 6 | (xmc[29] & 0x7) << 3 | xmc[30] & 0x7;
			frame[i++] = (xmc[31] & 0x7) << 5 | (xmc[32] & 0x7) << 2 | xmc[33] >> 1 & 0x3;
			frame[i++] = (xmc[33] & 0x1) << 7 | (xmc[34] & 0x7) << 4 | (xmc[35] & 0x7) << 1 | xmc[36] >> 2 & 0x1;
			frame[i++] = (xmc[36] & 0x3) << 6 | (xmc[37] & 0x7) << 3 | xmc[38] & 0x7;
			frame[i++] = (nc[3] & 0x7f) << 1 | bc[3] >> 1 & 0x1;
			frame[i++] = (bc[3] & 0x1) << 7 | (mc[3] & 0x3) << 5 | xmaxc[3] >> 1 & 0x1f;
			frame[i++] = (xmaxc[3] & 0x1) << 7 | (xmc[39] & 0x7) << 4 | (xmc[40] & 0x7) << 1 | xmc[41] >> 2 & 0x1;
			frame[i++] = (xmc[41] & 0x3) << 6 | (xmc[42] & 0x7) << 3 | xmc[43] & 0x7;
			frame[i++] = (xmc[44] & 0x7) << 5 | (xmc[45] & 0x7) << 2 | xmc[46] >> 1 & 0x3;
			frame[i++] = (xmc[46] & 0x1) << 7 | (xmc[47] & 0x7) << 4 | (xmc[48] & 0x7) << 1 | xmc[49] >> 2 & 0x1;
			frame[i++] = (xmc[49] & 0x3) << 6 | (xmc[50] & 0x7) << 3 | xmc[51] & 0x7;

			return frame;
		}

		private function preencoding(erp: Vector.<int>, xmaxc: Vector.<int>, mc: Vector.<int>, k: int, xmc: Vector.<int>, index: int): void {
			weightFilter(erp);
			gridSelection(xm, mc, k);
			quantization(xm, xmc, index, xmaxc, k);

			GSM.dequantization(xmc, xmp, index, mantis.x, mantis.y);
			positioning(mc[k], xmp, erp);
		}
		
		public static function positioning(mc: int, xmp: Vector.<int>, ep: Vector.<int>): void {
			var i: int = 13;
			var index: int = 5;
			var offset: int = 0;

			switch (mc) {
				case 3:
					ep[index++] = 0;
					do {
						ep[index++] = 0;
						ep[index++] = 0;
						ep[index++] = xmp[offset++];
					} while (--i > 0);
					break;
				case 2:
					do {
						ep[index++] = 0;
						ep[index++] = 0;
						ep[index++] = xmp[offset++];
					} while (--i > 0);
					break;
				case 1:
					do {
						ep[index++] = 0;
						ep[index++] = xmp[offset++];
						ep[index++] = 0;
					} while (--i > 0);
					break;
				case 0:
					do {
						ep[index++] = xmp[offset++];
						ep[index++] = 0;
						ep[index++] = 0;
					} while (--i > 0);
					break;
			}

			ep[index++] = 0;
		}

		private function quantization(xm: Vector.<int>, xmc: Vector.<int>, index: int, xmaxc: Vector.<int>, k: int): void {
			var value: int;
			var max: int;
			var i: int;

			for (i = 0; i <= 12; i++) {
				value = GSM.abs(xm[i]);
				if (value > max) {
					max = value;
				}
			}

			var exp: int = getExp(max >> 9);
			var result: int = GSM.add(max >> (exp + 5), exp << 3);

			GSM.fraction(result, mantis);

			var shift: int = 6 - mantis.x;
			var factor: int = GSM.NRFAC[mantis.y];

			for (i = 0; i <= 12; i++) {
				value = GSM.mult(xm[i] << shift, factor) >> 12;
				xmc[i + index] = value + 4;
			}

			xmaxc[k] = result;
		}

		private function getExp(value: int): int {
			var test: Boolean = false;
			var exp: int = 0;

			for (var i: int = 0; i < 6; i++) {
				if (value <= 0 && !test) {
					test = true;
				}
				value >>= 1;
				test || exp++
				;
			}

			return exp;
		}

		private function gridSelection(xm: Vector.<int>, mc: Vector.<int>, index: int): void {
			var value: int;
			var em: int;
			var step: int;
			var common: int = value = row(0, 1);

			em = value = (value + grid(0, 0)) << 1;

			value = row(1, 0) << 1;
			if (value > em) {
				step = 1;
				em = value;
			}

			value = row(2, 0) << 1;
			if (value > em) {
				step = 2;
				em = value;
			}

			value = (common + grid(3, 12)) << 1;
			if (value > em) {
				step = 3;
				em = value;
			}

			for (var i: int = 0; i <= 12; i++) {
				xm[i] = x[step + 3 * i];
			}

			mc[index] = step;
		}

		private function row(m: int, offset: int): int {
			var result: int = 0;
			for (var i: int = offset; i < 12; i++) {
				result += grid(m, i);
			}
			return result;
		}

		private function grid(m: int, i: int): int {
			var value: int = x[m + 3 * i] >> 2;
			return value * value;
		}

		private function weightFilter(erp: Vector.<int>): void {
			var value: int = 0;
			for (var k: int = 0; k < 40; k++) {
				value = 4096 + erp[k + 0] * -134 + erp[k + 1] * -374 + erp[k + 3] * 2054 + erp[k + 4] * 5741 + erp[k + 5] * 8192 + erp[k + 6] * 5741 + erp[k + 7] * 2054 + erp[k + 9] * -374 + erp[k + 10] * -134;
				x[k] = GSM.saturate(value >> 13);
			}
		}

		private function longTermAnalysis(samples: Vector.<int>, k: int, e: Vector.<int>, dp: Vector.<int>, offset: int, nc: Vector.<int>, bc: Vector.<int>, index: int): void {
			longTermPredict(samples, k, dp, offset, bc, nc, index);
			longTermAnalysisFilter(bc[index], nc[index], dp, samples, k, e, offset);
		}

		private function longTermAnalysisFilter(bc: int, nc: int, dp: Vector.<int>, samples: Vector.<int>, index: int, e: Vector.<int>, offset: int): void {
			var bp: int = GSM.QLB[bc];
			for (var k: int = 0; k < 40; k++) {
				dp[k + offset] = GSM.mult_r(bp, dp[k - nc + offset]);
				e[k + 5] = GSM.sub(samples[k + index], dp[k + offset]);
			}
		}

		private function longTermPredict(d: Vector.<int>, d_index: int, dp: Vector.<int>, dp_start: int, bc: Vector.<int>, nc: Vector.<int>, index: int): void {
			var lambda: int;
			var n: int = 40;
			var max: int;
			var power: int;
			var R: int;
			var S: int;
			var shift: int;
			var value: int;
			var k: int;

			for (k = 0; k < 40; k++) {
				value = GSM.abs(d[k + d_index]);
				if (value > max) {
					max = value;
				}
			}

			if (max > 0) {
				value = GSM.norm(max << 16);
			}

			shift = (value > 6) ? 0 : 6 - value;
			max = 0;

			for (k = 0; k < 40; k++) {
				wt[k] = d[k + d_index] >> shift;
			}

			for (lambda = 40; lambda <= 120; lambda++) {
				for (k = 0, value = 0; k < 40; k++) {
					value += wt[k] * dp[int(k + dp_start - lambda)];
				}
				if (value > max) {
					n = lambda;
					max = value;
				}
			}

			nc[index] = n;
			max <<= 1;
			max >>= 6 - shift;
			power = 0;

			for (k = 0; k < 40; k++) {
				value = dp[int(k - n + dp_start)] >> 3;
				power += value * value;
			}

			power <<= 1;
			if (max <= 0) {
				bc[index] = 0;
				return;
			}

			if (max >= power) {
				bc[index] = 3;
				return;
			}

			value = GSM.norm(power);
			R = (max << value) >> 16;
			S = (power << value) >> 16;

			for (value = 0; value < 3 && R > GSM.mult(S, GSM.DLB[value]); value++) {
				bc[index] = value;
			}
		}

		private function shortTermAnalysis(samples: Vector.<int>, larc: Vector.<int>): void {
			var larpp0: Vector.<int> = j ? this.larpp0 : this.larpp1;
			var larpp1: Vector.<int> = j ? this.larpp1 : this.larpp0;
			j ^= 1;

			decodeLAR(larc, larpp0);
			GSM.coefficients_0_12(larpp1, larpp0, larp);
			GSM.normalize(larp);
			shortTermAnalysisFiltering(larp, 13, samples, 0);
			GSM.coefficients_13_26(larpp1, larpp0, larp);
			GSM.normalize(larp);
			shortTermAnalysisFiltering(larp, 14, samples, 13);
			GSM.coefficients_27_39(larpp1, larpp0, larp);
			GSM.normalize(larp);
			shortTermAnalysisFiltering(larp, 13, samples, 27);
			GSM.coefficients_40_159(larpp0, larp);
			GSM.normalize(larp);
			shortTermAnalysisFiltering(larp, 120, samples, 40);
		}

		private function shortTermAnalysisFiltering(larp: Vector.<int>, length: int, samples: Vector.<int>, index: int): void {
			var di: int;
			var ui: int;
			var sav: int;
			var rpi: int;

			while (length != 0) {
				length--;
				di = sav = samples[index];

				for (var i: int = 0; i < 8; i++) {
					ui = u[i];
					rpi = larp[i];
					u[i] = sav;
					sav = GSM.add(ui, GSM.mult_r(rpi, di));
					di = GSM.add(di, GSM.mult_r(rpi, ui));
				}
				samples[index++] = di;
			}
		}

		private function preprocess(samples: Vector.<int>): void {
			var s: int;
			var msp: int;
			var lsp: int;
			var ls: int;
			var value: int;

			for (var i: int = 0; i < GSM.FRAME_SAMPLES; i++) {
				value = (samples[i] >> 3) << 2;

				s = value - z;
				z = value;

				ls = s << 15;
				msp = lz >> 15;
				lsp = lz - (msp << 15);

				ls += GSM.mult_r(lsp, 32735);
				lz = GSM.ladd(msp * 32735, ls);

				msp = GSM.mult_r(mp, -28180);
				mp = GSM.ladd(lz, 16384) >> 15;

				samples[i] = GSM.add(mp, msp);
			}
		}

		private function lpc(samples: Vector.<int>): void {
			autocorrelation(samples, lacf);
			reflection(larc);
			transform(larc);
			quant(larc);
		}

		private function quant(larc: Vector.<int>): void {
			var index: int = 0;
			quantStep(20480, 0, 31, -32, larc, index++);
			quantStep(20480, 0, 31, -32, larc, index++);
			quantStep(20480, 2048, 15, -16, larc, index++);
			quantStep(20480, -2560, 15, -16, larc, index++);
			quantStep(13964, 94, 7, -8, larc, index++);
			quantStep(15360, -1792, 7, -8, larc, index++);
			quantStep(8534, -341, 3, -4, larc, index++);
			quantStep(9036, -1144, 3, -4, larc, index++);
		}

		private function quantStep(a: int, b: int, mac: int, mic: Number, larc: Vector.<int>, index: int): void {
			var value: int = GSM.mult(a, larc[index]);
			value = GSM.add(value, b);
			value = GSM.add(value, 256) >> 9;
			larc[index] = value < mic ? 0 : (value > mac ? mac - mic : value - mic);
		}

		private function decodeLAR(larc: Vector.<int>, larpp: Vector.<int>): void {
			var index: int = 0;
			decodeStep(larc, larpp, index++, 0, -32, 13107);
			decodeStep(larc, larpp, index++, 0, -32, 13107);
			decodeStep(larc, larpp, index++, 2048, -16, 13107);
			decodeStep(larc, larpp, index++, -2560, -16, 13107);
			decodeStep(larc, larpp, index++, 94, -8, 19223);
			decodeStep(larc, larpp, index++, -1792, -8, 17476);
			decodeStep(larc, larpp, index++, -341, -4, 31454);
			decodeStep(larc, larpp, index++, -1144, -4, 29708);
		}

		private function decodeStep(larc: Vector.<int>, larpp: Vector.<int>, index: int, b: int, mic: int, inva: int): void {
			var value: int = GSM.add(larc[index], mic) << 10;
			value = GSM.sub(value, b << 1);
			value = GSM.mult_r(inva, value);
			larpp[index] = GSM.add(value, value);
		}

		private function transform(larc: Vector.<int>): void {
			var value: int;

			for (var i: int = 0; i < 8; i++) {
				value = GSM.abs(larc[i]);
				if (value < 22118) {
					value = value >> 1;
				} else if (value < 31130) {
					value = value - 11059;
				} else {
					value = int(value - 26112) << 2;
				}
				larc[i] = larc[i] < 0 ? -value : value;
			}
		}

		private function reflection(larc: Vector.<int>): void {
			var i: int;
			var temp: int = lacf[0];
			var value: int;

			if (temp == 0) {
				for (i = 0; i < 8; i++) {
					larc[i] = 0;
				}
				return;
			}

			temp = GSM.norm(temp);

			for (i = 0; i < 8; i++) {
				value = (lacf[i] << temp) >> 16;
				p[i] = value;
				k[i] = value;
			}

			k[7] = 0;
			k[8] = 0;
			p[8] = 0;

			for (var n: int = 1, r: int = 0; n <= 8; r++, n++) {
				value = GSM.abs(p[1]);

				if (p[0] < value) {
					for (i = n; i < 8; i++) {
						larc[i] = 0;
					}
					return;
				}

				larc[r] = value = GSM.div(value, p[0]);

				if (p[1] > 0) {
					larc[r] = -larc[r];
				}

				if (n == 8) {
					return;
				}

				value = GSM.mult_r(p[1], larc[r]);
				p[0] = GSM.add(p[0], value);

				var count: int = 8 - n;
				var shift: int = larc[r];

				for (var m: int = 1; m <= count ; m++) {
					p[m] = GSM.add(p[int(m + 1)], GSM.mult_r(k[m], shift));
					k[m] = GSM.add(k[m], GSM.mult_r(p[int(m + 1)], shift));
				}
			}
		}

		private static function autocorrelation(samples: Vector.<int>, lacf: Vector.<int>): void {
			var value: int;
			var max: int;
			var scalauto: int;
			var i: int;

			for each (value in samples) {
				if (value > max) {
					max = value;
				}
			}

			if (max > 0) {
				scalauto = 4 - GSM.norm(max << 16);
			}

			if (scalauto > 0) {
				var factor: int = scalauto == 1 ? 0x4000 : scalauto == 2 ? 0x2000 : scalauto == 3 ? 0x1000 : 0x800;
				for (i = 0; i < 160; i++) {
					samples[i] = (samples[i] * factor + 0x4000) >> 15;
				}
			}

			var sl: int = samples[i = 0];

			lacf[0] += sl * samples[i];

			sl = samples[++i];
			lacf[0] += sl * samples[i];
			lacf[1] += sl * samples[int(i - 1)];

			sl = samples[++i];
			lacf[0] += sl * samples[i];
			lacf[1] += sl * samples[int(i - 1)];
			lacf[2] += sl * samples[int(i - 2)];

			sl = samples[++i];
			lacf[0] += sl * samples[i];
			lacf[1] += sl * samples[int(i - 1)];
			lacf[2] += sl * samples[int(i - 2)];
			lacf[3] += sl * samples[int(i - 3)];

			sl = samples[++i];
			lacf[0] += sl * samples[i];
			lacf[1] += sl * samples[int(i - 1)];
			lacf[2] += sl * samples[int(i - 2)];
			lacf[3] += sl * samples[int(i - 3)];
			lacf[4] += sl * samples[int(i - 4)];

			sl = samples[++i];
			lacf[0] += sl * samples[i];
			lacf[1] += sl * samples[int(i - 1)];
			lacf[2] += sl * samples[int(i - 2)];
			lacf[3] += sl * samples[int(i - 3)];
			lacf[4] += sl * samples[int(i - 4)];
			lacf[5] += sl * samples[int(i - 5)];

			sl = samples[++i];
			lacf[0] += sl * samples[i];
			lacf[1] += sl * samples[int(i - 1)];
			lacf[2] += sl * samples[int(i - 2)];
			lacf[3] += sl * samples[int(i - 3)];
			lacf[4] += sl * samples[int(i - 4)];
			lacf[5] += sl * samples[int(i - 5)];
			lacf[6] += sl * samples[int(i - 6)];

			sl = samples[++i];
			lacf[0] += sl * samples[i];
			lacf[1] += sl * samples[int(i - 1)];
			lacf[2] += sl * samples[int(i - 2)];
			lacf[3] += sl * samples[int(i - 3)];
			lacf[4] += sl * samples[int(i - 4)];
			lacf[5] += sl * samples[int(i - 5)];
			lacf[6] += sl * samples[int(i - 6)];
			lacf[7] += sl * samples[int(i - 7)];

			sl = samples[++i];

			for (; i < 160; i++) {
				sl = samples[i];
				lacf[0] += sl * samples[i];
				lacf[1] += sl * samples[int(i - 1)];
				lacf[2] += sl * samples[int(i - 2)];
				lacf[3] += sl * samples[int(i - 3)];
				lacf[4] += sl * samples[int(i - 4)];
				lacf[5] += sl * samples[int(i - 5)];
				lacf[6] += sl * samples[int(i - 6)];
				lacf[7] += sl * samples[int(i - 7)];
				lacf[8] += sl * samples[int(i - 8)];
			}

			for (i = 0; i < 9; i++) {
				lacf[i] <<= 1;
			}

			if (scalauto > 0) {
				for (i = 0; i < 160; i++) {
					samples[i] <<= scalauto;
				}
			}
		}

	}
}
