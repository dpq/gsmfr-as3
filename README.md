gsmfr-as3
=========

var data: Vector<int>;	// 8KHz 16bit sample data
var frame: ByteArray;	// 33 bytes

// Encode
var encoder: GSMEncoder = new GSMEncoder();
frame = encoder.encode( data );

// Decode
var decoder: GSMDecoder = new GSMDecoder();
data = decoder.decode( frame );