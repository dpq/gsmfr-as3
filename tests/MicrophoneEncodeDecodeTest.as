package {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.SampleDataEvent;
	import flash.events.StatusEvent;
	import flash.media.Microphone;
	import flash.media.SoundCodec;
	import flash.utils.ByteArray;
	import org.glavbot.codecs.gsmfr.GSMEncoder;


	[SWF(backgroundColor="#000000", frameRate="60", width="640", height="480")]
	public class MicrophoneEncodeDecodeTest extends Sprite {

		private var microphone: Microphone;
		private var encoder: GSMEncoder;
		private var bitmap: BitmapData;
		private var frame: Vector.<Number> = new <Number>[];
				
		public function MicrophoneEncodeDecodeTest() {
			try {
				initStage();
				initView();
				initEncoder();
				initMicrophone();
			} catch (error:*) {
				trace(error);
			}
		}

		private function initStage(): void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.showDefaultContextMenu = false;
			stage.stageFocusRect = false;
			stage.frameRate = 60;
		}

		private function initView(): void {
			addChild(new Bitmap(bitmap = new BitmapData(stage.stageWidth, 256, false, 0)));
		}

		private function initEncoder(): void {
			encoder = new GSMEncoder();
		}

		private function initMicrophone(): void {
			microphone = Microphone.getEnhancedMicrophone();

			if (microphone) {
				microphone.setLoopBack(false);
				microphone.encodeQuality = 5;
				microphone.setSilenceLevel(0);
				microphone.gain = 75;
				microphone.rate = 44;
				microphone.framesPerPacket = 1;
				microphone.codec = SoundCodec.SPEEX;				
				microphone.addEventListener(StatusEvent.STATUS, _status);
				microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, _sample);
				
			} else {
				throw new Error("No microphone found");
			}
		}
		
		private function _sample(event: SampleDataEvent): void {
			try {
				var data:ByteArray = event.data;
				var count:int = data.bytesAvailable / 16;
				var left:Number;
				var right: Number;
				var frame: Vector.<Number> = this.frame;
				var index:int = frame.length;
				var size:int = GSMEncoder.FRAME_SIZE;
								
				for(var i:int = 0; i < count; i++) {
					left = data.readFloat();
					right = data.readFloat();
					
					// TODO: resample...
					// TODO: try different types of left+right channel mixing
					
					frame[index++] = (left + right) / 2;
					
					if (index == size) {
						encoder.encode(frame);
						frame.length = index = 0;
					}
					
					left = int(left * 127);
					right = int(right * 127);
					
					if (left == right) {
						bitmap.setPixel(1, 128 + left, 0xffff00);						
					} else {
						bitmap.setPixel(1, 128 + left, 0x00ff00);
						bitmap.setPixel(1, 128 + right, 0xff0000);
					}
					bitmap.scroll(1, 0);	
				}				
			} catch (error:*) {
				trace(error);
			}
		}

		private function _status(event: StatusEvent): void {
			trace(event.type);
		}
	}
}
