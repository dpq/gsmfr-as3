gsmfr-as3
=========

ETSI GSM 06.10 RPELTP (Regular Pulse Excitation-Long Term-Prediction-Linear Predictive Coder) Speech Coder Implementation

Coding Rate: 13.2kbps
Sampling Rate: 8000Hz

Encoding:

	var encoder: GSMEncoder = new GSMEncoder();
	var data: Vector<int> = readSamples(); // 160 samples of PCM 8000Hz 16bit
	var frame: ByteArray = encoder.encode( data ); // 33 bytes of GSM-FR encoded data

Decoding:

	var decoder: GSMDecoder = new GSMDecoder();
	var frame: ByteArray = readBytes(); // 33 bytes of GSM-FR encoded data
	var data: Vector<int> = decoder.decode( frame ); // 160 samples of PCM 8000Hz 16bit