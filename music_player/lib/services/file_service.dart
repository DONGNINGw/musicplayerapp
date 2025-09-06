import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 文件管理服务
/// 负责扫描本地音频文件和管理文件访问权限
class FileService extends ChangeNotifier {
  // 支持的音频格式
  static const List<String> supportedFormats = [
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.m4a',
  ];

  // 扫描到的音频文件列表
  List<File> _audioFiles = [];
  List<File> get audioFiles => _audioFiles;

  // 扫描状态
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // 上次扫描时间
  DateTime? _lastScanTime;
  DateTime? get lastScanTime => _lastScanTime;

  // 扫描错误信息
  String? _scanError;
  String? get scanError => _scanError;

  /// 请求存储权限
  Future<bool> requestPermissions() async {
    // 根据平台请求不同的权限
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.storage.request();
      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS不需要显式请求文件访问权限
      return true;
    } else {
      // 桌面平台默认有权限
      return true;
    }
  }

  /// 扫描指定目录下的音频文件
  Future<void> scanDirectory(String directoryPath) async {
    try {
      _isScanning = true;
      _scanError = null;
      notifyListeners();

      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        throw Exception('目录不存在: $directoryPath');
      }

      final files = await _scanRecursively(directory);
      _audioFiles = files;
      _lastScanTime = DateTime.now();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      _scanError = e.toString();
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 扫描音乐目录
  Future<void> scanMusicDirectory() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('没有存储访问权限');
      }

      // 获取音乐目录
      final directory = await _getMusicDirectory();
      await scanDirectory(directory.path);
    } catch (e) {
      _scanError = e.toString();
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 递归扫描目录下的所有音频文件
  Future<List<File>> _scanRecursively(Directory directory) async {
    List<File> audioFiles = [];

    try {
      final entities = await directory.list().toList();

      for (var entity in entities) {
        if (entity is File) {
          // 检查是否为支持的音频格式
          if (_isAudioFile(entity.path)) {
            audioFiles.add(entity);
          }
        } else if (entity is Directory) {
          // 递归扫描子目录
          final subFiles = await _scanRecursively(entity);
          audioFiles.addAll(subFiles);
        }
      }
    } catch (e) {
      // 忽略无法访问的目录
      debugPrint('无法访问目录: ${directory.path}, 错误: $e');
    }

    return audioFiles;
  }

  /// 检查文件是否为支持的音频格式
  bool _isAudioFile(String filePath) {
    final lowercasePath = filePath.toLowerCase();
    return supportedFormats.any((format) => lowercasePath.endsWith(format));
  }

  /// 获取音乐目录
  Future<Directory> _getMusicDirectory() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android平台使用外部存储的Music目录
      final directories = await getExternalStorageDirectories();
      if (directories != null && directories.isNotEmpty) {
        // 尝试找到Music目录
        final baseDir = directories.first.path.split('Android')[0];
        final musicDir = Directory('$baseDir/Music');
        if (await musicDir.exists()) {
          return musicDir;
        }
      }
      // 如果找不到Music目录，使用下载目录
      return await getExternalStorageDirectory() ??
          await getTemporaryDirectory();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS平台使用文档目录
      return await getApplicationDocumentsDirectory();
    } else {
      // 桌面平台使用临时目录
      return await getTemporaryDirectory();
    }
  }

  /// 清除扫描结果
  void clearScanResults() {
    _audioFiles = [];
    _lastScanTime = null;
    _scanError = null;
    notifyListeners();
  }
}
