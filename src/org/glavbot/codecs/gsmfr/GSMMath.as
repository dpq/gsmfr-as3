package org.glavbot.codecs.gsmfr {
	/**
	 * @author Vasiliy Vasilyev developer@flashgate.org
	 */
	public class GSMMath {

		public static function normalize(value: int): int {
			if (value < -0x40000000) {
				return 0;
			}
			if (value < 0) {
				value = ~value;
			}
			return (30 - topbit(value)) & 0xffff;
		}

		public static function topbit(bits: int): int {
			var result: int;
			if (bits == 0) {
				return -1;
			}
			if (bits & 0xffff0000) {
				bits &= 0xffff0000;
				result += 16;
			}
			if (bits & 0xff00ff00) {
				bits &= 0xff00ff00;
				result += 16;
			}
			if (bits & 0xf0f0f0f0) {
				bits &= 0xf0f0f0f0;
				result += 4;
			}
			if (bits & 0xcccccccc) {
				bits &= 0xcccccccc;
				result += 2;
			}
			if (bits & 0xaaaaaaaa) {
				bits &= 0xaaaaaaaa;
				result += 1;
			}
			return result;
		}

		public static function div(num: int, denum: int): * {
			var L_num: int = num;
			var L_denum: int = denum;
			var div: int = 0;
			var k: int = 15;

			if ((num < 0) || (denum < num)) {
				throw new GSMError(GSMError.GSM_DIV_ERROR);
			}

			if (num == 0) {
				return 0;
			}

			while (k != 0) {
				k--;
				div = (div << 1) & 0xffff;
				L_num <<= 1;

				if (L_num >= L_denum) {
					L_num -= L_denum;
					div = (div + 1) & 0xffff;
				}
			}

			return div;
		}



	}

}
