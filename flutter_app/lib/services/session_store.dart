import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_user.dart';

class CheckInSessionStore {
  Future<AppUser?> load() async {
    final file = await _sessionFile();
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    if (content.isEmpty) return null;

    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) return null;

    final user = AppUser.fromJson(decoded);
    return user.id.isEmpty ? null : user;
  }

  Future<void> save(AppUser user) async {
    final file = await _sessionFile();
    await file.writeAsString(jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    final file = await _sessionFile();
    if (await file.exists()) await file.delete();
  }

  Future<File> _sessionFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/checkin_session.json');
  }
}
