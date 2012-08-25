gsmfr-as3
=========

Encoding:
	var encoder: GSMEncoder = new GSMEncoder();
	var data: Vector<int> = readSamples(); // 160 samples of PCM 8000Hz 16bit
	var frame: ByteArray = encoder.encode( data ); // 33 bytes of GSM-FR encoded data

Decoding:
	var decoder: GSMDecoder = new GSMDecoder();
	var frame: ByteArray = readBytes(); // 33 bytes of GSM-FR encoded data
	var data: Vector<int> = decoder.decode( frame ); // 160 samples of PCM 8000Hz 16bit