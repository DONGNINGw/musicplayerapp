import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist_model.dart';
import '../services/playlist_service.dart';
import '../services/audio_service.dart';

/// 播放列表组件
class PlaylistWidget extends StatefulWidget {
  const PlaylistWidget({super.key});

  @override
  State<PlaylistWidget> createState() => _PlaylistWidgetState();
}

class _PlaylistWidgetState extends State<PlaylistWidget> {
  final TextEditingController _playlistNameController = TextEditingController();

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlaylistService, AudioPlayerService>(
      builder: (context, playlistService, audioService, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(playlistService),
              const Divider(height: 1),
              _buildPlaylistList(playlistService, audioService),
            ],
          ),
        );
      },
    );
  }

  /// 构建头部
  Widget _buildHeader(PlaylistService playlistService) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.queue_music, color: Colors.blue, size: 24),
          const SizedBox(width: 8),
          const Text(
            '播放列表',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showCreatePlaylistDialog(playlistService),
            icon: const Icon(Icons.add, color: Colors.blue),
            tooltip: '创建播放列表',
          ),
        ],
      ),
    );
  }

  /// 构建播放列表列表
  Widget _buildPlaylistList(
    PlaylistService playlistService,
    AudioPlayerService audioService,
  ) {
    if (playlistService.playlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.playlist_add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无播放列表',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角的 + 按钮创建播放列表',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlistService.playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlistService.playlists[index];
        final isCurrentPlaylist =
            playlistService.currentPlaylist?.id == playlist.id;

        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCurrentPlaylist ? Colors.blue : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCurrentPlaylist ? Icons.play_arrow : Icons.queue_music,
              color: isCurrentPlaylist ? Colors.white : Colors.grey[600],
            ),
          ),
          title: Text(
            playlist.name,
            style: TextStyle(
              fontWeight:
                  isCurrentPlaylist ? FontWeight.bold : FontWeight.normal,
              color: isCurrentPlaylist ? Colors.blue : Colors.black87,
            ),
          ),
          subtitle: Text(
            '${playlist.songCount} 首歌曲 • ${playlist.formattedTotalDuration}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          trailing: PopupMenuButton<String>(
            onSelected:
                (value) =>
                    _handlePlaylistAction(value, playlist, playlistService),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'play',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow, size: 20),
                        SizedBox(width: 8),
                        Text('播放'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('重命名'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
          onTap:
              () =>
                  _showPlaylistDetail(playlist, playlistService, audioService),
        );
      },
    );
  }

  /// 显示创建播放列表对话框
  void _showCreatePlaylistDialog(PlaylistService playlistService) {
    _playlistNameController.clear();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('创建播放列表'),
            content: TextField(
              controller: _playlistNameController,
              decoration: const InputDecoration(
                labelText: '播放列表名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = _playlistNameController.text.trim();
                  if (name.isNotEmpty) {
                    playlistService.createPlaylist(name);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('播放列表 "$name" 创建成功')),
                    );
                  }
                },
                child: const Text('创建'),
              ),
            ],
          ),
    );
  }

  /// 处理播放列表操作
  void _handlePlaylistAction(
    String action,
    Playlist playlist,
    PlaylistService playlistService,
  ) {
    switch (action) {
      case 'play':
        if (playlist.isNotEmpty) {
          playlistService.setCurrentPlaylist(playlist);
          final audioService = Provider.of<AudioPlayerService>(
            context,
            listen: false,
          );
          audioService.playAudio(playlist.songs.first.path);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('开始播放 "${playlist.name}"')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('播放列表为空')));
        }
        break;
      case 'rename':
        _showRenamePlaylistDialog(playlist, playlistService);
        break;
      case 'delete':
        _showDeletePlaylistDialog(playlist, playlistService);
        break;
    }
  }

  /// 显示重命名播放列表对话框
  void _showRenamePlaylistDialog(
    Playlist playlist,
    PlaylistService playlistService,
  ) {
    _playlistNameController.text = playlist.name;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('重命名播放列表'),
            content: TextField(
              controller: _playlistNameController,
              decoration: const InputDecoration(
                labelText: '新名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newName = _playlistNameController.text.trim();
                  if (newName.isNotEmpty && newName != playlist.name) {
                    playlistService.renamePlaylist(playlist.id, newName);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('播放列表重命名为 "$newName"')),
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  /// 显示删除播放列表对话框
  void _showDeletePlaylistDialog(
    Playlist playlist,
    PlaylistService playlistService,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除播放列表'),
            content: Text('确定要删除播放列表 "${playlist.name}" 吗？此操作无法撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  playlistService.deletePlaylist(playlist.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('播放列表 "${playlist.name}" 已删除')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }

  /// 显示播放列表详情
  void _showPlaylistDetail(
    Playlist playlist,
    PlaylistService playlistService,
    AudioPlayerService audioService,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 拖拽指示器
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // 播放列表信息
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.queue_music,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    playlist.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${playlist.songCount} 首歌曲 • ${playlist.formattedTotalDuration}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (playlist.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: () {
                                  playlistService.setCurrentPlaylist(playlist);
                                  audioService.playAudio(
                                    playlist.songs.first.path,
                                  );
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('播放'),
                              ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // 歌曲列表
                      Expanded(
                        child:
                            playlist.isEmpty
                                ? const Center(
                                  child: Text(
                                    '播放列表为空',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  controller: scrollController,
                                  itemCount: playlist.songs.length,
                                  itemBuilder: (context, index) {
                                    final song = playlist.songs[index];
                                    final isCurrentSong =
                                        playlistService.currentPlaylist?.id ==
                                            playlist.id &&
                                        playlistService.currentSongIndex ==
                                            index;

                                    return ListTile(
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color:
                                              isCurrentSong
                                                  ? Colors.blue
                                                  : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Icon(
                                          isCurrentSong
                                              ? Icons.play_arrow
                                              : Icons.music_note,
                                          color:
                                              isCurrentSong
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        song.name,
                                        style: TextStyle(
                                          fontWeight:
                                              isCurrentSong
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              isCurrentSong
                                                  ? Colors.blue
                                                  : Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${song.formattedDuration} • ${song.formattedSize}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'remove') {
                                            playlistService
                                                .removeSongFromPlaylist(
                                                  playlist.id,
                                                  song,
                                                );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '已从播放列表中移除 "${song.name}"',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder:
                                            (context) => [
                                              const PopupMenuItem(
                                                value: 'remove',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.remove,
                                                      size: 20,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      '移除',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                      ),
                                      onTap: () {
                                        playlistService.setCurrentPlaylist(
                                          playlist,
                                          index,
                                        );
                                        audioService.playAudio(song.path);
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
