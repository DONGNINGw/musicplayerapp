import 'package:flutter/foundation.dart';
import '../models/playlist_model.dart';

/// 播放列表服务
class PlaylistService extends ChangeNotifier {
  final List<Playlist> _playlists = [];
  Playlist? _currentPlaylist;
  int _currentSongIndex = -1;
  bool _isShuffleMode = false;
  bool _isRepeatMode = false;
  final List<int> _shuffleOrder = [];
  int _shuffleIndex = -1;

  /// 获取所有播放列表
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  /// 获取当前播放列表
  Playlist? get currentPlaylist => _currentPlaylist;

  /// 获取当前歌曲索引
  int get currentSongIndex => _currentSongIndex;

  /// 获取当前播放的歌曲
  AudioFile? get currentSong {
    if (_currentPlaylist == null ||
        _currentSongIndex < 0 ||
        _currentSongIndex >= _currentPlaylist!.songs.length) {
      return null;
    }
    return _currentPlaylist!.songs[_currentSongIndex];
  }

  /// 是否为随机播放模式
  bool get isShuffleMode => _isShuffleMode;

  /// 是否为重复播放模式
  bool get isRepeatMode => _isRepeatMode;

  /// 创建新的播放列表
  Playlist createPlaylist(String name, [List<AudioFile>? initialSongs]) {
    final playlist = Playlist.create(name, initialSongs);
    _playlists.add(playlist);
    notifyListeners();
    return playlist;
  }

  /// 删除播放列表
  bool deletePlaylist(String playlistId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists.removeAt(index);
      // 如果删除的是当前播放列表，清除当前播放状态
      if (_currentPlaylist?.id == playlistId) {
        _currentPlaylist = null;
        _currentSongIndex = -1;
        _clearShuffleOrder();
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 重命名播放列表
  bool renamePlaylist(String playlistId, String newName) {
    final playlist = _playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => throw ArgumentError('Playlist not found'),
    );

    // 由于Playlist的name是final，我们需要创建一个新的播放列表
    final newPlaylist = Playlist(
      id: playlist.id,
      name: newName,
      songs: playlist.songs,
      createdAt: playlist.createdAt,
      updatedAt: DateTime.now(),
    );

    final index = _playlists.indexWhere((p) => p.id == playlistId);
    _playlists[index] = newPlaylist;

    // 如果是当前播放列表，更新引用
    if (_currentPlaylist?.id == playlistId) {
      _currentPlaylist = newPlaylist;
    }

    notifyListeners();
    return true;
  }

  /// 设置当前播放列表
  void setCurrentPlaylist(Playlist playlist, [int songIndex = 0]) {
    _currentPlaylist = playlist;
    _currentSongIndex = songIndex.clamp(0, playlist.songs.length - 1);
    _generateShuffleOrder();
    notifyListeners();
  }

  /// 播放指定歌曲
  void playSong(int index) {
    if (_currentPlaylist == null ||
        index < 0 ||
        index >= _currentPlaylist!.songs.length) {
      return;
    }
    _currentSongIndex = index;
    if (_isShuffleMode) {
      _shuffleIndex = _shuffleOrder.indexOf(index);
    }
    notifyListeners();
  }

  /// 播放下一首
  AudioFile? playNext() {
    if (_currentPlaylist == null || _currentPlaylist!.isEmpty) {
      return null;
    }

    if (_isShuffleMode) {
      _shuffleIndex++;
      if (_shuffleIndex >= _shuffleOrder.length) {
        if (_isRepeatMode) {
          _shuffleIndex = 0;
        } else {
          return null; // 播放完毕
        }
      }
      _currentSongIndex = _shuffleOrder[_shuffleIndex];
    } else {
      _currentSongIndex++;
      if (_currentSongIndex >= _currentPlaylist!.songs.length) {
        if (_isRepeatMode) {
          _currentSongIndex = 0;
        } else {
          return null; // 播放完毕
        }
      }
    }

    notifyListeners();
    return currentSong;
  }

  /// 播放上一首
  AudioFile? playPrevious() {
    if (_currentPlaylist == null || _currentPlaylist!.isEmpty) {
      return null;
    }

    if (_isShuffleMode) {
      _shuffleIndex--;
      if (_shuffleIndex < 0) {
        if (_isRepeatMode) {
          _shuffleIndex = _shuffleOrder.length - 1;
        } else {
          _shuffleIndex = 0;
          return currentSong; // 已经是第一首
        }
      }
      _currentSongIndex = _shuffleOrder[_shuffleIndex];
    } else {
      _currentSongIndex--;
      if (_currentSongIndex < 0) {
        if (_isRepeatMode) {
          _currentSongIndex = _currentPlaylist!.songs.length - 1;
        } else {
          _currentSongIndex = 0;
          return currentSong; // 已经是第一首
        }
      }
    }

    notifyListeners();
    return currentSong;
  }

  /// 切换随机播放模式
  void toggleShuffleMode() {
    _isShuffleMode = !_isShuffleMode;
    if (_isShuffleMode) {
      _generateShuffleOrder();
    } else {
      _clearShuffleOrder();
    }
    notifyListeners();
  }

  /// 切换重复播放模式
  void toggleRepeatMode() {
    _isRepeatMode = !_isRepeatMode;
    notifyListeners();
  }

  /// 生成随机播放顺序
  void _generateShuffleOrder() {
    if (_currentPlaylist == null) return;

    _shuffleOrder.clear();
    for (int i = 0; i < _currentPlaylist!.songs.length; i++) {
      _shuffleOrder.add(i);
    }
    _shuffleOrder.shuffle();

    // 确保当前歌曲在随机列表中的位置
    if (_currentSongIndex >= 0) {
      _shuffleIndex = _shuffleOrder.indexOf(_currentSongIndex);
    }
  }

  /// 清除随机播放顺序
  void _clearShuffleOrder() {
    _shuffleOrder.clear();
    _shuffleIndex = -1;
  }

  /// 添加歌曲到播放列表
  void addSongToPlaylist(String playlistId, AudioFile song) {
    final playlist = _playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => throw ArgumentError('Playlist not found'),
    );
    playlist.addSong(song);

    // 如果是当前播放列表，更新随机播放顺序
    if (_currentPlaylist?.id == playlistId && _isShuffleMode) {
      _generateShuffleOrder();
    }

    notifyListeners();
  }

  /// 从播放列表移除歌曲
  void removeSongFromPlaylist(String playlistId, AudioFile song) {
    final playlist = _playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => throw ArgumentError('Playlist not found'),
    );

    final removed = playlist.removeSong(song);
    if (removed && _currentPlaylist?.id == playlistId) {
      // 如果移除的是当前播放的歌曲，需要调整索引
      if (_currentSongIndex >= playlist.songs.length) {
        _currentSongIndex = playlist.songs.length - 1;
      }

      // 更新随机播放顺序
      if (_isShuffleMode) {
        _generateShuffleOrder();
      }
    }

    notifyListeners();
  }

  /// 获取指定播放列表
  Playlist? getPlaylist(String playlistId) {
    try {
      return _playlists.firstWhere((p) => p.id == playlistId);
    } catch (e) {
      return null;
    }
  }

  /// 检查是否有下一首歌曲
  bool get hasNext {
    if (_currentPlaylist == null || _currentPlaylist!.isEmpty) {
      return false;
    }

    if (_isRepeatMode) {
      return true; // 重复模式下总是有下一首
    }

    if (_isShuffleMode) {
      return _shuffleIndex < _shuffleOrder.length - 1;
    } else {
      return _currentSongIndex < _currentPlaylist!.songs.length - 1;
    }
  }

  /// 检查是否有上一首歌曲
  bool get hasPrevious {
    if (_currentPlaylist == null || _currentPlaylist!.isEmpty) {
      return false;
    }

    if (_isRepeatMode) {
      return true; // 重复模式下总是有上一首
    }

    if (_isShuffleMode) {
      return _shuffleIndex > 0;
    } else {
      return _currentSongIndex > 0;
    }
  }

  @override
  void dispose() {
    _playlists.clear();
    _currentPlaylist = null;
    _currentSongIndex = -1;
    _clearShuffleOrder();
    super.dispose();
  }
}
