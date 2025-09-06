import 'dart:io';

/// 音频文件模型
class AudioFile {
  final String path;
  final String name;
  final String? artist;
  final String? album;
  final Duration? duration;
  final DateTime dateModified;
  final int size;

  AudioFile({
    required this.path,
    required this.name,
    this.artist,
    this.album,
    this.duration,
    required this.dateModified,
    required this.size,
  });

  /// 从文件创建AudioFile对象
  factory AudioFile.fromFile(File file) {
    final fileName = file.path.split('\\').last;
    final nameWithoutExtension =
        fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;

    return AudioFile(
      path: file.path,
      name: nameWithoutExtension,
      dateModified: file.lastModifiedSync(),
      size: file.lengthSync(),
    );
  }

  /// 获取文件扩展名
  String get extension {
    return path.split('.').last.toLowerCase();
  }

  /// 获取格式化的文件大小
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// 获取格式化的时长
  String get formattedDuration {
    if (duration == null) return '未知';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioFile && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() {
    return 'AudioFile(name: $name, path: $path)';
  }
}

/// 播放列表模型
class Playlist {
  final String id;
  final String name;
  final List<AudioFile> songs;
  final DateTime createdAt;
  DateTime updatedAt;

  Playlist({
    required this.id,
    required this.name,
    required this.songs,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 创建新的播放列表
  factory Playlist.create(String name, [List<AudioFile>? initialSongs]) {
    final now = DateTime.now();
    return Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songs: initialSongs ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 添加歌曲
  void addSong(AudioFile song) {
    if (!songs.contains(song)) {
      songs.add(song);
      updatedAt = DateTime.now();
    }
  }

  /// 添加多首歌曲
  void addSongs(List<AudioFile> newSongs) {
    for (final song in newSongs) {
      if (!songs.contains(song)) {
        songs.add(song);
      }
    }
    if (newSongs.isNotEmpty) {
      updatedAt = DateTime.now();
    }
  }

  /// 移除歌曲
  bool removeSong(AudioFile song) {
    final removed = songs.remove(song);
    if (removed) {
      updatedAt = DateTime.now();
    }
    return removed;
  }

  /// 移除指定索引的歌曲
  AudioFile? removeSongAt(int index) {
    if (index >= 0 && index < songs.length) {
      final song = songs.removeAt(index);
      updatedAt = DateTime.now();
      return song;
    }
    return null;
  }

  /// 移动歌曲位置
  bool moveSong(int oldIndex, int newIndex) {
    if (oldIndex >= 0 &&
        oldIndex < songs.length &&
        newIndex >= 0 &&
        newIndex < songs.length &&
        oldIndex != newIndex) {
      final song = songs.removeAt(oldIndex);
      songs.insert(newIndex, song);
      updatedAt = DateTime.now();
      return true;
    }
    return false;
  }

  /// 清空播放列表
  void clear() {
    songs.clear();
    updatedAt = DateTime.now();
  }

  /// 获取播放列表总时长
  Duration get totalDuration {
    return songs.fold(Duration.zero, (total, song) {
      return total + (song.duration ?? Duration.zero);
    });
  }

  /// 获取格式化的总时长
  String get formattedTotalDuration {
    final total = totalDuration;
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    final seconds = total.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// 获取播放列表大小
  int get songCount => songs.length;

  /// 检查是否为空
  bool get isEmpty => songs.isEmpty;

  /// 检查是否不为空
  bool get isNotEmpty => songs.isNotEmpty;

  @override
  String toString() {
    return 'Playlist(name: $name, songs: ${songs.length})';
  }
}
