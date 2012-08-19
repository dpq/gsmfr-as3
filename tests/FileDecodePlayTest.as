package {

	import org.glavbot.codecs.gsmfr.GSM;
	import org.glavbot.codecs.gsmfr.GSMDecoder;

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	/**
	 * @author Vasiliy Vasilyev
	 */
	[SWF(backgroundColor="#000000", frameRate="31", width="640", height="480")]
	public class FileDecodePlayTest extends Sprite {

		public static const SAMPLE_RATE: int = 44100;
		public static const FRAME_SAMPLES: int = GSM.FRAME_SAMPLES * SAMPLE_RATE / GSM.SAMPLE_RATE;

		[Embed(source="/../samples/sample_beatsix_littlemess_gsmfr.raw", mimeType="application/octet-stream")]
		private var InputData: Class;

		private var input: ByteArray;
		private var decoder: GSMDecoder;
		private var sound: Sound;
		private var field: TextField;

		private var framesProcessed: int;
		private var timeTotal: int;
		private var timeProcessed: int;
		private var timeResampled: int;
		private var timeLastSample: int;

		public function FileDecodePlayTest() {
			try {
				initStage();
				initView();
				initInput();
				initDecoder();
				initSound();
			} catch (error: Error) {
				trace(error.getStackTrace());
			}
		}

		private function initStage(): void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.showDefaultContextMenu = false;
			stage.stageFocusRect = false;
			stage.frameRate = 31;
		}

		private function initView(): void {
			field = new TextField();
			field.defaultTextFormat = new TextFormat("_typewriter", 12, 0xffff00);
			field.autoSize = TextFieldAutoSize.LEFT;
			field.multiline = true;
			field.wordWrap = false;
			field.selectable = false;
			field.mouseEnabled = false;
			addChild(field);
		}

		private function initInput(): void {
			input = new InputData();
		}

		private function initDecoder(): void {
			decoder = new GSMDecoder();
		}

		private function initSound(): void {
			sound = new Sound();
			sound.addEventListener(SampleDataEvent.SAMPLE_DATA, _sample);
			sound.play();
		}

		private function _sample(event: SampleDataEvent): void {
			try {
				// Minimum required samples count
				var samples: int = 2048;
				var timeStart: int = getTimer();

				while (samples > 0 && input.bytesAvailable > GSM.FRAME_SIZE) {
					var time: int = getTimer();
					var frame: Vector.<int> = decoder.decode(input);
					var scale: Number = GSM.FRAME_SAMPLES / FRAME_SAMPLES;

					timeProcessed += getTimer() - time;
					time = getTimer();

					for (var i: int = 0; i < FRAME_SAMPLES; i++) {
						var value: Number = frame[int(i * scale)] / 32768;
						event.data.writeFloat(value);
						event.data.writeFloat(value);
					}
					timeResampled += getTimer() - time;
					framesProcessed++;

					samples -= FRAME_SAMPLES;
				}

				while (samples-- > 0) {
					event.data.writeFloat(0);
					event.data.writeFloat(0);
				}

				timeTotal += getTimer() - timeStart;

				field.text = "GSM-FR Decoding\n" + "Input: File(read position:" + input.position + ", length:" + input.length + ")\n" + "Output: Sound object\n--\n" + "Frame process time: " + Math.round(timeTotal / framesProcessed) + "ms (" + Math.round(framesProcessed * 1000 / timeTotal) + "fps)\n" + "Frame decode time: " + Math.round(timeProcessed / framesProcessed) + "ms\n" + "Frame resampe+write time: " + Math.round(timeResampled / framesProcessed) + "ms\n" + "Frames processed: " + framesProcessed + "\n" + "Sample request delay: " + (getTimer() - timeLastSample) + "ms";

				timeLastSample = getTimer();

			} catch (e: Error) {
				trace(e.getStackTrace());
			}
		}

	}
}
