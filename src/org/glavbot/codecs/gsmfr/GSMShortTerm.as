package org.glavbot.codecs.gsmfr {
	/**
	 * @author Humanoid
	 */
	public class GSMShortTerm {

		private var larp: Vector.<int> = new <int>[8];

		public function GSMShortTerm() {
		}

		public function filter(S: GSMState, LARc: Vector.<int>, s: Vector.<int>): void {
			var LARp: Vector.<int> = this.larp;

			var LARpp_j: Vector.<int> = S.j ? S.LARpp0 : S.LARpp1;
			var LARpp_j_1: Vector.<int> = S.j ? S.LARpp1 : S.LARpp0;
			S.j ^= 1;

			decode(LARc, LARpp_j);

			Coefficients_0_12(LARpp_j_1, LARpp_j, LARp);
			LARp_to_rp(LARp);
			Short_term_analysis_filtering(S, LARp, 13, s, 0);

			Coefficients_13_26(LARpp_j_1, LARpp_j, LARp);
			LARp_to_rp(LARp);
			Short_term_analysis_filtering(S, LARp, 14, s, 13);

			Coefficients_27_39(LARpp_j_1, LARpp_j, LARp);
			LARp_to_rp(LARp);
			Short_term_analysis_filtering(S, LARp, 13, s, 27);

			Coefficients_40_159(LARpp_j, LARp);
			LARp_to_rp(LARp);
			Short_term_analysis_filtering(S, LARp, 120, s, 40);
		}

		private function Coefficients_40_159(LARpp_j: Vector.<int>, LARp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				LARp[i] = LARpp_j[i];
			}
		}

		private function Coefficients_27_39(LARpp_j_1: Vector.<int>, LARpp_j: Vector.<int>, LARp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				var value: int = (LARpp_j_1[i] >> 2) + (LARpp_j[i] >> 2) + (LARpp_j[i] >> 1);
				LARp[i] = value > 0x7fff ? 0x7fff : (value < -0x8000 ? -0x8000 : value);
			}
		}

		private function Coefficients_13_26(LARpp_j_1: Vector.<int>, LARpp_j: Vector.<int>, LARp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				var value: int = (LARpp_j_1[i] >> 1) + (LARpp_j[i] >> 1);
				LARp[i] = value > 0x7fff ? 0x7fff : (value < -0x8000 ? -0x8000 : value);
			}
		}

		private function Short_term_analysis_filtering(s: GSMState, lARp: Vector.<int>, lARp1: int, s1: Vector.<int>, s2: int): void {
		}

		private function LARp_to_rp(LARp: Vector.<int>): void {
			var value:int;
			for (var i: int = 0; i < 8; i++) {
				value = LARp[i];
				if (value < 0) {
					value = (value == -32768 ? 32767 : -value);
					
					//LARp[i] = (short)(-(temp < 20070 ? temp + 11059 : temp < 11059 ? temp << 1 : Add.GSM_ADD((short)(temp >> 2), 26112)));
					
				} else {
					
//					LARp[i] = (short)(temp < 20070 ? temp + 11059 : temp < 11059 ? temp << 1 : Add.GSM_ADD((short)(temp >> 2), 26112));
				}
			}
		}

		private function Coefficients_0_12(LARpp_j_1: Vector.<int>, LARpp_j: Vector.<int>, LARp: Vector.<int>): void {
			for (var i: int = 0; i < 8; i++) {
				var value: int = (LARpp_j_1[i] >> 2) + (LARpp_j[i] >> 2) + (LARpp_j_1[i] >> 1);
				LARp[i] = value > 0x7fff ? 0x7fff : (value < -0x8000 ? -0x8000 : value);
			}
		}

		public static function decode(LARc: Vector.<int>, LARpp: Vector.<int>): void {
			var index: int = 0;

			STEP(LARc, LARpp, index++, 0, 0, -32, 13107);
			STEP(LARc, LARpp, index++, 0, 0, -32, 13107);
			STEP(LARc, LARpp, index++, 0, 2048, -16, 13107);
			STEP(LARc, LARpp, index++, 0, -2560, -16, 13107);
			STEP(LARc, LARpp, index++, 0, 94, -8, 19223);
			STEP(LARc, LARpp, index++, 0, -1792, -8, 17476);
			STEP(LARc, LARpp, index++, 0, -341, -4, 31454);
			STEP(LARc, LARpp, index++, 0, -1144, -4, 29708);
		}

		public static function STEP(LARc: Vector.<int>, LARpp: Vector.<int>, index: int, temp1: int, B: int, MIC: int, INVA: int): void {
			var value: int = (LARc[index] + MIC) << 10;
			value = value - (B << 1);
			value = (INVA * temp1 >> 15) << 1;
			LARpp[index] = value > 0x7fff ? 0x7fff : (value < -0x8000 ? -0x8000 : value);
		}
	}
}
