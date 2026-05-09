import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class CheckInAudioService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<String> startRecording(String seniorId) async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('Microphone permission was not granted.');
    }

    final directory = await getTemporaryDirectory();
    final safeSeniorId = _safePathSegment(seniorId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final localPath =
        '${directory.path}${Platform.pathSeparator}checkin_${safeSeniorId}_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: localPath,
    );

    return localPath;
  }

  Future<String?> stopRecording() {
    return _recorder.stop();
  }

  Future<String> uploadRecording({
    required String seniorId,
    required String localPath,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Firebase is not initialized. Start the app with Firebase dart-defines.',
      );
    }

    final file = File(localPath);
    if (!file.existsSync()) {
      throw StateError('Recorded audio file could not be found.');
    }

    final safeSeniorId = _safePathSegment(seniorId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storage = FirebaseStorage.instance;
    final ref =
        storage.ref('triage_uploads/$safeSeniorId/checkin_$timestamp.m4a');

    await ref.putFile(
      file,
      SettableMetadata(
        contentType: 'audio/mp4',
        customMetadata: {'senior_id': seniorId},
      ),
    );

    final bucket = storage.bucket.replaceFirst(RegExp(r'^gs://'), '');
    return 'gs://$bucket/${ref.fullPath}';
  }

  void dispose() {
    _recorder.dispose();
  }

  String _safePathSegment(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  }
}
