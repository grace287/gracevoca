import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

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
  // 2. 무료 한국어 번역 API
  // ----------------------------
  Future<String> translateToKorean(String text) async {
    try {
      final resp = await http.post(
        Uri.parse("https://libretranslate.com/translate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "q": text,
          "source": "en",
          "target": "ko"
        }),
      );

      final json = jsonDecode(resp.body);
      return json["translatedText"] ?? "번역 실패";
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
  // 발음 재생
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
        title: Text("단어 추가"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _searchInput(),
          SizedBox(height: 20),
          if (audioSources.isNotEmpty) _audioSection(),
          if (phonetic.isNotEmpty) _phoneticSection(),
          _meaningSection(),
          if (posList.isNotEmpty) _posSection(),
          if (examples.isNotEmpty) _exampleSection(),
          _formsSection(),
          if (recommendedWords.isNotEmpty) _recommendedSection(),
          SizedBox(height: 25),
          _saveButton(context),
        ]),
      ),
    );
  }

  Widget _searchInput() {
    return TextField(
      controller: wordController,
      decoration: InputDecoration(
        labelText: "단어 입력",
        filled: true,
        fillColor: Colors.white,
        suffixIcon: isLoading
            ? Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: Colors.deepPurple,
                  strokeWidth: 2,
                ),
              )
            : IconButton(
                icon: Icon(Icons.search),
                onPressed: () => fetchWordDetails(wordController.text.trim()),
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _audioSection() {
    return Row(
      children: [
        Icon(Icons.volume_up, color: Colors.deepPurple),
        SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
          ),
          onPressed: () => playAudio(audioSources.first),
          child: Text("발음 재생"),
        ),
      ],
    );
  }

  Widget _phoneticSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text("🔤 [ $phonetic ]", style: TextStyle(fontSize: 18)),
    );
  }

  Widget _meaningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("📌 한국어 뜻",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Container(
          padding: EdgeInsets.all(18),
          margin: EdgeInsets.only(top: 8),
          decoration: _cardStyle(),
          child: Text(
            meaningKo.text.isEmpty ? "자동으로 불러옵니다." : meaningKo.text,
            style: TextStyle(fontSize: 16),
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
        Text("📚 품사", style: TextStyle(fontSize: 17)),
        Wrap(
          spacing: 8,
          children:
              posList.map((p) => Chip(label: Text(p), backgroundColor: Colors.deepPurple.shade100)).toList(),
        )
      ],
    );
  }

  Widget _exampleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text("✏ 예문", style: TextStyle(fontSize: 17)),
        SizedBox(height: 8),
        Column(
          children: examples.take(3).map((e) {
            return Container(
              padding: EdgeInsets.all(14),
              margin: EdgeInsets.only(bottom: 10),
              decoration: _cardStyle(),
              child: Text(e),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _formsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text("🔗 형태 변화", style: TextStyle(fontSize: 17)),

        if (nounForms.isNotEmpty) _formItem("명사형", nounForms),
        if (verbForms.isNotEmpty) _formItem("동사형", verbForms),
        if (adjForms.isNotEmpty) _formItem("형용사형", adjForms),
        if (advForms.isNotEmpty) _formItem("부사형", advForms),
      ],
    );
  }

  Widget _formItem(String title, List<String> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        Text("• $title", style: TextStyle(fontSize: 15)),
        Wrap(
          spacing: 8,
          children: list
              .map((w) => Chip(label: Text(w), backgroundColor: Colors.deepPurple.shade50))
              .toList(),
        )
      ],
    );
  }

  Widget _recommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 25),
        Text("✨ 추천 단어",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: recommendedWords
              .map((w) =>
                  Chip(label: Text(w), backgroundColor: Colors.deepPurple.shade50))
              .toList(),
        ),
      ],
    );
  }

  Widget _saveButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context, {
          "word": wordController.text,
          "meaning": meaningKo.text,
          "examples": examples,
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        minimumSize: Size(double.infinity, 52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text("저장하기", style: TextStyle(fontSize: 18)),
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
