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
	import flash.media.MicrophoneEnhancedMode;
	import flash.media.MicrophoneEnhancedOptions;
	import flash.media.Sound;
	import flash.media.SoundLoaderContext;
	import flash.media.SoundMixer;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;

	/**
	 * @author Humanoid
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="640", height="480")]
	public class MicrophoneEncodeDecodeTest extends Sprite {

		public static const SAMPLE_RATE: int = 44100;
		public static const FRAME_SAMPLES: int = GSM.FRAME_SAMPLES * SAMPLE_RATE / GSM.SAMPLE_RATE;

		private var microphone: Microphone;
		private var encoder: GSMEncoder;
		private var field: TextField;
		
		private var decoder: GSMDecoder;
		private var sound: Sound;
		
		var input: Vector.<int> = new <int>[];
		var inputPosition: int;
		private var bitmap: BitmapData;
		
		public function MicrophoneEncodeDecodeTest() {
			try {
				initStage();
				initView();
				initEncoder();
				initDecoder();
				initMicrophone();
				initSound();
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
			
			addChild(new Bitmap(bitmap = new BitmapData(640, 128, false, 0x002200)));
		}

		private function initEncoder(): void {
			encoder = new GSMEncoder();
		}

		private function initMicrophone(): void {
			microphone = Microphone.getEnhancedMicrophone();

			if (microphone) {
				
				var options:MicrophoneEnhancedOptions = new MicrophoneEnhancedOptions();
				options.nonLinearProcessing = true;
				options.echoPath = 128;
				options.mode = MicrophoneEnhancedMode.FULL_DUPLEX;						
				microphone.enhancedOptions = options;
				
				microphone.setUseEchoSuppression(true);
				microphone.encodeQuality = 6;
				microphone.setSilenceLevel(0);
				microphone.gain = 75;
				microphone.rate = 44;
				microphone.addEventListener(StatusEvent.STATUS, _status);
				microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, _samplein);

			} else {
				throw new Error("No microphone found");
			}
		}

		private function initSound(): void {
			
			SoundMixer.bufferTime = 0;
			SoundMixer.useSpeakerphoneForVoice = true;
            
			var context: SoundLoaderContext = new SoundLoaderContext();
			context.bufferTime = 0;
			
			sound = new Sound(null, context);
			sound.addEventListener(SampleDataEvent.SAMPLE_DATA, _sampleout);
			sound.play();
		}

		private function _samplein(event: SampleDataEvent): void {
			var data: ByteArray = event.data;
			try {
				while (data.bytesAvailable > 4) {
					var sample: Number = data.readFloat();
					input[input.length] = int(sample * 32767);

					if (input.length - inputPosition == FRAME_SAMPLES) {
						downsample(input, inputPosition);
						input.length = inputPosition + GSM.FRAME_SAMPLES;
						inputPosition = input.length;
					}
				}
			} catch (e: *) {
				trace("in:" + e);
			}
		}

		private function downsample(input: Vector.<int>, position: int): void {
			var index:int;
			var old:int;
			var count:int = 1;
			
			for (var i: int = 1; i < FRAME_SAMPLES; i++) {
				index = Math.round(i * GSM.FRAME_SAMPLES / FRAME_SAMPLES);
				if (index == old) {
					count++;
					input[position + index] += input[position + i];
				} else {
					input[position + old] /= count;
					old = index;
					count = 0;
				}
			}
			
			if (count) {
				input[position + old] /= count;
			}
		}
		
		private function _sampleout(event: SampleDataEvent): void {
			var total: int;
			var min: int = 2048;
			var max:int = 8192;
			var data: ByteArray = event.data;
			var i:int = 0;
			
			try {
				
				while(inputPosition > 0 && total + FRAME_SAMPLES < max) {
					var signal: Vector.<int> = input.splice(0, GSM.FRAME_SAMPLES);
					inputPosition -= GSM.FRAME_SAMPLES;
					
					var frame: Vector.<int> = decoder.decode(encoder.encode(signal));
					
					for (i = 0; i < GSM.FRAME_SAMPLES; i++) {
						bitmap.setPixel(1, bitmap.height * (0.5 + signal[i] * 0.5 / 32768), 0x00ff00);
						bitmap.setPixel(1, bitmap.height * (0.5 + frame[i] * 0.5 / 32768), 0xff0000);
						bitmap.scroll(1, 0);
					}
					
					for (i = 0; i < FRAME_SAMPLES; i++) {
						var value: Number = frame[int(i * GSM.FRAME_SAMPLES / FRAME_SAMPLES)] / 32768;						
						event.data.writeFloat(value);
						event.data.writeFloat(value);
					}
					
					total += FRAME_SAMPLES;
				}
				
				if (inputPosition > GSM.FRAME_SAMPLES) {
					input.length = 0;
					inputPosition = 0;
				}
				
				while (total++ < min) {
					data.writeFloat(0);
					data.writeFloat(0);
				}
				
				field.text = "GSM-FR Encoding\n" +
					"Input: " + (microphone ? microphone.name : "No microphone") + "\n" +
					"Output: Sound Object\n" + 
					"--\n";

			} catch (e: *) {
				trace("out:" + e);
			}
		}

		private function _status(event: StatusEvent): void {
			trace(event.type);
		}
	}
}