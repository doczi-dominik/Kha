package kha;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import kha.audio2.ogg.vorbis.Reader;

/**
 * Contains compressed or uncompressed audio data.
 */
@:cppFileCode("\n#define STB_VORBIS_HEADER_ONLY\n#include <kinc/libs/stb_vorbis.c>")
class Sound implements Resource {
	public var compressedData: Bytes;
	public var uncompressedData: kha.arrays.Float32Array;
	public var length: Float = 0; // in seconds
	public var channels: Int = 0;
	public var sampleRate: Int = 0;

	public function new() {}

	#if kha_kore
	public function uncompress(done: Void->Void): Void {
		if (uncompressedData != null) {
			done();
			return;
		}

		var samples: Int = 0;
		var channels: Int = 0;
		var samplesPerSecond: Int = 0;

		untyped __cpp__("int16_t *data = nullptr");
		untyped __cpp__("samples = stb_vorbis_decode_memory((uint8_t*)compressedData->b->GetBase(), compressedData->length, &channels, &samplesPerSecond, &data)");

		if (channels == 1) {
			length = samples / samplesPerSecond;
			uncompressedData = new kha.arrays.Float32Array(samples * 2);
			for (i in 0...samples) {
				untyped __cpp__("*((float*)&this->uncompressedData->self.data[({0} * 2) * 4]) = data[{0}] / 32767.0f", i);
				untyped __cpp__("*((float*)&this->uncompressedData->self.data[({0} * 2 + 1) * 4]) = data[{0}] / 32767.0f", i);
			}
		}
		else {
			length = samples / samplesPerSecond;
			uncompressedData = new kha.arrays.Float32Array(samples * 2);
			for (i in 0...samples * 2) {
				untyped __cpp__("*((float*)&this->uncompressedData->self.data[({0} * 2) * 4]) = data[{0}] / 32767.0f", i);
			}
		}
		this.channels = channels;
		this.sampleRate = samplesPerSecond;

		untyped __cpp__("delete[] data");

		compressedData = null;
		done();
	}
	#else
	public function uncompress(done: Void->Void): Void {
		#if (!kha_no_ogg)
		if (uncompressedData != null) {
			done();
			return;
		}

		var output = new BytesOutput();
		var header = Reader.readAll(compressedData, output, true);
		var soundBytes = output.getBytes();
		var count = Std.int(soundBytes.length / 4);
		if (header.channel == 1) {
			length = count / kha.audio2.Audio.samplesPerSecond; // header.sampleRate;
			uncompressedData = new kha.arrays.Float32Array(count * 2);
			for (i in 0...count) {
				uncompressedData[i * 2 + 0] = soundBytes.getFloat(i * 4);
				uncompressedData[i * 2 + 1] = soundBytes.getFloat(i * 4);
			}
		}
		else {
			length = count / 2 / kha.audio2.Audio.samplesPerSecond; // header.sampleRate;
			uncompressedData = new kha.arrays.Float32Array(count);
			for (i in 0...count) {
				uncompressedData[i] = soundBytes.getFloat(i * 4);
			}
		}
		channels = header.channel;
		sampleRate = header.sampleRate;
		compressedData = null;
		done();
		#end
	}
	#end

	public function unload() {
		compressedData = null;
		uncompressedData = null;
	}
}
