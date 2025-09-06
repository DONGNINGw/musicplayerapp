import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/file_service.dart';
import '../services/audio_service.dart';
import '../services/playlist_service.dart';
import '../models/playlist_model.dart';

/// 文件扫描组件
/// 用于扫描本地音频文件并显示结果
class FileScannerWidget extends StatelessWidget {
  const FileScannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<FileService, AudioPlayerService, PlaylistService>(
      builder: (context, fileService, audioService, playlistService, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              _buildHeader(),
              const SizedBox(height: 16),

              // 扫描按钮
              _buildScanButton(context, fileService),
              const SizedBox(height: 16),

              // 扫描状态和结果
              _buildScanStatus(fileService),
              const SizedBox(height: 16),

              // 文件列表
              if (fileService.audioFiles.isNotEmpty)
                _buildFileList(
                  context,
                  fileService,
                  audioService,
                  playlistService,
                ),
            ],
          ),
        );
      },
    );
  }

  /// 构建标题
  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.folder_special, color: Colors.blue),
        SizedBox(width: 8),
        Text(
          '本地音频文件扫描',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// 构建扫描按钮
  Widget _buildScanButton(BuildContext context, FileService fileService) {
    return ElevatedButton.icon(
      onPressed:
          fileService.isScanning
              ? null
              : () => _startScan(context, fileService),
      icon:
          fileService.isScanning
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.search),
      label: Text(fileService.isScanning ? '扫描中...' : '扫描音乐文件'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// 构建扫描状态
  Widget _buildScanStatus(FileService fileService) {
    if (fileService.isScanning) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('正在扫描音频文件，请稍候...'),
        ),
      );
    }

    if (fileService.scanError != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Text(
          '扫描错误: ${fileService.scanError}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (fileService.audioFiles.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '找到 ${fileService.audioFiles.length} 个音频文件',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (fileService.lastScanTime != null)
              Text(
                '上次扫描: ${_formatDateTime(fileService.lastScanTime!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      );
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('点击上方按钮扫描本地音频文件'),
      ),
    );
  }

  /// 构建文件列表
  Widget _buildFileList(
    BuildContext context,
    FileService fileService,
    AudioPlayerService audioService,
    PlaylistService playlistService,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListView.builder(
          itemCount: fileService.audioFiles.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final file = fileService.audioFiles[index];
            return _buildFileItem(context, file);
          },
        ),
      ),
    );
  }

  /// 构建文件项
  Widget _buildFileItem(BuildContext context, File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;

    return ListTile(
      leading: const Icon(Icons.music_note, color: Colors.blue),
      title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        file.path,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final playlistService = Provider.of<PlaylistService>(
                context,
                listen: false,
              );
              _handleFileAction(context, value, file, playlistService);
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'add_to_playlist',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add, size: 20),
                        SizedBox(width: 8),
                        Text('添加到播放列表'),
                      ],
                    ),
                  ),
                ],
            child: const Icon(Icons.more_vert, color: Colors.grey),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline, color: Colors.blue),
            onPressed: () => _playFile(context, file),
          ),
        ],
      ),
      onTap: () => _playFile(context, file),
    );
  }

  /// 开始扫描
  Future<void> _startScan(BuildContext context, FileService fileService) async {
    try {
      await fileService.scanMusicDirectory();
      if (fileService.audioFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('未找到音频文件'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('扫描失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// 播放文件
  void _playFile(BuildContext context, File file) {
    final audioService = Provider.of<AudioPlayerService>(
      context,
      listen: false,
    );
    audioService.playAudio(file.path);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始播放: ${file.path.split(Platform.pathSeparator).last}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 处理文件操作
  void _handleFileAction(
    BuildContext context,
    String action,
    File file,
    PlaylistService playlistService,
  ) {
    if (action == 'add_to_playlist') {
      _showAddToPlaylistDialog(context, file, playlistService);
    }
  }

  /// 显示添加到播放列表对话框
  void _showAddToPlaylistDialog(
    BuildContext context,
    File file,
    PlaylistService playlistService,
  ) {
    final audioFile = AudioFile.fromFile(file);

    if (playlistService.playlists.isEmpty) {
      // 如果没有播放列表，提示创建
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('添加到播放列表'),
              content: const Text('暂无播放列表，请先创建一个播放列表。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('确定'),
                ),
              ],
            ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('添加到播放列表'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('将 "${audioFile.name}" 添加到：'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.maxFinite,
                  height: 200,
                  child: ListView.builder(
                    itemCount: playlistService.playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlistService.playlists[index];
                      return ListTile(
                        leading: const Icon(Icons.queue_music),
                        title: Text(playlist.name),
                        subtitle: Text('${playlist.songCount} 首歌曲'),
                        onTap: () {
                          playlistService.addSongToPlaylist(
                            playlist.id,
                            audioFile,
                          );
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已添加到播放列表 "${playlist.name}"'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ],
          ),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  /// 两位数格式化
  String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }
}
