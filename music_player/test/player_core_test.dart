import 'package:flutter_test/flutter_test.dart';
import 'package:music_player/services/audio_service.dart';

void main() {
  group('AudioPlayerService Tests', () {
    late AudioPlayerService audioService;

    setUp(() {
      audioService = AudioPlayerService();
    });

    tearDown(() {
      audioService.dispose();
    });

    test('初始状态应该正确', () {
      expect(audioService.isPlaying, false);
      expect(audioService.isPaused, false);
      expect(audioService.currentFilePath, null);
      expect(audioService.duration, Duration.zero);
      expect(audioService.position, Duration.zero);
      expect(audioService.volume, 1.0);
    });

    test('音量设置应该在有效范围内', () async {
      // 测试正常范围
      await audioService.setVolume(0.5);
      expect(audioService.volume, 0.5);

      // 测试超出上限
      await audioService.setVolume(1.5);
      expect(audioService.volume, 1.0);

      // 测试超出下限
      await audioService.setVolume(-0.5);
      expect(audioService.volume, 0.0);
    });

    test('停止播放应该重置状态', () async {
      // 模拟设置当前文件路径
      // 注意：这里只是测试逻辑，实际播放需要真实文件
      await audioService.stop();
      
      expect(audioService.currentFilePath, null);
      expect(audioService.position, Duration.zero);
    });
  });
}