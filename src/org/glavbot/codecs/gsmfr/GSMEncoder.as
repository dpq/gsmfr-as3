package org.glavbot.codecs.gsmfr {

	import flash.utils.ByteArray;

	/**
	 * @author Humanoid
	 */
	public class GSMEncoder {

		public static const FRAME_SIZE: int = 160;

		private var xmc_point: int;
		private var Nc_bc_index: int;
		private var xmaxc_Mc_index: int;
		private var dp_dpp_point_dp0: int = 120;

		private var ep: Vector.<int> = new <int>[];
		private var e: Vector.<int> = new <int>[];
		private var so: Vector.<int> = new <int>[FRAME_SIZE];

		private var state: GSMState = new GSMState();
		private var lpc: GSMLPCAnalysis = new GSMLPCAnalysis();
		private var short: GSMShortTerm = new GSMShortTerm();

		public function GSMEncoder() {
			super();
		}

		public function encode(frame: Vector.<Number>): ByteArray {
			preprocess(state, so, frame);
			lpc.analyze(so);
			short.filter(state, lpc.larc, so);

			return null;
		}

		private function preprocess(state: GSMState, so: Vector.<int>, frame: Vector.<Number>): void {
			const MIN: int = int.MIN_VALUE;
			const MAX: int = int.MAX_VALUE;

			var z1: int = state.z1;
			var L_z2: int = state.L_z2;
			var mp: int = state.mp;
			var s1: int;
			var msp: int;
			var lsp: int;

			var SO: int;
			var L_s2: int;
			var L_tmp: int;
			var index: int = FRAME_SIZE;
			var sum: Number;

			while (index-- != 0) {
				SO = (frame[index] * 0x7fff >> 1) & ~3;

				if (SO < -0x4000 || SO > 0x3ffc) {
					throw new GSMError(GSMError.PREPROCESS_INPUT_ERROR);
				}

				s1 = SO - z1;
				if (s1 == -0x8000) {
					throw new GSMError(GSMError.PREPROCESS_STATE_ERROR);
				}

				z1 = SO;
				L_s2 = s1 << 15;
				msp = L_z2 >> 15;
				lsp = L_z2 - (msp << 15);

				L_tmp = lsp * 0x7FDF;
				L_s2 += (L_tmp + 0x4000) >> 15;

				sum = L_tmp + L_s2;
				L_z2 = sum > MAX ? MAX : (sum < MIN ? MIN : sum);

				sum = L_z2 + 0x4000;
				L_tmp = sum > MAX ? MAX : (sum < MIN ? MIN : sum);

				msp = (mp * -0x6e14 + 0x4000) >> 15;
				mp = L_tmp >> 15;

				sum = msp + mp;
				so[index] = sum > 0x7fff ? 0x7fff : (sum < -0x8000 ? -0x8000 : sum);
			}

			state.z1 = z1;
			state.L_z2 = L_z2;
			state.mp = mp;
		}

	}
}
