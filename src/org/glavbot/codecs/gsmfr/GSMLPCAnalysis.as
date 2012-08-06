package org.glavbot.codecs.gsmfr {
	/**
	 * @author Humanoid
	 */
	public class GSMLPCAnalysis {

		private static const SCALAUTO: Array = [0x4000, 0x2000, 0x1000, 0x800];

		public var larc: Vector.<int> = new <int>[8];
		public var lacf: Vector.<int> = new <int>[9];

		private var p: Vector.<int> = new <int>[9];
		private var k: Vector.<int> = new <int>[9];

		public function GSMLPCAnalysis() {
		}

		public function analyze(so: Vector.<int>): void {
			correlation(so, lacf);
			reflection(lacf, larc, p, k);
			transform(larc);
			quantization(larc);
		}

		private function quantization(larc: Vector.<int>): void {
			var index: int = 0;

			step(20480, 0, 31, -32, larc, index++);
			step(20480, 0, 31, -32, larc, index++);
			step(20480, 2048, 15, -16, larc, index++);
			step(20480, -2560, 15, -16, larc, index++);
			step(13964, 94, 7, -8, larc, index++);
			step(15360, -1792, 7, -8, larc, index++);
			step(8534, -341, 3, -4, larc, index++);
			step(9036, -1144, 3, -4, larc, index++);
		}

		private function step(a: int, b: int, mac: int, mic: Number, larc: Vector.<int>, index: int): void {
			var value: int = (a * larc[index]) >> 15;
			value = (value + b + 256) >> 9;
			value = value > 0x7fff ? 0x7fff : (value < -0x8000 ? -0x8000 : value);
			larc[index] = value < mic ? 0 : (value > mac ? mac - mic : value - mic);
		}

		private function transform(larc: Vector.<int>): void {
			var value: int;
			for (var i: int = 0; i < 8; i++) {
				value = larc[i];

				if (value == -0x8000) value = 0x7fff;
				else if (value < 0) value = -value;

				if (value < 22118) {
					value = value >> 1;
				} else if (value < 31130) {
					value = value - 11059;
				} else {
					value = (value - 26112) << 2;
				}

				larc[i] = larc[i] < 0 ? -value : value;
			}
		}

		private static function reflection(lacf: Vector.<int>, larc: Vector.<int>, p: Vector.<int>, k: Vector.<int>): void {
			var i: int;
			var normal: int = lacf[0];
			var value: int;

			if (normal == 0) {
				for (i = 0; i < 8; i++) {
					larc[i] = 0;
				}
				return;
			}

			normal = GSMMath.normalize(normal);

			if (normal < 0 || normal >= 32) {
				throw new GSMError(GSMError.REFLECTION_NORMAL_ERROR);
			}

			for (i = 0; i <= 8; i++) {
				value = (lacf[i] << normal) >> 16;
				p[i] = value;
				k[i] = value;
			}

			for (var n: int = 1, r: int = 0; n <= 8; r++, n++) {
				value = p[1];
				if (value == -0x8000) value = 0x7fff;
				else if (value < 0) value = -value;

				if (p[0] < value) {
					for (i = n; i < 8; i++) {
						larc[i] = 0;
					}
					return;
				}

				larc[r] = value = GSMMath.div(value, p[0]);
				if (value < 0) {
					throw new GSMError(GSMError.REFLECTION_DIV_ERROR);
				}

				if (p[1] > 0) {
					larc[r] = (-larc[r]) & 0xffff;
				}

				if (larc[r] == -0x800) {
					throw new GSMError(GSMError.REFLECTION_COEFF_ERROR);
				}

				if (n == 8) {
					return;
				}

				value = p[0] + (p[1] >> larc[r]);
				p[0] = value > 0x7fff ? 0x7fff : (value < -0x8000 ? -0x8000 : value);

				var count: int = 8 - n;
				var shift: int = larc[r];

				for (var m: int = 0; m <= count ; m++) {
					value = p[m + 1] + (k[m] >> shift);
					p[m] = value > 0x7fff ? 0x7fff : (value < -0x8000 ? -0x8000 : value);

					value = k[m] + (p[m + 1] >> shift);
					k[m] = value > 0x7fff ? 0x7fff : (value < -0x8000 ? -0x8000 : value);
				}

			}
		}

		private static function correlation(so: Vector.<int>, lacf: Vector.<int>): void {
			var count: int = so.length;
			var max: int;
			var value: int;
			var scalauto: int;
			var i: int;

			for each (value in so) {
				if (value > max) max = value;
			}

			if (max == 0) {
				scalauto = 0;
			} else if (max <= 0) {
				throw new GSMError(GSMError.CORRELATION_NEGATIVE_MAX_ERROR);
			} else {
				scalauto = 4 - GSMMath.normalize(max << 16);
			}

			if (scalauto > 0) {
				if (scalauto > 4) {
					throw new GSMError(GSMError.CORRELATION_SCALAUTO_ERROR);
				}

				var factor: int = SCALAUTO[scalauto - 1];
				for (i = 0; i < count; i++) {
					so[i] = (so[i] * factor + 0x4000) >> 15;
				}
			}

			var sl: int = so[i = 0];

			lacf[0] += sl * so[i];

			sl = so[++i];
			lacf[0] += sl * so[i];
			lacf[1] += sl * so[int(i - 1)];

			sl = so[++i];
			lacf[0] += sl * so[i];
			lacf[1] += sl * so[int(i - 1)];
			lacf[2] += sl * so[int(i - 2)];

			sl = so[++i];
			lacf[0] += sl * so[i];
			lacf[1] += sl * so[int(i - 1)];
			lacf[2] += sl * so[int(i - 2)];
			lacf[3] += sl * so[int(i - 3)];

			sl = so[++i];
			lacf[0] += sl * so[i];
			lacf[1] += sl * so[int(i - 1)];
			lacf[2] += sl * so[int(i - 2)];
			lacf[3] += sl * so[int(i - 3)];
			lacf[4] += sl * so[int(i - 4)];

			sl = so[++i];
			lacf[0] += sl * so[i];
			lacf[1] += sl * so[int(i - 1)];
			lacf[2] += sl * so[int(i - 2)];
			lacf[3] += sl * so[int(i - 3)];
			lacf[4] += sl * so[int(i - 4)];
			lacf[5] += sl * so[int(i - 5)];

			sl = so[++i];
			lacf[0] += sl * so[i];
			lacf[1] += sl * so[int(i - 1)];
			lacf[2] += sl * so[int(i - 2)];
			lacf[3] += sl * so[int(i - 3)];
			lacf[4] += sl * so[int(i - 4)];
			lacf[5] += sl * so[int(i - 5)];
			lacf[6] += sl * so[int(i - 6)];

			sl = so[++i];
			lacf[0] += sl * so[i];
			lacf[1] += sl * so[int(i - 1)];
			lacf[2] += sl * so[int(i - 2)];
			lacf[3] += sl * so[int(i - 3)];
			lacf[4] += sl * so[int(i - 4)];
			lacf[5] += sl * so[int(i - 5)];
			lacf[6] += sl * so[int(i - 6)];
			lacf[7] += sl * so[int(i - 7)];

			sl = so[++i];

			for (; i < count; i++) {
				sl = so[i];
				lacf[0] += sl * so[i];
				lacf[1] += sl * so[int(i - 1)];
				lacf[2] += sl * so[int(i - 2)];
				lacf[3] += sl * so[int(i - 3)];
				lacf[4] += sl * so[int(i - 4)];
				lacf[5] += sl * so[int(i - 5)];
				lacf[6] += sl * so[int(i - 6)];
				lacf[7] += sl * so[int(i - 7)];
				lacf[8] += sl * so[int(i - 8)];
			}

			for (i = 0; i < 9; i++) {
				lacf[i] <<= 1;
			}

			if (scalauto > 0) {
				for (i = 0; i < count; i++) {
					so[i] <<= scalauto;
				}
			}
		}

	}
}
