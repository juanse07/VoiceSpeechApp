import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';

class AudioService {
  AudioService()
      : _recorder = FlutterSoundRecorder(),
        _player = AudioPlayer();

  final FlutterSoundRecorder _recorder;
  final AudioPlayer _player;
  String? _currentRecordingPath;

  // Recording state streams
  Stream<Duration> get recordingPosition =>
      _recorder.onProgress?.map((e) => e.duration) ??
      const Stream.empty();

  // Playback state
  Stream<Duration> get playbackPosition => _player.positionStream;
  Stream<Duration?> get playbackDuration => _player.durationStream;
  Stream<bool> get isPlayingStream =>
      _player.playingStream;

  Future<void> initialize() async {
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(
      const Duration(milliseconds: 100),
    );
  }

  Future<void> dispose() async {
    await _recorder.closeRecorder();
    await _player.dispose();
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> startRecording() async {
    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied.');
    }

    final dir = await getTemporaryDirectory();
    final id = const Uuid().v4().substring(0, 8);
    _currentRecordingPath =
        '${dir.path}/recording_$id${AppConstants.audioFileExtension}';

    await _recorder.startRecorder(
      toFile: _currentRecordingPath,
      codec: Codec.pcm16WAV,
      sampleRate: AppConstants.audioSampleRate,
      numChannels: AppConstants.audioChannels,
    );

    return _currentRecordingPath!;
  }

  Future<String> stopRecording() async {
    await _recorder.stopRecorder();
    if (_currentRecordingPath == null) {
      throw Exception('No recording in progress.');
    }
    return _currentRecordingPath!;
  }

  bool get isRecording => _recorder.isRecording;

  // Playback
  Future<void> loadAudio(String filePath) async {
    await _player.setFilePath(filePath);
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }
}
