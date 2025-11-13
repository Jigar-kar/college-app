import 'package:bca_c/screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  OnBoardingPageState createState() => OnBoardingPageState();
}

class OnBoardingPageState extends State<OnBoardingPage> {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    return Image.asset(
      'assets/$assetName',
      width: width,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, size: 50, color: Colors.red);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(
      fontSize: 18.0,
      color: Color.fromARGB(255, 0, 0, 0),
      fontFamily: 'Roboto',
    );

    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 30.0,
        fontWeight: FontWeight.w700,
        color: Color.fromARGB(255, 0, 0, 0),
      ),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Color.fromARGB(255, 255, 255, 255),
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
      allowImplicitScrolling: true,
      autoScrollDuration: 3000,
      infiniteAutoScroll: true,
      globalHeader: const Align(
        alignment: Alignment.topRight,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 16, right: 16),
          ),
        ),
      ),
      pages: [
        PageViewModel(
          title: "Welcome to Our College",
          body:
              "Join an institution that helps you grow academically and personally. Embrace learning at every stage.",
          decoration: pageDecoration,
          image: _buildImage('logo3.png'),
        ),
        PageViewModel(
          title: "Engage in Modern Learning",
          body:
              "We offer state-of-the-art resources and tools to enhance your learning experience. Get ahead with interactive lessons.",
          decoration: pageDecoration,
          image: _buildImage('college class-bro.png'),
        ),
        PageViewModel(
          title: "Join Our Community",
          body:
              "Our college is not just about academics; it's about creating a vibrant community where students connect, collaborate, and succeed.",
          decoration: pageDecoration,
          image: _buildImage('college project-cuate.png'),
        ),
        PageViewModel(
          title: "Experience Campus Life",
          body:
              "From sports to cultural activities, campus life at our college is designed to be as enriching as your academic journey.",
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            fullScreen: true,
            bodyFlex: 2,
            imageFlex: 2,
            safeArea: 100,
          ),
          reverse: false,
          image: _buildImage('toppers.png'),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      back: const Icon(Icons.arrow_back, color: Colors.white),
      skip: const Text('Skip',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      next: const Icon(Icons.arrow_forward, color: Colors.white),
      done: const Text('Done',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: kIsWeb
          ? const EdgeInsets.all(18.0) // Larger padding for web
          : const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(12.0, 12.0), // Larger dot size for web
        color: Color(0xFFBDBDBD),
        activeSize: Size(24.0, 12.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: const ShapeDecoration(
        color: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
}
