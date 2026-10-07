import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myapps_ai/myapps_ai.dart' hide OnDeviceAiService;
import 'package:myapps_data/myapps_data.dart';
import 'package:my_day/features/ai/services/ai_source_backend.dart';
import 'package:my_day/features/ai/services/on_device_ai_service.dart';

class _Storage implements StorageAdapter {
  _Storage(this.dir);
  final Directory dir;
  Map<String, dynamic> config = {'unrelated': 'keep'};
  @override
  Future<Directory> getAppDir() async => dir;
  @override
  Future<Map<String, dynamic>> readConfig() async => Map.of(config);
  @override
  Future<void> writeConfig(Map<String, dynamic> value) async =>
      config.addAll(value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('installed local model generates through the app runtime on Linux', () async {
    final model = Platform.environment['LLAMA_TEST_MODEL']!;
    final dir = await Directory.systemTemp.createTemp('source_live');
    addTearDown(() => dir.delete(recursive: true));
    final storage = _Storage(dir);
    final backend = AiSourceBackend(storage: storage);
    final manifest = backend.catalog.first;
    final artifactDir = await backend.manager.artifactDir(manifest.artifactId);
    await artifactDir.create(recursive: true);
    await Link('${artifactDir.path}/${manifest.files.first.path}').create(model);
    await File('${artifactDir.path}/manifest.json').writeAsString(jsonEncode(manifest.toJson()));
    await backend.select(manifest.modelId);
    final service = OnDeviceAiService(backend: backend);
    await service.setEnabled(true);
    expect(service.canGenerate, isTrue);
    expect(await service.generate(instructions: 'Answer briefly.', prompt: 'What is the capital of France?'), contains('Paris'));
    await service.setEnabled(false);
    await backend.select('system');
    service.dispose();
  }, skip: Platform.environment['LLAMA_TEST_MODEL'] == null);
  test(
    'missing selected model is unavailable without downloading or overwriting config',
    () async {
      final dir = await Directory.systemTemp.createTemp('source_test');
      addTearDown(() => dir.delete(recursive: true));
      final storage = _Storage(dir);
      final backend = AiSourceBackend(storage: storage);
      await backend.initialize();
      expect(await Directory('${dir.path}/ai_models').exists(), isFalse);
      await backend.select('local:qwen3.5-0.8b');
      expect((await backend.statusReport()).status, GenAiStatus.unavailable);
      expect(storage.config['unrelated'], 'keep');
      expect(await Directory('${dir.path}/ai_models').exists(), isFalse);
      final restored = AiSourceBackend(storage: storage);
      await restored.initialize();
      expect(restored.selection.global, 'local:qwen3.5-0.8b');
      expect(restored.catalog.length, 3);
    },
  );
}
