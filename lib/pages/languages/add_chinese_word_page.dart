import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddChineseWordPage extends StatefulWidget {
  const AddChineseWordPage({Key? key}) : super(key: key);

  @override
  State<AddChineseWordPage> createState() => _AddChineseWordPageState();
}

class _AddChineseWordPageState extends State<AddChineseWordPage> {
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
    flutterTts.setLanguage("zh-CN");
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
        final chineseNotebooks = data['chinese'] as List?;
        if (chineseNotebooks != null) {
          setState(() {
            notebooks = List<String>.from(chineseNotebooks);
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
          "https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(word)}&langpair=zh|en";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String englishMeaning = data["responseData"]["translatedText"] ?? "";
        if (englishMeaning.isNotEmpty) {
          String koreanMeaning = await _translateToKorean(englishMeaning);
          meanings.clear();
          
          // 간체/번체 판별 (간단한 로직, 더 정확하려면 API 필요)
          String simplified = word;
          String traditional = word;
          
          // 한자 범위 체크로 간체/번체 구분 시도
          // 번체는 간체보다 획이 많은 특성이 있음 (실제 구분은 복잡함)
          try {
            // 간체와 번체의 몇 가지 차이 예시
            Map<String, String> conversionMap = {
              '爱': '愛', '国': '國', '学': '學', '认': '認', '为': '為', 
              '们': '們', '个': '個', '对': '對', '来': '來', '要': '要',
              '只': '隻', '可': '可', '主': '主', '样': '樣'
            };
            if (conversionMap.containsKey(word)) {
              simplified = word;
              traditional = conversionMap[word]!;
            }
          } catch (e) {
            // 변환 실패시 동일하게 처리
          }
          
          meanings.add({
            "simplified": simplified,
            "traditional": traditional,
            "pinyin": "[발음]",
            "english": englishMeaning,
            "korean": koreanMeaning
          });
          meaningController.text = koreanMeaning;
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
              labelText: '중국어 (간체/번체/성조)',
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
                    if (m['simplified']!.isNotEmpty)
                      Wrap(spacing: 8, children: [
                        GestureDetector(
                            onTap: () => flutterTts.speak(m['simplified']!),
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
                                      Text(m['simplified']!,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(width: 4),
                                      Icon(Icons.volume_up,
                                          size: 16, color: Colors.red)
                                    ]))),
                        if (m['traditional']!.isNotEmpty &&
                            m['traditional'] != m['simplified'])
                          Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.orange.shade200)),
                              child: Text(m['traditional']!,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600))),
                        Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.yellow.shade50,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(m['pinyin']!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber.shade800))),
                      ]),
                    if (m['simplified']!.isNotEmpty) SizedBox(height: 8),
                    if (m['english']!.isNotEmpty)
                      Text('영어: ${m['english']}',
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
                "language": "chinese",
                "notebook": selectedNotebook ?? '기본 단어장',
                "simplified": meanings.isNotEmpty ? meanings.first['simplified'] : wordController.text.trim(),
                "traditional": meanings.isNotEmpty ? meanings.first['traditional'] : wordController.text.trim(),
                "pinyin": meanings.isNotEmpty ? meanings.first['pinyin'] : '[발음]'
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
