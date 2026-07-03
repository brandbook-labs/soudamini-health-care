import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class JivanConfetti extends StatefulWidget {
  final bool autoPlay;
  final Duration duration;

  const JivanConfetti({
    super.key,
    this.autoPlay = true,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<JivanConfetti> createState() => _JivanConfettiState();
}

class _JivanConfettiState extends State<JivanConfetti> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: widget.duration);
    
    // ଯଦି autoPlay true ଅଛି, ତେବେ ସ୍କ୍ରିନ୍ ଲୋଡ୍ ହେବାର ଅଧ ସେକେଣ୍ଡ୍ ପରେ ଆନିମେସନ୍ ଆରମ୍ଭ ହେବ
    if (widget.autoPlay) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _controller.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // ମେମୋରୀ ଲିକ୍ ରୋକିବା ପାଇଁ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ଇଗନୋର୍ କରନ୍ତୁ ଯଦି କୌଣସି ୟୁଜର୍ କ୍ଲିକ୍ କରନ୍ତି, ଏହା କେବଳ ଭିଜୁଆଲ୍ ଅଟେ
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive, // ଚାରିଆଡ଼କୁ ଖେଳେଇ ହେବ
          shouldLoop: false,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple
          ],
        ),
      ),
    );
  }
}