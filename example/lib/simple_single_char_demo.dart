import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:text_to_path_maker/text_to_path_maker.dart';
import 'dart:typed_data';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const Home());
}

class PathClipper extends CustomClipper<Path> {
  final Path path;

  PathClipper(this.path);

  @override
  Path getClip(Size size) {
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _Home();
  }
}

class _Home extends State<Home> with SingleTickerProviderStateMixin {
  Path? path;
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller?.setVolume(0);
        _controller?.play();
        _controller?.setLooping(true);
      }).catchError((error) {
        print("Error initializing video: $error");
      });

    rootBundle.load("assets/font2.ttf").then((ByteData data) {
      var reader = PMFontReader();
      final font = reader.parseTTFAsset(data);
      final tempPath = font.generatePathForCharacter(101); // e

      // Move it and scale it. These values were produced by trial and error
      // TODO: we need a way to put multiple characters into the path and determine
      // correct scale and position values
      setState(() {
        path = PMTransform.moveAndScale(tempPath, 25.0, 175.0, 0.15, 0.15);
      });
    });
  }

  buildOriginalVideo() {
    if (_controller == null) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        const Text("Original Video"),
        SizedBox(
          width: 200,
          height: 200,
          child: VideoPlayer(_controller!),
        ),
      ],
    );
  }

  buildCircleClippedVideo() {
    if (_controller == null) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        const Text("Circle Clipped Video"),
        ClipOval(
          child: SizedBox(
            width: 200,
            height: 200,
            child: VideoPlayer(_controller!),
          ),
        ),
      ],
    );
  }

  buildCharacterClippedVideo() {
    if (path == null || _controller == null) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        const Text("Character Clipped Video"),
        ClipPath(
          clipper: PathClipper(path!),
          child: Container(
            width: 200,
            height: 200,
            color: Colors.red,
            child: VideoPlayer(_controller!),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildOriginalVideo(),
              buildCircleClippedVideo(),
              buildCharacterClippedVideo(),
            ],
          ),
        ),
      ),
    );
  }
}
