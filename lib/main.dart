import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/word_list_page.dart';
import 'pages/add_word_page.dart';
import 'pages/edit_word_page.dart';

void main() {
  runApp(GraceVoca());
}

class GraceVoca extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GraceVoca',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: "Pretendard",
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => HomePage(),
        '/wordList': (_) => WordListPage(),
        '/addWord': (_) => AddWordPage(),
        '/editWord': (_) => EditWordPage(),
      },
    );
  }
}
