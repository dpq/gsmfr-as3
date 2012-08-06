package org.glavbot.codecs.gsmfr {

	import flash.utils.IDataInput;
	/**
	 * @author Humanoid
	 */
	public class GSMDecoder {
		
		private var frame:Vector.<Number> = new <Number>[];

		public function GSMDecoder() {
		}
		
		public function decode( data:IDataInput ):Vector.<Number> {
			return frame;
		}

	}
}
