import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:audioplayers/audioplayers.dart';

class AddWordPage extends StatefulWidget {
  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  final wordController = TextEditingController();
  final meaningKo = TextEditingController();
  List<String> examples = [];
  List<String> derivedWords = [];
  List<String> audioUrls = [];
  List<String> partsOfSpeech = [];

  bool isLoading = false;

  Future<void> fetchWordDetails(String word) async {
    setState(() {
      isLoading = true;
      partsOfSpeech.clear();
      examples.clear();
      derivedWords.clear();
      audioUrls.clear();
    });

    try {
      // -------------------------
      // 1) Free Dictionary API
      // -------------------------
      final url =
          "https://api.dictionaryapi.dev/api/v2/entries/en/$word";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception("Not found");

      final data = json.decode(response.body);

      // **발음(mp3)**  
      data[0]["phonetics"].forEach((p) {
        if (p["audio"] != null && p["audio"].toString().isNotEmpty) {
          audioUrls.add(p["audio"]);
        }
      });

      // **뜻/품사/예문**
      List<String> engMeanings = [];

      for (var meaning in data[0]["meanings"]) {
        final pos = meaning["partOfSpeech"];
        partsOfSpeech.add(pos);

        for (var def in meaning["definitions"]) {
          if (def["definition"] != null) {
            engMeanings.add(def["definition"]);
          }
          if (def["example"] != null) {
            examples.add(def["example"]);
          }
        }

        // 파생어/관련어
        if (meaning["synonyms"] != null) {
          derivedWords.addAll(
            List<String>.from(meaning["synonyms"]).take(5),
          );
        }
      }

      // -------------------------
      // 2) 무료 한국어 번역 API
      // -------------------------
      final transResp = await http.post(
        Uri.parse("https://libretranslate.com/translate"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "q": engMeanings.take(2).join(". "),
          "source": "en",
          "target": "ko"
        }),
      );

      final transJson = json.decode(transResp.body);

      meaningKo.text = transJson["translatedText"];

    } catch (e) {
      meaningKo.text = "뜻을 찾을 수 없습니다.";
      examples = ["예문을 가져올 수 없습니다."];
    }

    setState(() => isLoading = false);
  }

  // void playAudio(String url) async {
  //   final player = AudioPlayer();
  //   await player.play(UrlSource(url));
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2FF),
      appBar: AppBar(
        title: Text("단어 추가"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------- 단어 입력 -------------------
            TextField(
              controller: wordController,
              decoration: InputDecoration(
                labelText: "단어 입력",
                hintText: "예: secure",
                filled: true,
                fillColor: Colors.white,
                suffixIcon: isLoading
                    ? Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            color: Colors.deepPurple, strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () =>
                            fetchWordDetails(wordController.text.trim()),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            SizedBox(height: 20),

            // ------------------- 발음 버튼들 -------------------
            // if (audioUrls.isNotEmpty) ...[
            //   Text("🔊 발음 듣기", style: TextStyle(fontSize: 16)),
            //   Wrap(
            //     spacing: 10,
            //     children: audioUrls
            //         .map((url) => ElevatedButton(
            //               onPressed: () => playAudio(url),
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: Colors.deepPurple,
            //               ),
            //               child: Text("재생"),
            //             ))
            //         .toList(),
            //   ),
            //   SizedBox(height: 20),
            // ],

            // ------------------- 한국어 뜻 -------------------
            Text("📌 한국어 뜻",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      blurRadius: 8, color: Colors.black12, offset: Offset(0, 3))
                ],
              ),
              child: Text(
                meaningKo.text.isEmpty
                    ? "자동 생성된 뜻이 여기에 표시됩니다."
                    : meaningKo.text,
                style: TextStyle(fontSize: 16),
              ),
            ),

            SizedBox(height: 25),

            // ------------------- 품사 -------------------
            if (partsOfSpeech.isNotEmpty) ...[
              Text("📚 품사", style: TextStyle(fontSize: 17)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: partsOfSpeech
                    .map((pos) => Chip(
                          label: Text(pos),
                          backgroundColor: Colors.deepPurple.shade100,
                        ))
                    .toList(),
              ),
              SizedBox(height: 20),
            ],

            // ------------------- 예문 -------------------
            Text("✏ 예문", style: TextStyle(fontSize: 17)),
            SizedBox(height: 8),
            Column(
              children: examples
                  .take(3)
                  .map(
                    (ex) => Container(
                      padding: EdgeInsets.all(14),
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 6,
                              color: Colors.black12,
                              offset: Offset(0, 3))
                        ],
                      ),
                      child: Text(ex, style: TextStyle(fontSize: 15)),
                    ),
                  )
                  .toList(),
            ),

            // ------------------- 파생어 -------------------
            if (derivedWords.isNotEmpty) ...[
              SizedBox(height: 25),
              Text("🔗 파생어 / 관련어",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: derivedWords
                    .map((w) => Chip(
                          label: Text(w),
                          backgroundColor: Colors.deepPurple.shade50,
                        ))
                    .toList(),
              )
            ],

            SizedBox(height: 40),

            // ------------------- 저장 버튼 -------------------
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  "word": wordController.text,
                  "meaning": meaningKo.text,
                  "examples": examples,
                  "derived": derivedWords
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text("저장하기", style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}
