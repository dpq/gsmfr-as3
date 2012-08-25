package org.glavbot.codecs.gsmfr {

	import flash.geom.Point;

	/**
	 * @author Vasiliy Vasilyev developer@flashgate.org
	 */
	public class GSM {

		public static const SAMPLE_RATE: int = 8000;
		public static const FRAME_SIZE: int = 33;
		public static const FRAME_SAMPLES: int = 160;

		public static const QLB: Vector.<int> = new <int>[3277, 11469, 21299, 32767];
		public static const DLB: Vector.<int> = new <int>[6554, 16384, 26214, 32767];
		public static const FAC: Vector.<int> = new <int>[18431, 20479, 22527, 24575, 26623, 28671, 30719, 32767];
		public static const NRFAC: Vector.<int> = new <int>[29128, 26215, 23832, 21846, 20165, 18725, 17476, 16384];

		public static function normalize(larp: Vector.<int>): void {
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

		public static function dequantization(xmc: Vector.<int>, xmp: Vector.<int>, offset: int, exp: int, mant: int): void {
			var fac: int = GSM.FAC[mant];
			var sub: int = GSM.sub(6, exp);
			var asl: int = GSM.asl(1, GSM.sub(sub, 1));
			var value: int;
			var index: int = 0;

			for (var i: int = 13; i-- > 0;) {
				value = (xmc[offset++] << 1) - 7;
				value <<= 12;
				value = GSM.mult_r(fac, value);
				value = GSM.add(value, asl);
				xmp[index++] = GSM.asr(value, sub);
			}
		}

		public static function coefficients_0_12(larpp0: Vector.<int>, larpp1: Vector.<int>, larp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				larp[i] = add(larpp0[i] >> 2, larpp1[i] >> 2);
				larp[i] = add(larp[i], larpp0[i] >> 1);
			}
		}

		public static function coefficients_13_26(larpp0: Vector.<int>, larpp1: Vector.<int>, larp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				larp[i] = add(larpp0[i] >> 1, larpp1[i] >> 1);
			}
		}

		public static function coefficients_27_39(larpp0: Vector.<int>, larpp1: Vector.<int>, larp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				larp[i] = add(larpp0[i] >> 2, larpp1[i] >> 2);
				larp[i] = add(larp[i], larpp1[i] >> 1);
			}
		}

		public static function coefficients_40_159(larpp: Vector.<int>, larp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				larp[i] = larpp[i];
			}
		}

		public static function saturate(x: int): int {
			return x >= -32768 ? x <= 32767 ? x : 32767 : -32768;
		}

		public static function sub(a: int, b: int): int {
			return saturate(a - b);
		}

		public static function add(a: int, b: int): int {
			return saturate(a + b);
		}

		public static function abs(a: int): int {
			return (a >= 0) ? a : a == -32768 ? 32767 : -a;
		}

		public static function ladd(a: int, b: int): int {
			var A: Number;
			if (a <= 0) {
				if (b >= 0) {
					return a + b;
				} else {
					A = (-(a + 1)) + (-(b + 1));
					return A < 0x7fffffff ? -A - 2 : 0x80000000;
				}
			}
			if (b <= 0) {
				return a + b;
			} else {
				A = a + b;
				return (A <= 0x7fffffff ? A : 0x7fffffff);
			}
		}

		public static function asl(a: int, n: int): int {
			if (n >= 16)
				return 0;
			if (n <= -16)
				return a >= 0 ? 0 : -1;
			if (n < 0)
				return asr(a, -n);
			else
				return a << n;
		}

		public static function asr(a: int, n: int): int {
			if (n >= 16)
				return a >= 0 ? 0 : -1;
			if (n <= -16)
				return 0;
			if (n < 0)
				return a << -n;
			else
				return a >> n;
		}

		public static function mult(a: int, b: int): int {
			if (a == -32768 && b == -32768) {
				return 32767;
			} else {
				return int(a * b) >> 15;
			}
		}

		public static function mult_r(a: int, b: int): int {
			if (a == -32768 && b == -32768) {
				return 32767;
			} else {
				return int(int(a * b) + 16384) >> 15;
			}
		}

		public static function norm(value: int): int {
			if (value < 0) {
				if (value <= 0xc0000000) {
					return 0;
				}
				value = ~value;
			}

			if (value & 0xffff0000) {
				if (value & 0xff000000) {
					value = -1 + bitoff(0xff & value >> 24);
				} else {
					value = 7 + bitoff(0xff & value >> 16);
				}
			} else {
				if (value & 0xff00) {
					value = bitoff(0xff & value >> 8);
				} else {
					value = 23 + bitoff(0xff & value);
				}
			}

			return value;
		}

		public static function fraction(value: int, result: Point): void {
			var exp: int = 0;
			if (value > 15) {
				exp = (value >> 3) - 1;
			}
			var mant: int = value - (exp << 3);
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
			result.x = exp;
			result.y = mant;
		}

		public static function bitoff(value: int): int {
			if (value > 127) return 0;
			if (value > 63) return 1;
			if (value > 31) return 2;
			if (value > 15) return 3;
			if (value > 7) return 4;
			if (value > 3) return 5;
			if (value > 1) return 6;
			if (value > 0) return 7;
			return 8;
		}

		public static function div(a: int, b: int): int {
			var div: int = 0;
			var k: int = 15;

			if (a == 0) {
				return 0;
			}

			while (k != 0) {
				k--;
				div = (div << 1) & 0xffff;
				a <<= 1;

				if (a >= b) {
					a -= b;
					div = (div + 1) & 0xffff;
				}
			}

			return div;
		}

	}
}
