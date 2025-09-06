import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/playlist_service.dart';

/// 播放器控制组件
/// 包含播放/暂停/停止按钮和进度条
class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AudioPlayerService, PlaylistService>(
      builder: (context, audioService, playlistService, child) {
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // 进度条
              _buildProgressBar(audioService),
              const SizedBox(height: 16),

              // 控制按钮
              _buildControlButtons(audioService, playlistService),
              const SizedBox(height: 16),

              // 音量控制
              _buildVolumeControl(audioService, playlistService),
            ],
          ),
        );
      },
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(AudioPlayerService audioService) {
    return Column(
      children: [
        // 进度条
        SliderTheme(
          data: SliderThemeData(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 4,
            activeTrackColor: Colors.blue,
            inactiveTrackColor: Colors.grey[300],
          ),
          child: Slider(
            value:
                audioService.duration.inMilliseconds > 0
                    ? audioService.position.inMilliseconds /
                        audioService.duration.inMilliseconds
                    : 0.0,
            onChanged: (value) {
              final position = Duration(
                milliseconds:
                    (value * audioService.duration.inMilliseconds).round(),
              );
              audioService.seek(position);
            },
          ),
        ),

        // 时间显示
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(audioService.position),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                _formatDuration(audioService.duration),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons(
    AudioPlayerService audioService,
    PlaylistService playlistService,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 上一首按钮
        IconButton(
          onPressed:
              playlistService.hasPrevious
                  ? () => _playPrevious(audioService, playlistService)
                  : null,
          icon: const Icon(Icons.skip_previous),
          iconSize: 32,
          color:
              playlistService.hasPrevious ? Colors.grey[600] : Colors.grey[400],
        ),

        // 播放/暂停按钮
        Container(
          decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          child: IconButton(
            onPressed: () {
              if (audioService.isPlaying) {
                audioService.pause();
              } else if (audioService.currentFilePath != null) {
                audioService.resume();
              } else if (playlistService.currentSong != null) {
                audioService.playAudio(playlistService.currentSong!.path);
              }
            },
            icon: Icon(
              audioService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            iconSize: 40,
          ),
        ),

        // 下一首按钮
        IconButton(
          onPressed:
              playlistService.hasNext
                  ? () => _playNext(audioService, playlistService)
                  : null,
          icon: const Icon(Icons.skip_next),
          iconSize: 32,
          color: playlistService.hasNext ? Colors.grey[600] : Colors.grey[400],
        ),
      ],
    );
  }

  /// 构建音量控制
  Widget _buildVolumeControl(
    AudioPlayerService audioService,
    PlaylistService playlistService,
  ) {
    return Row(
      children: [
        const Icon(Icons.volume_down, color: Colors.grey),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.grey[300],
            ),
            child: Slider(
              value: audioService.volume,
              onChanged: (value) => audioService.setVolume(value),
              min: 0.0,
              max: 1.0,
            ),
          ),
        ),
        const Icon(Icons.volume_up, color: Colors.grey),
        const SizedBox(width: 16),
        // 播放模式控制
        _buildPlayModeControls(playlistService),
      ],
    );
  }

  /// 构建播放模式控制
  Widget _buildPlayModeControls(PlaylistService playlistService) {
    return Row(
      children: [
        // 随机播放按钮
        IconButton(
          onPressed: playlistService.toggleShuffleMode,
          icon: Icon(
            Icons.shuffle,
            color:
                playlistService.isShuffleMode ? Colors.blue : Colors.grey[600],
          ),
          tooltip: playlistService.isShuffleMode ? '关闭随机播放' : '开启随机播放',
        ),
        // 重复播放按钮
        IconButton(
          onPressed: playlistService.toggleRepeatMode,
          icon: Icon(
            Icons.repeat,
            color:
                playlistService.isRepeatMode ? Colors.blue : Colors.grey[600],
          ),
          tooltip: playlistService.isRepeatMode ? '关闭重复播放' : '开启重复播放',
        ),
      ],
    );
  }

  /// 播放上一首
  void _playPrevious(
    AudioPlayerService audioService,
    PlaylistService playlistService,
  ) {
    final previousSong = playlistService.playPrevious();
    if (previousSong != null) {
      audioService.playAudio(previousSong.path);
    }
  }

  /// 播放下一首
  void _playNext(
    AudioPlayerService audioService,
    PlaylistService playlistService,
  ) {
    final nextSong = playlistService.playNext();
    if (nextSong != null) {
      audioService.playAudio(nextSong.path);
    }
  }

  /// 格式化时间显示
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
