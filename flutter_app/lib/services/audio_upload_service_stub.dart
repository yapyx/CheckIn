class CheckInAudioService {
  Future<String> startRecording(String seniorId) {
    throw UnsupportedError(
      'Audio recording is only wired for mobile/desktop builds right now.',
    );
  }

  Future<String?> stopRecording() {
    throw UnsupportedError(
      'Audio recording is only wired for mobile/desktop builds right now.',
    );
  }

  Future<String> uploadRecording({
    required String seniorId,
    required String localPath,
  }) {
    throw UnsupportedError(
      'Firebase Storage upload is only wired for mobile/desktop builds right now.',
    );
  }

  void dispose() {}
}
