import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'themeNotifier.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'user_bubble.dart';
import 'gemini_bubble.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';


class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    requestMicPermission();
  }
  Future<void> requestMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }


  callGeminiModel() async {
    try {
      if (_controller.text.isNotEmpty) {
        setState(() {
          _messages.add(Message(text: _controller.text, isUser: true));
          _isLoading = true;
          _messages.add(Message(text: "Wait....asking gemini", isUser: true));

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        });
      }

      final model = GenerativeModel(
          model: 'gemini-2.0-flash', apiKey: dotenv.env['GOOGLE_API_KEY']!);
      final prompt = _controller.text.trim();
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      setState(() {
        _messages.removeLast();
        _messages.add(Message(text: response.text!, isUser: false));
        _isLoading = false;
      });
      // 👇 Scroll after the UI updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });


      _controller.clear();
    } catch (e) {
      String errorMessage;

      if (e is SocketException) {
        errorMessage = "No Internet connection. Please check your network.";
      } else if (e.toString().contains("403")) {
        errorMessage = "Access denied. Please check your API key.";
      } else if (e.toString().contains("429")) {
        errorMessage = "Rate limit exceeded. Please try again after some time.";
      } else {
        errorMessage = "Oops! Something went wrong. Please try again.";
      }

      if (kDebugMode) {
        print("Gemini Error: $e"); // Only shows in debug mode
      }

      setState(() {
        _messages.removeLast(); // remove loading message
        _messages.add(Message(
          text: errorMessage,
          isUser: false,
        ));
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gemini Chat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            GestureDetector(
              child: Icon(
                currentTheme == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: currentTheme == ThemeMode.dark
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.primary,
              ),
              onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return message.isUser
                    ? UserBubble(text: message.text)
                    : GeminiBubble(text: message.text);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: Theme.of(context).textTheme.titleSmall,
                      decoration: InputDecoration(
                        hintText: 'Write or Speak ..',
                        hintStyle: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                  _isLoading
                      ? Padding(
                          padding: EdgeInsets.all(8.w),
                          child: SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.all(16.w),
                          child: GestureDetector(
                            child: Image.asset('assets/send.png', width: 24.w),
                            onTap: callGeminiModel,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

