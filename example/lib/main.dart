import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:video_player/video_player.dart';
import 'package:text_to_path_maker/text_to_path_maker.dart';
import 'dart:math' as math;

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: DemoPage(),
      ),
    );
  }
}

/// A widget that displays [text] clipped from a [videoAsset] file.
/// The [width] and [height] constants control the overall ClipPath size.
/// This is a minimal example to demonstrate the concept; customize as needed.
class VideoText extends StatefulWidget {
  final String text;
  final double width;
  final double height;
  final String videoAsset;

  const VideoText({
    Key? key,
    required this.text,
    required this.width,
    required this.height,
    required this.videoAsset,
  }) : super(key: key);

  @override
  State<VideoText> createState() => _VideoTextState();
}

class _VideoTextState extends State<VideoText> {
  Path? _combinedPath;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _initFontAndBuildPath();
  }

  /// Initialize the video controller.
  void _initVideo() {
    _videoController = VideoPlayerController.asset(widget.videoAsset)
      ..initialize().then((_) {
        setState(() {});
        _videoController?.setVolume(0);
        _videoController?.play();
        _videoController?.setLooping(true);
      }).catchError((error) {
        debugPrint("Error initializing video: $error");
      });
  }

  /// Load the TTF font from assets, parse it, then build a combined path
  /// for each character in [widget.text], positioning them side by side.
  void _initFontAndBuildPath() {
    rootBundle.load("assets/font2.ttf").then((ByteData data) {
      final reader = PMFontReader();
      final font = reader.parseTTFAsset(data);

      // The combined path for the entire string
      final combinedPath = Path();

      // Gather each character's path, offset them in a naive manner
      double xOffset = 0.0;
      const double spacing = 15.0; // Extra space between letters

      for (int i = 0; i < widget.text.length; i++) {
        final codeUnit = widget.text.codeUnitAt(i);
        final letterPath = font.generatePathForCharacter(codeUnit);

        // Get approximate bounding box to shift letters
        final bounds = letterPath.getBounds();
        final letterWidth = bounds.width;

        // Scale each glyph so it fits roughly in widget.height
        // (Very simplistic approach)
        final desiredHeight = widget.height;
        final double scale = (desiredHeight / bounds.height);

        // Move path so that it doesn't overlap the previous one
        // and is baseline-aligned. Add it to the combined path.
        // We invert Y scale so that it doesn't show upside-down.
        final transformed = PMTransform.moveAndScale(
          letterPath,
          xOffset - bounds.left, // Shift away negative left
          -bounds.top + 400, // Shift baseline to y=0
          scale, // scaleX
          scale, // scaleY but note: negative if you prefer
        );

        combinedPath.addPath(transformed, Offset.zero);

        // Advance offset horizontally for the next character
        xOffset += (letterWidth * scale) + spacing;
      }

      setState(() {
        _combinedPath = combinedPath;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_combinedPath == null || _videoController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // SizedBox(
        //   width: widget.width,
        //   height: widget.height,
        //   child: VideoPlayer(_videoController!),
        // ),
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: ClipPath(
            clipper: _VideoTextClipper(_combinedPath!),
            child: VideoPlayer(_videoController!),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}

class _VideoTextClipper extends CustomClipper<Path> {
  final Path path;
  _VideoTextClipper(this.path);

  @override
  Path getClip(Size size) {
    final boundingBox = path.getBounds();

    // Compute scale factors so that the entire path fits inside.
    final double xScale = size.width / boundingBox.width;
    final double yScale = size.height / boundingBox.height;

    // Use the smaller of the two scale factors so we contain it without overflow.
    final double scale = math.min(xScale, yScale);

    // Compute offsets so that the path is centered within the SizedBox.
    final double offsetX = (size.width - boundingBox.width * scale) / 2;
    final double offsetY = (size.height - boundingBox.height * scale) / 2;

    // Apply translate(-boundingBox.left, -boundingBox.top) so the top-left of
    // our path is at (0,0) in "path coordinates," then apply the scale and the
    // final offset to center it in the box.
    final Matrix4 transform = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(scale, scale)
      ..translate(-boundingBox.left, -boundingBox.top);

    return path.transform(transform.storage);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class DemoPage extends StatelessWidget {
  const DemoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VideoText Demo')),
      body: const Center(
        child: VideoText(
          text: "Hello good world",
          width: 400,
          height: 400,
          videoAsset: 'assets/video.mp4',
        ),
      ),
    );
  }
}
