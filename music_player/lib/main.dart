import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/audio_service.dart';
import 'services/file_service.dart';
import 'services/playlist_service.dart';
import 'widgets/player_controls.dart';
import 'widgets/file_picker_widget.dart';
import 'widgets/file_scanner_widget.dart';
import 'widgets/playlist_widget.dart';

void main() {
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AudioPlayerService()),
        ChangeNotifierProvider(create: (context) => FileService()),
        ChangeNotifierProvider(create: (context) => PlaylistService()),
      ],
      child: MaterialApp(
        title: '音乐播放器',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MusicPlayerHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MusicPlayerHomePage extends StatelessWidget {
  const MusicPlayerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '音乐播放器',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 应用标题和描述
                _buildHeader(),
                const SizedBox(height: 24),

                // 文件选择器
                const FilePickerWidget(),
                const SizedBox(height: 20),

                // 文件扫描组件
                const FileScannerWidget(),
                const SizedBox(height: 20),

                // 播放列表组件
                const PlaylistWidget(),
                const SizedBox(height: 20),

                // 播放器控制面板
                const Expanded(child: PlayerControls()),

                const SizedBox(height: 16),

                // 底部信息
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建头部信息
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Icon(Icons.music_note, size: 48, color: Colors.blue),
          const SizedBox(height: 8),
          const Text(
            '欢迎使用音乐播放器',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '选择您喜欢的音频文件开始播放',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 构建底部信息
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Text(
        'Version 1.1 - 第二天开发成果',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
