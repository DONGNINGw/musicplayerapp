import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';

/// 文件选择器组件
/// 用于选择音频文件并开始播放
class FilePickerWidget extends StatelessWidget {
  const FilePickerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 当前播放文件信息
              if (audioService.currentFilePath != null)
                _buildCurrentFileInfo(audioService),
              
              const SizedBox(height: 16),
              
              // 选择文件按钮
              _buildFilePickerButton(context, audioService),
              
              const SizedBox(height: 16),
              
              // 支持的格式说明
              _buildSupportedFormats(),
            ],
          ),
        );
      },
    );
  }

  /// 构建当前文件信息显示
  Widget _buildCurrentFileInfo(AudioPlayerService audioService) {
    final fileName = audioService.currentFilePath?.split('\\').last ?? 
                    audioService.currentFilePath?.split('/').last ?? 
                    '未知文件';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '当前播放:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fileName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '状态: ${audioService.isPlaying ? "播放中" : audioService.isPaused ? "已暂停" : "已停止"}',
            style: TextStyle(
              fontSize: 12,
              color: audioService.isPlaying ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文件选择按钮
  Widget _buildFilePickerButton(BuildContext context, AudioPlayerService audioService) {
    return ElevatedButton.icon(
      onPressed: () => _pickAndPlayFile(context, audioService),
      icon: const Icon(Icons.folder_open),
      label: const Text('选择音频文件'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 构建支持格式说明
  Widget _buildSupportedFormats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '支持的音频格式:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'MP3, WAV, FLAC, AAC, OGG, M4A',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 选择并播放文件
  Future<void> _pickAndPlayFile(BuildContext context, AudioPlayerService audioService) async {
    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      // 关闭加载指示器
      Navigator.of(context).pop();

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        
        // 播放选中的文件
        await audioService.playAudio(filePath);
        
        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('开始播放: ${result.files.single.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 关闭可能存在的加载指示器
      Navigator.of(context).pop();
      
      // 显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('播放失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}