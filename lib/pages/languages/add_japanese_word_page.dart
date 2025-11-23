import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddJapaneseWordPage extends StatefulWidget {
  const AddJapaneseWordPage({Key? key}) : super(key: key);

  @override
  State<AddJapaneseWordPage> createState() => _AddJapaneseWordPageState();
}

class _AddJapaneseWordPageState extends State<AddJapaneseWordPage> {
  final wordController = TextEditingController();
  final meaningController = TextEditingController();

  bool isLoading = false;
  List<Map<String, String>> meanings = [];
  String? selectedNotebook;
  List<String> notebooks = ['기본 단어장'];

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    flutterTts.setLanguage("ja-JP");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    _loadNotebooks();
  }

  Future<void> _loadNotebooks() async {
    final prefs = await SharedPreferences.getInstance();
    final notebooksJson = prefs.getString('notebooks_by_language');
    if (notebooksJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(notebooksJson);
        final japaneseNotebooks = data['japanese'] as List?;
        if (japaneseNotebooks != null) {
          setState(() {
            notebooks = List<String>.from(japaneseNotebooks);
            selectedNotebook = notebooks.first;
          });
        }
      } catch (e) {
        setState(() => selectedNotebook = '기본 단어장');
      }
    } else {
      setState(() => selectedNotebook = '기본 단어장');
    }
  }

  Future<void> fetchWord() async {
    String word = wordController.text.trim();
    if (word.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final url =
          "https://jisho.org/api/v1/search/words?keyword=${Uri.encodeComponent(word)}";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["data"] != null && data["data"].isNotEmpty) {
          meanings.clear();
          for (var entry in data["data"]) {
            if (entry["senses"] != null) {
              for (var sense in entry["senses"]) {
                if (sense["english_definitions"] != null) {
                  for (var definition in sense["english_definitions"]) {
                    String kanji = "";
                    String hiragana = "";
                    if (entry["japanese"] != null &&
                        entry["japanese"].isNotEmpty) {
                      kanji = entry["japanese"][0]["word"]?.toString() ?? "";
                      hiragana =
                          entry["japanese"][0]["reading"]?.toString() ?? "";
                    }
                    String koreanMeaning =
                        await _translateToKorean(definition.toString());
                    meanings.add({
                      "kanji": kanji,
                      "hiragana": hiragana,
                      "meaning": definition.toString(),
                      "korean": koreanMeaning
                    });
                    if (meanings.length >= 10) break;
                  }
                }
                if (meanings.length >= 10) break;
              }
            }
            if (meanings.length >= 10) break;
          }
          if (meanings.isNotEmpty) {
            meaningController.text = meanings.first["korean"] ?? "";
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e')));
      }
    }
    setState(() => isLoading = false);
  }

  Future<String> _translateToKorean(String text) async {
    try {
      final url =
          "https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=en|ko";
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body)["responseData"]["translatedText"] ?? text;
      }
    } catch (e) {}
    return text;
  }

  @override
  void dispose() {
    flutterTts.stop();
    wordController.dispose();
    meaningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 16),
          _buildSearchField(),
          SizedBox(height: 20),
          if (meanings.isNotEmpty) ...[
            Text('🎯 검색 결과',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            _buildMeaningsSection(),
            SizedBox(height: 20),
          ],
          _buildMeaningField(),
          SizedBox(height: 20),
          _buildNotebookSelector(),
          SizedBox(height: 24),
          _buildSaveButton(),
          SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _buildSearchField() => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)
            ]),
        child: TextField(
            controller: wordController,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: '일본어 (한자/히라가나/영어)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: EdgeInsets.all(16),
              suffixIcon: isLoading
                  ? Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      icon: Icon(Icons.search, color: Colors.red),
                      onPressed: fetchWord),
            ),
            onSubmitted: (_) => fetchWord()),
      );

  Widget _buildMeaningsSection() => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)
            ]),
        child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: meanings.take(5).length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, idx) {
              var m = meanings[idx];
              return Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    if (m['kanji']!.isNotEmpty ||
                        m['hiragana']!.isNotEmpty)
                      Wrap(spacing: 8, children: [
                        if (m['kanji']!.isNotEmpty)
                          GestureDetector(
                              onTap: () => flutterTts.speak(m['kanji']!),
                              child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.red.shade200)),
                                  child: Row(mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(m['kanji']!,
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        SizedBox(width: 4),
                                        Icon(Icons.volume_up,
                                            size: 16, color: Colors.red)
                                      ]))),
                        if (m['hiragana']!.isNotEmpty)
                          Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.pink.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.pink.shade200)),
                              child: Text(m['hiragana']!,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600))),
                      ]),
                    if ((m['kanji']!.isNotEmpty ||
                        m['hiragana']!.isNotEmpty))
                      SizedBox(height: 8),
                    if (m['meaning']!.isNotEmpty)
                      Text('영어: ${m['meaning']}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[700])),
                    if (m['korean']!.isNotEmpty)
                      Text('한국어: ${m['korean']}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600)),
                  ]));
            }),
      );

  Widget _buildMeaningField() => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)
            ]),
        child: TextField(
            controller: meaningController,
            maxLines: 4,
            decoration: InputDecoration(
                labelText: '한국어 뜻',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: EdgeInsets.all(16))),
      );

  Widget _buildNotebookSelector() => Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📚 단어장 선택',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8)),
            child: DropdownButton<String>(
                value: selectedNotebook,
                isExpanded: true,
                underline: SizedBox(),
                items: notebooks
                    .map((String v) =>
                        DropdownMenuItem<String>(value: v, child: Text(v)))
                    .toList(),
                onChanged: (String? n) {
                  if (n != null) setState(() => selectedNotebook = n);
                }),
          ),
        ]),
      );

  Widget _buildSaveButton() => Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.red.shade700,
              Colors.red.shade500
            ]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4))
            ]),
        child: ElevatedButton(
            onPressed: () {
              if (wordController.text.trim().isEmpty ||
                  meaningController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('단어와 뜻을 입력해주세요')));
                return;
              }
              Navigator.pop(context, {
                "word": wordController.text.trim(),
                "meaning": meaningController.text.trim(),
                "language": "japanese",
                "notebook": selectedNotebook ?? '기본 단어장',
                "kanji": meanings.isNotEmpty ? meanings.first['kanji'] : '',
                "hiragana": meanings.isNotEmpty ? meanings.first['hiragana'] : ''
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('저장',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white))
            ])),
      );
}
