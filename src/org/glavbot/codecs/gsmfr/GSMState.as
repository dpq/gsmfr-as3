package org.glavbot.codecs.gsmfr {
	/**
	 * @author Vasiliy Vasilyev developer@flashgate.org
	 */
	public class GSMState {

		public var dp0: Vector.<int> = new <int>[280];
		public var u: Vector.<int> = new <int>[8];
		
		public var LARpp0: Vector.<int> = new <int>[8];
		public var LARpp1: Vector.<int> = new <int>[8];
		
		public var v: Vector.<int> = new <int>[9];
		public var z1: int;
		public var L_z2: int;
		public var mp: int;
		public var j: int;
		public var nrp: int = 40;
		public var msr: int;
				
		public function dump():void {
			trace("8< -------------- gsm state ");
			trace("z1: " + z1);
			trace("L_z2: " + L_z2);
			trace("mp: " + mp);
			trace("u: " + u);
			trace("LARpp0: " + LARpp0);
			trace("LARpp1: " + LARpp1);
			trace("j: " + j);
			trace("nrp: " + nrp);
			trace("v: " + v);
			trace("msr: " + msr);
			trace("8< -------------- gsm state ");
		}

	}
}
