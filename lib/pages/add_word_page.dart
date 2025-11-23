import 'package:flutter/material.dart';
import 'languages/add_english_word_page.dart';
import 'languages/add_japanese_word_page.dart';
import 'languages/add_chinese_word_page.dart';

class AddWordPage extends StatefulWidget {
  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📝 단어 추가', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '🇺🇸 영어'),
            Tab(text: '🇯🇵 일본어'),
            Tab(text: '🇨🇳 중국어'),
          ],
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: TabBarView(
        controller: _tabController,
        children: [
          AddEnglishWordPage(),
          AddJapaneseWordPage(),
          AddChineseWordPage(),
        ],
      ),
    );
  }
}
