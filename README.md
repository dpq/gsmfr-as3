gsmfr-as3
=========

Encoding:
---------
	var encoder: GSMEncoder = new GSMEncoder();
	var data: Vector<int> = readSamples(); // 8KHz 16bit sample data
	var frame: ByteArray = encoder.encode( data ); // 33 bytes

Decoding:
---------
	var decoder: GSMDecoder = new GSMDecoder();
	var frame: ByteArray = readBytes(); // 33 bytes
	var data: Vector<int> = decoder.decode( frame ); // 8KHz 16bit sample data