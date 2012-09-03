package {

	import org.glavbot.codecs.gsmfr.GSMEncoder;

	import flash.display.Sprite;
	import flash.utils.ByteArray;

	/**
	 * @author Humanoid
	 */
	public class RandomFramesEncodeTest extends Sprite {
		
		[Embed(source="/../samples/random_pcm_gsm_encode_test.txt", mimeType="application/octet-stream")]
		private var TestData: Class;

		private var encoder: GSMEncoder = new GSMEncoder();
				
		public function RandomFramesEncodeTest() {
			var bytes:ByteArray = new TestData();
			var lines:Array = bytes.readUTFBytes(bytes.length).split("\n");
			var index:int = 0;
			 
			for each(var line:String in lines) {
				var parts:Array = line.split(" ");
				var input: Vector.<int> = Vector.<int>(parts[0].split(","));
												
				if (input.length == 160) {
					trace("Frame #" + index +":");
					trace("input: ["+input+"]");
					var frame: ByteArray = encoder.encode(input);
					var encoded: String = "";
					for (var i: int = 0; i < frame.length; i++) {
						var r:String = frame[i].toString(16).toUpperCase();
						encoded += (r.length == 2) ? r : "0"+r;
					}			
					trace("encoded: " + encoded);		
					index++;
					
					if (encoded != parts[1]) {
						trace("FAIL");
					}
					
					trace("");
				}
			}
		}

	}
}
