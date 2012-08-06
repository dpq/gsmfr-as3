package org.glavbot.codecs.gsmfr {
	/**
	 * @author Humanoid
	 */
	public class GSMError extends Error {

		public static const PREPROCESS_INPUT_ERROR: int = 1001;
		public static const PREPROCESS_STATE_ERROR: int = 1002;

		public static const CORRELATION_NEGATIVE_MAX_ERROR: int = 2001;
		public static const CORRELATION_SCALAUTO_ERROR: int = 2002;
		
		public static const REFLECTION_NORMAL_ERROR: int = 3001;
		public static const REFLECTION_DIV_ERROR: int = 3002;
		public static const REFLECTION_COEFF_ERROR: int = 3003;

		public static const GSM_DIV_ERROR: int = 1;

		public function GSMError(code: int) {
			super(code);
		}

	}
}
