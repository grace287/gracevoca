import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AddWordPage extends StatefulWidget {
  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  final wordController = TextEditingController();
  final meaningKo = TextEditingController();

  bool isLoading = false;

  // Data
  List<String> audioSources = [];
  String phonetic = "";
  List<String> posList = [];
  List<String> examples = [];

  List<String> nounForms = [];
  List<String> verbForms = [];
  List<String> adjForms = [];
  List<String> advForms = [];

  List<String> recommendedWords = [];

  final player = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();

  // ----------------------------
  // 1. FREE Dictionary API
  // ----------------------------
  Future<void> fetchWordDetails(String word) async {
    setState(() => isLoading = true);

    _resetData();

    try {
      final url = "https://api.dictionaryapi.dev/api/v2/entries/en/$word";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) throw Exception("Not found");

      final data = jsonDecode(response.body)[0];

      // 발음 기호
      phonetic = data["phonetic"] ?? "";

      // 발음 오디오
      for (var p in data["phonetics"]) {
        if (p["audio"] != null && p["audio"].toString().isNotEmpty) {
          audioSources.add(p["audio"]);
        }
      }

      // 뜻 + 품사 + 예문
      List<String> engDefinitions = [];

      for (var meaning in data["meanings"]) {
        posList.add(meaning["partOfSpeech"]);

        for (var def in meaning["definitions"]) {
          if (def["definition"] != null) engDefinitions.add(def["definition"]);
          if (def["example"] != null) examples.add(def["example"]);
        }
      }

      // 한국어 번역
      if (engDefinitions.isNotEmpty) {
        meaningKo.text = await translateToKorean(engDefinitions.take(2).join(". "));
      }

      // 형태 변화
      await fetchWordForms(word);

      // 추천 단어
      await fetchRecommendedWords(word);
    } catch (e) {
      meaningKo.text = "뜻을 가져올 수 없습니다.";
    }

    setState(() => isLoading = false);
  }

  // ----------------------------
  // 2. 무료 한국어 번역 API (MyMemory)
  // ----------------------------
  Future<String> translateToKorean(String text) async {
    try {
      final encodedText = Uri.encodeComponent(text);
      final url = "https://api.mymemory.translated.net/get?q=$encodedText&langpair=en|ko";
      final resp = await http.get(Uri.parse(url));

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        return json["responseData"]["translatedText"] ?? "번역 실패";
      }
      return "번역 실패";
    } catch (_) {
      return "번역 실패";
    }
  }

  // ----------------------------
  // 3. Datamuse 형태 변화
  // ----------------------------
  Future<void> fetchWordForms(String word) async {
    final resp = await http.get(Uri.parse("https://api.datamuse.com/words?rel_jjb=$word&max=10"));
    final dataAdj = jsonDecode(resp.body);

    adjForms = dataAdj.map<String>((e) => e["word"].toString()).toList();

    final respNoun = await http.get(Uri.parse("https://api.datamuse.com/words?rel_jja=$word&max=10"));
    nounForms = List<String>.from(jsonDecode(respNoun.body).map((e) => e["word"]));

    final respVerb = await http.get(Uri.parse("https://api.datamuse.com/words?rel_trg=$word&max=10"));
    verbForms = List<String>.from(jsonDecode(respVerb.body).map((e) => e["word"]));

    final respAdv =
        await http.get(Uri.parse("https://api.datamuse.com/words?rel_adv=$word&max=10"));
    advForms = List<String>.from(jsonDecode(respAdv.body).map((e) => e["word"]));
  }

  // ----------------------------
  // 4. 추천 단어
  // ----------------------------
  Future<void> fetchRecommendedWords(String word) async {
    final resp =
        await http.get(Uri.parse("https://api.datamuse.com/words?ml=$word&max=7"));
    final data = jsonDecode(resp.body);
    recommendedWords = data.map<String>((e) => e["word"].toString()).toList();
  }

  // ----------------------------
  // 발음 재생 (오디오 파일)
  // ----------------------------
  Future<void> playAudio(String url) async {
    try {
      await player.setUrl(url);
      await player.play();
    } catch (e) {
      print("Audio Error: $e");
    }
  }

  // ----------------------------
  // TTS 발음 재생
  // ----------------------------
  Future<void> speakWord(String word) async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.speak(word);
    } catch (e) {
      print("TTS Error: $e");
    }
  }

  // ----------------------------
  // 리셋
  // ----------------------------
  void _resetData() {
    audioSources.clear();
    phonetic = "";
    posList.clear();
    examples.clear();
    nounForms.clear();
    verbForms.clear();
    adjForms.clear();
    advForms.clear();
    recommendedWords.clear();
  }

  @override
  void dispose() {
    player.dispose();
    flutterTts.stop();
    super.dispose();
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F0FF),
      appBar: AppBar(
        title: Text("단어 추가", style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _searchInput(),
          SizedBox(height: 20),
          if (audioSources.isNotEmpty || wordController.text.isNotEmpty) _audioSection(),
          if (phonetic.isNotEmpty) _phoneticSection(),
          _meaningSection(),
          if (posList.isNotEmpty) _posSection(),
          if (examples.isNotEmpty) _exampleSection(),
          _formsSection(),
          if (recommendedWords.isNotEmpty) _recommendedSection(),
          SizedBox(height: 30),
          _saveButton(context),
          SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _searchInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: wordController,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: "영어 단어 입력",
          labelStyle: TextStyle(color: Colors.deepPurple.shade300),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
          suffixIcon: isLoading
              ? Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    color: Colors.deepPurple,
                    strokeWidth: 2,
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.auto_awesome, color: Colors.deepPurple),
                  onPressed: () {
                    if (wordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("단어를 입력해주세요")),
                      );
                      return;
                    }
                    fetchWordDetails(wordController.text.trim());
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            fetchWordDetails(value.trim());
          }
        },
      ),
    );
  }

  Widget _audioSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Row(
        children: [
          Icon(Icons.volume_up, color: Colors.deepPurple, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("발음 듣기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text("오디오 또는 TTS로 발음을 확인하세요", style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          SizedBox(width: 8),
          if (audioSources.isNotEmpty)
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade100,
              ),
              icon: Icon(Icons.audiotrack, color: Colors.deepPurple),
              onPressed: () => playAudio(audioSources.first),
            ),
          SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.green.shade100,
            ),
            icon: Icon(Icons.record_voice_over, color: Colors.green.shade700),
            onPressed: () => speakWord(wordController.text.trim()),
          ),
        ],
      ),
    );
  }

  Widget _phoneticSection() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Text("🔤", style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Text("[ $phonetic ]", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _meaningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.translate, color: Colors.deepPurple, size: 20),
            ),
            SizedBox(width: 10),
            Text("한국어 뜻", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(18),
          decoration: _cardStyle(),
          child: Text(
            meaningKo.text.isEmpty ? "자동으로 불러옵니다." : meaningKo.text,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
        )
      ],
    );
  }

  Widget _posSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Row(
          children: [
            Text("📚", style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text("품사", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: posList.map((p) => Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(p, style: TextStyle(fontWeight: FontWeight.w500)),
          )).toList(),
        )
      ],
    );
  }

  Widget _exampleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Row(
          children: [
            Text("✏️", style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text("예문", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 10),
        Column(
          children: examples.take(3).map((e) {
            return Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade100),
                boxShadow: [
                  BoxShadow(blurRadius: 4, color: Colors.black.withOpacity(0.05), offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote, color: Colors.deepPurple.shade300, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(e, style: TextStyle(fontSize: 15, height: 1.5)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _formsSection() {
    if (nounForms.isEmpty && verbForms.isEmpty && adjForms.isEmpty && advForms.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Row(
          children: [
            Text("🔗", style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text("형태 변화", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),

        if (nounForms.isNotEmpty) _formItem("명사형", nounForms, Colors.blue),
        if (verbForms.isNotEmpty) _formItem("동사형", verbForms, Colors.green),
        if (adjForms.isNotEmpty) _formItem("형용사형", adjForms, Colors.orange),
        if (advForms.isNotEmpty) _formItem("부사형", advForms, Colors.purple),
      ],
    );
  }

  Widget _formItem(String title, List<String> list, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 14),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list.map((w) => Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(w, style: TextStyle(fontSize: 14)),
          )).toList(),
        )
      ],
    );
  }

  Widget _recommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 25),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("✨", style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text("추천 단어", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recommendedWords.map((w) => InkWell(
                  onTap: () {
                    wordController.text = w;
                    fetchWordDetails(w);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(blurRadius: 4, color: Colors.black.withOpacity(0.1), offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(w, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        SizedBox(width: 4),
                        Icon(Icons.touch_app, size: 14, color: Colors.deepPurple),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _saveButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.shade700],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (wordController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("단어를 입력해주세요")),
            );
            return;
          }
          Navigator.pop(context, {
            "word": wordController.text,
            "meaning": meaningKo.text,
            "examples": examples,
            "phonetic": phonetic,
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 22),
            SizedBox(width: 8),
            Text("저장하기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            blurRadius: 8, color: Colors.black12, offset: Offset(0, 3)),
      ],
    );
  }
}
