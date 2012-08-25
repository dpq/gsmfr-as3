package {

	import org.glavbot.codecs.gsmfr.GSMDecoder;
	import org.glavbot.codecs.gsmfr.GSMEncoder;

	import flash.display.Sprite;
	import flash.utils.ByteArray;

	/**
	 * @author Humanoid
	 */
	public class SingleFrameEncodeTest extends Sprite {

		public function SingleFrameEncodeTest() {
			var input: Vector.<int> = new <int>[0, 1286, 2570, 3851, 5125, 6392, 7649, 8894, 10125, 11341, 12539, 13718, 14875, 16010, 17120, 18204, 19259, 20285, 21280, 22242, 23169, 24061, 24916, 25732, 26509, 27244, 27938, 28589, 29195, 29757, 30272, 30741, 31163, 31536, 31861, 32137, 32363, 32539, 32665, 32741, 32767, 32741, 32665, 32539, 32363, 32137, 31861, 31536, 31163, 30741, 30272, 29757, 29195, 28589, 27938, 27244, 26509, 25732, 24916, 24061, 23169, 22242, 21280, 20285, 19259, 18204, 17120, 16010, 14875, 13718, 12539, 11341, 10125, 8894, 7649, 6392, 5125, 3851, 2570, 1286, 0, -1286, -2570, -3851, -5125, -6392, -7649, -8894, -10125, -11341, -12539, -13718, -14875, -16010, -17120, -18204, -19259, -20285, -21280, -22242, -23169, -24061, -24916, -25732, -26509, -27244, -27938, -28589, -29195, -29757, -30272, -30741, -31163, -31536, -31861, -32137, -32363, -32539, -32665, -32741, -32767, -32741, -32665, -32539, -32363, -32137, -31861, -31536, -31163, -30741, -30272, -29757, -29195, -28589, -27938, -27244, -26509, -25732, -24916, -24061, -23169, -22242, -21280, -20285, -19259, -18204, -17120, -16010, -14875, -13718, -12539, -11341, -10125, -8894, -7649, -6392, -5125, -3851, -2570, -1286];
			var output: Vector.<int> = new <int>[-48, 42, -44, 45, -30, 80, 82, -35, -1, -1, -3, 109, 80, 70, 116, 73, 32, 2, -110, 80, 65, -124, -111, 41, 36, -110, -20, 5, 34, 0, 0, 2, -110];

			var encoder: GSMEncoder = new GSMEncoder();
			var decoder: GSMDecoder = new GSMDecoder();

			var frame: ByteArray = encoder.encode(input);
			var reverse: Vector.<int> = decoder.decode(frame);
			var bytes: String = "";

			for (var i: int = 0; i < frame.length; i++) {
				var r:String = frame[i].toString(16).toUpperCase();
				bytes += (r.length == 2) ? r : "0"+r;
			}
			
			trace("output (gsm):    " + output);
			trace("output (test):   " + bytes);
			trace("inptut (signal):  " + input);
			trace("inptut (reverse): " + reverse);			
			trace("encoding test: " + (bytes == "D02AD42DE25052DDFFFFFD6D5046744920029250418491292492EC052200000292"));
		}

	}
}
