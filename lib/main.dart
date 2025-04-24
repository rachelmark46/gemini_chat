import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'themeNotifier.dart';
import 'themes.dart';
import 'myHomePage.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  runApp(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => ProviderScope(child: MyApp())));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'gemini by rachel',
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: themeMode,
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
