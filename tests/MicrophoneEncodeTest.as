package {

	import org.glavbot.codecs.gsmfr.GSM;
	import org.glavbot.codecs.gsmfr.GSMDecoder;
	import org.glavbot.codecs.gsmfr.GSMEncoder;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.SampleDataEvent;
	import flash.events.StatusEvent;
	import flash.media.Microphone;
	import flash.media.SoundCodec;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	/**
	 * @author Humanoid
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="640", height="480")]
	public class MicrophoneEncodeTest extends Sprite {

		public static const SAMPLE_RATE: int = 44100;
		public static const FRAME_SAMPLES: int = GSM.FRAME_SAMPLES * SAMPLE_RATE / GSM.SAMPLE_RATE;

		private var microphone: Microphone;
		private var encoder: GSMEncoder;
		private var field: TextField;
		private var frame: Vector.<int> = new <int>[];
		private var bitmap: BitmapData;
		private var decoder: GSMDecoder;
		private var image: Bitmap;
		private var timeProcessed: int;
		private var framesProcessed: int;
		private var timeTotal: int;
		private var timeLastSample: int;

		public function MicrophoneEncodeTest() {
			try {
				initStage();
				initView();
				initEncoder();
				initDecoder();
				initMicrophone();
			} catch (error: *) {
				trace(error);
			}
		}

		private function initDecoder(): void {
			decoder = new GSMDecoder();
		}

		private function initStage(): void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.showDefaultContextMenu = false;
			stage.stageFocusRect = false;
			stage.frameRate = 60;
		}

		private function initView(): void {
			field = new TextField();
			field.defaultTextFormat = new TextFormat("_typewriter", 12, 0xffff00);
			field.autoSize = TextFieldAutoSize.LEFT;
			field.multiline = true;
			field.wordWrap = false;
			field.selectable = false;
			field.mouseEnabled = false;
			field.y = 130;
			addChild(field);

			addChild(image = new Bitmap(bitmap = new BitmapData(640, 128, false, 0x002200)));
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
			
			var sampleTime:int = getTimer();
			var scale: Number = GSM.FRAME_SAMPLES / FRAME_SAMPLES;
			var data: ByteArray = event.data;
			var bytes: ByteArray;
			var i: int;

			// Sample contains 2560 bytes / 320 PCM samples

			while (data.bytesAvailable > 0) {

				var timeStart: int = getTimer();

				// Read and Convert float PCM to 16bit PCM

				frame.push(GSM.saturate(data.readFloat() * 32768));

				if (frame.length == FRAME_SAMPLES) {

					// Resample 44100Hz --> 8000Hz
					
					var sum:int = 1;
					var old:int;
					var index:int;
											
					for (i = 1; i < FRAME_SAMPLES; i++) {
						index = int(i * scale);
						
						if (old != index) {
							frame[old] = frame[old] / sum;
							sum = 1;
							old = index;
						} else {
							sum++;
						}
						
						frame[index] += frame[i];
					}
					
					index = FRAME_SAMPLES - 1;
					frame[index] = frame[index] / sum;

					var time: int = getTimer();

					bytes = encoder.encode(frame);
															
					timeProcessed += getTimer() - time;
					framesProcessed++;

					var decoded: Vector.<int> = decoder.decode(bytes);

					// Draw comparison graph

					for (i = 0; i < GSM.FRAME_SAMPLES; i++) {
						var recoded: int = bitmap.height * (0.5 + frame[i] * 0.5 / 32768);
						var captured: int = bitmap.height * (0.5 + decoded[i] * 0.5 / 32768);
						
						if (recoded == captured) {
							bitmap.setPixel(1, recoded, 0xffff00);
						} else {
							bitmap.setPixel(1, recoded, 0x00ff00);
							bitmap.setPixel(1, captured, 0xff0000);
						}
						bitmap.scroll(1, 0);
					}

					frame.length = 0;
				}

				timeTotal += getTimer() - timeStart;

			}

			field.text = "GSM-FR Encoding\n" +
					"Input: " + microphone.name + "\n" +
					"Output: Comparison Graph\n" + 
					"--\n" +
					"Performance: " + Math.round(framesProcessed * 1000 / timeProcessed) + "fps\n" +
					"Frame encode time: " + Math.round(timeProcessed / framesProcessed) + "ms\n" +
					"Frames processed: " + framesProcessed + "\n" +
					"Sample input delay: " + (sampleTime - timeLastSample) + "ms";

			timeLastSample = getTimer();
		}

		private function _status(event: StatusEvent): void {
			trace(event.type);
		}
	}
}
