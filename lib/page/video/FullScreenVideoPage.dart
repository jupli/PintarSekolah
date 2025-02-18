import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FullScreenVideoPage extends StatelessWidget {
  final String videoUrl;

  const FullScreenVideoPage({Key? key, required this.videoUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final videoId = YoutubePlayer.convertUrlToId(videoUrl) ?? '';

    if (videoId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Video Player'),
          backgroundColor: Colors.black,
        ),
        body: const Center(child: Text('Invalid video URL')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logop.png', // Ganti dengan logo yang sesuai
          fit: BoxFit.contain,
          height: 40,
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
          ),
        ],
      ),
      body: YoutubePlayer(
        controller: YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            hideControls: false,
            showLiveFullscreenButton: true,
          ),
        ),
        showVideoProgressIndicator: true,
      ),
    );
  }
}
