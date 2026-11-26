import 'dart:io';

import 'package:record/record.dart';

import 'speech_repository.dart';

/// Records a short voice clip and turns it into text. The page owns the
/// recording/transcribing UI state; this owns the device and temp files.
abstract class VoiceInput {
  bool get isRecording;

  Future<bool> hasPermission();

  Future<void> start();

  /// Stops, transcribes, deletes the temp file, and returns the transcript.
  /// Returns null when nothing intelligible was captured.
  Future<String?> stopAndTranscribe();

  Future<void> dispose();
}

class DeviceVoiceInput implements VoiceInput {
  DeviceVoiceInput(this._speech, {AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final SpeechRepository _speech;
  final AudioRecorder _recorder;
  String? _path;
  var _isRecording = false;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    final path =
        '${Directory.systemTemp.path}/named-voice-'
        '${DateTime.now().microsecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: path,
    );
    _path = path;
    _isRecording = true;
  }

  @override
  Future<String?> stopAndTranscribe() async {
    if (!_isRecording) {
      return null;
    }
    _isRecording = false;
    final expected = _path;
    _path = null;
    try {
      final path = await _recorder.stop() ?? expected;
      if (path == null) {
        return null;
      }
      final bytes = await File(path).readAsBytes();
      await _deleteQuietly(path);
      final text = await _speech.transcribe(bytes);
      final trimmed = text.trim();
      return trimmed.isEmpty ? null : trimmed;
    } finally {
      if (expected != null) {
        await _deleteQuietly(expected);
      }
    }
  }

  @override
  Future<void> dispose() async {
    final expected = _path;
    final wasRecording = _isRecording;
    _path = null;
    _isRecording = false;
    if (wasRecording) {
      try {
        await _recorder.stop();
      } catch (_) {
        // Best-effort stop when the page closes mid-recording.
      }
    }
    if (expected != null) {
      await _deleteQuietly(expected);
    }
    await _recorder.dispose();
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } catch (_) {
      // Best-effort cleanup of the temporary recording.
    }
  }
}
