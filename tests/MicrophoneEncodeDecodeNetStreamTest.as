package {

	import org.glavbot.codecs.gsmfr.GSM;
	import org.glavbot.codecs.gsmfr.GSMDecoder;
	import org.glavbot.codecs.gsmfr.GSMEncoder;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.NetStatusEvent;
	import flash.events.SampleDataEvent;
	import flash.media.Microphone;
	import flash.media.MicrophoneEnhancedMode;
	import flash.media.MicrophoneEnhancedOptions;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamAppendBytesAction;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;

	/**
	 * @author Vasiliy Vasilyev developer@flashgate.org
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="640", height="480")]
	public class MicrophoneEncodeDecodeNetStreamTest extends Sprite {

		public static const SAMPLE_RATE: int = 44100;
		public static const FRAME_SAMPLES: int = GSM.FRAME_SAMPLES * SAMPLE_RATE / GSM.SAMPLE_RATE;

		private var microphone: Microphone;
		private var encoder: GSMEncoder;
		private var field: TextField;
		
		private var decoder: GSMDecoder;
		
		private var input: Vector.<int> = new <int>[];
				
		private var bitmap: BitmapData;
		private var connection: NetConnection;
		private var stream: NetStream;
		private var tag: ByteArray;
		
		public function MicrophoneEncodeDecodeNetStreamTest() {
			try {
				initStage();
				initView();
				initEncoder();
				initDecoder();
				initMicrophone();
				initConnection();
			} catch (error: *) {
				trace(error);
			}
		}

		private function initConnection(): void {
			connection = new NetConnection();
			connection.addEventListener(NetStatusEvent.NET_STATUS, _status);
			connection.connect(null);
		}

		private function _status(event: NetStatusEvent): void {
			var code:String = event.info["code"];
			switch (code) {
				case "NetConnection.Connect.Success":
					initStream();
					break;
			}
			trace(code);
		}

		private function initStream(): void {
			stream = new NetStream(connection);
			stream.bufferTime = 0;
			stream.bufferTimeMax = 0.01;
			try {
				// fp 11.3+ is required
				stream["useJitterBuffer"] = true;
			} catch (e:*) {
				trace("NetStream.useJitterBuffer is not supported");
			}
			stream.addEventListener(NetStatusEvent.NET_STATUS, _status);
			
			var header : ByteArray = new ByteArray();
			header.endian = Endian.BIG_ENDIAN;
			header.writeByte(0x46); // F
			header.writeByte(0x4C); // L
			header.writeByte(0x56); // V
			header.writeByte(0x01); // version = 0x01
			header.writeByte(0x04); // audio only = 0x04
			header.writeUnsignedInt(0x09); // header length = 0x09
			header.writeUnsignedInt(0x00); // previous tag size
			
			tag = new ByteArray();
			
			stream.play(null);
			stream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
			stream.appendBytes(header);
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
				options.autoGain = true;
				options.mode = MicrophoneEnhancedMode.FULL_DUPLEX;						
				microphone.enhancedOptions = options;
				
				microphone.setUseEchoSuppression(true);
				microphone.encodeQuality = 6;
				microphone.setSilenceLevel(0);
				microphone.enableVAD = true;
				microphone.gain = 50;
				microphone.rate = 44;
				microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, _samplein);

			} else {
				throw new Error("No microphone found");
			}
		}
		
		private function _samplein(event: SampleDataEvent): void {
			var data: ByteArray = event.data;
			var i:int;
			
			try {
				while (data.bytesAvailable > 4) {
					var sample: Number = data.readFloat();
					input[input.length] = int(sample * 32767);

					if (input.length == FRAME_SAMPLES) {
						downsample(input);

						var reencoded: Vector.<int> = decoder.decode(encoder.encode(input.slice())); // do not slice in production, reuse
						
						for (i = 0; i < GSM.FRAME_SAMPLES; i++) {
							bitmap.setPixel(1, bitmap.height * (0.5 + input[i] * 0.5 / 32768), 0x00ff00);
							bitmap.setPixel(1, bitmap.height * (0.5 + reencoded[i] * 0.5 / 32768), 0xff0000);
							bitmap.scroll(1, 0);
						}
						
						streamOut(reencoded);						
						input.length = 0;						
					}					
				}
			} catch (e: Error) {
				trace("in:" + e.getStackTrace());
			}
		}
		
		private var start:int = 0;

		private function streamOut(input: Vector.<int>): void {
			tag.endian = Endian.BIG_ENDIAN;
			tag.position = 0;
			tag.length = 0;
			
			tag.writeByte(0x08); // audio packet			
			tag.writeByte(0); // length placeholder
			tag.writeShort(0);
			
			var time:int = getTimer();
			var i:int;
			
			if (start) {			
				var timestamp:int = time - start;				
				
				tag.writeByte((timestamp & 0xff0000) >> 16); // timstamp
				tag.writeShort(timestamp & 0xffff);
				tag.writeByte((timestamp & 0xff000000) >> 24);
				
				start--; // eats cumulative latency
			} else {
				start = time - 10000; // first packet shift to make use bufferMaxTime
				tag.writeUnsignedInt(0);
			}
			
			tag.writeByte(0); // stream id
			tag.writeShort(0);
			
			// data 
			
			tag.writeByte((3 << 4) | (3 << 2) | (1 << 1) | 0); // LPCM-LE, 44KHz, 16bit, mono			
			tag.endian = Endian.LITTLE_ENDIAN;		
				
			for (i = 0; i < FRAME_SAMPLES; i++) {
				var value: Number = input[int(i * GSM.FRAME_SAMPLES / FRAME_SAMPLES)];						
				tag.writeShort(value);
			}
			
			tag.endian = Endian.BIG_ENDIAN;
			tag.writeUnsignedInt(tag.position);
			
			// length
			
			var length:int = tag.position - 15;
			tag.position = 1;
			tag.writeByte((length & 0xff0000) >> 16);
			tag.writeShort(length & 0xffff);	
			
			if (stream) {
				stream.appendBytes(tag);
			}
		}

		private function downsample(input: Vector.<int>): void {
			var index:int;
			var old:int;
			var count:int = 1;
			
			for (var i: int = 1; i < FRAME_SAMPLES; i++) {
				index = Math.round(i * GSM.FRAME_SAMPLES / FRAME_SAMPLES);
				if (index == old) {
					count++;
					input[index] += input[i];
				} else {
					input[old] /= count;
					old = index;
					count = 0;
				}
			}
			
			if (count) {
				input[old] /= count;
			}
		}
				
	}
}