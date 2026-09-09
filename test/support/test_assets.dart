/// Reads the generated content bundle straight from disk, so domain and widget
/// tests run against the real compiled content without a device.
///
/// Run `python scripts/build_content.py` before the test suite (CI does).
library;

import 'dart:convert';
import 'dart:io';

import 'package:ease_move/domain/exercise/exercise.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads synchronously on purpose: `testWidgets` runs inside fake async, where
/// real file I/O would never complete, so an asynchronous bundle would leave
/// every provider stuck in `AsyncLoading`.
class DiskAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final File file = File(key);
    if (!file.existsSync()) {
      throw FlutterError('Asset not found on disk: $key');
    }
    return ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final File file = File(key);
    if (!file.existsSync()) {
      throw FlutterError('Asset not found on disk: $key');
    }
    return file.readAsStringSync();
  }
}

Exercise loadExerciseFromDisk(String id) {
  final String raw = File('assets/content/exercises/$id.json')
      .readAsStringSync();
  return Exercise.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Map<String, dynamic> loadJsonFromDisk(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
