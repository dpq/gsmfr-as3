package org.glavbot.codecs.gsmfr {

	import flash.utils.ByteArray;

	/**
	 * @author Vasiliy Vasilyev developer@flashgate.org
	 */
	public class GSMEncoder {

		public static const FRAME_SIZE: int = 160;

		private var mc: Vector.<int> = new Vector.<int>(4, true);


		private var wt: Vector.<int> = new Vector.<int>(GSM.FRAME_SAMPLES, true);
		private var s: Vector.<int> = new Vector.<int>(GSM.FRAME_SAMPLES, true);

		private var z: int;
		private var lz: int;
		private var mp: int;

		public function GSMEncoder() {
			super();
		}

		public function encode(frame: Vector.<int>): ByteArray {
			preprocess(frame);

			return null;
		}

		private function preprocess(frame: Vector.<int>): void {
			var s: int;
			var msp: int;
			var lsp: int;
			var ls: int;
			var value: int;

			for(var i:int = 0; i< GSM.FRAME_SAMPLES; i++) {
				value = frame[i];
				
				trace(value);
				
				s = value - z;
				z = value;
				
				ls = s << 15;
				msp = lz >> 15;
				lsp = lz - (msp << 15);

				ls += mult_r(lsp, 32735);
				lz = saturate(msp * 32735 + ls);

				msp = mult_r(mp, -28180);
				mp = saturate(lz + 16384) >> 15;
				
				//trace(mp+" "+msp);
				
				frame[i] = add(mp, msp);
			}
		}

		private static function saturate(x: Number): int {
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
