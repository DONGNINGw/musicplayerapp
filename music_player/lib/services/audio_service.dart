import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

/// 音频播放服务类
/// 负责管理音频播放的核心功能
class AudioPlayerService extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  
  // 播放状态
  bool _isPlaying = false;
  bool _isPaused = false;
  
  // 当前播放信息
  String? _currentFilePath;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  
  // Getters
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  String? get currentFilePath => _currentFilePath;
  Duration get duration => _duration;
  Duration get position => _position;
  double get volume => _volume;
  
  AudioPlayerService() {
    _initializePlayer();
  }
  
  /// 初始化音频播放器
  void _initializePlayer() {
    _audioPlayer = AudioPlayer();
    
    // 监听播放状态变化
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isPaused = state.processingState == ProcessingState.ready && !state.playing;
      notifyListeners();
    });
    
    // 监听播放进度
    _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });
    
    // 监听音频时长
    _audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });
  }
  
  /// 播放音频文件
  /// [filePath] 音频文件路径
  Future<void> playAudio(String filePath) async {
    try {
      _currentFilePath = filePath;
      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('播放音频失败: $e');
      rethrow;
    }
  }
  
  /// 暂停播放
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('暂停播放失败: $e');
    }
  }
  
  /// 恢复播放
  Future<void> resume() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('恢复播放失败: $e');
    }
  }
  
  /// 停止播放
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentFilePath = null;
      _position = Duration.zero;
      notifyListeners();
    } catch (e) {
      debugPrint('停止播放失败: $e');
    }
  }
  
  /// 设置播放位置
  /// [position] 目标位置
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('设置播放位置失败: $e');
    }
  }
  
  /// 设置音量
  /// [volume] 音量值 (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      debugPrint('设置音量失败: $e');
    }
  }
  
  /// 切换播放/暂停状态
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else if (_isPaused) {
      await resume();
    }
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}