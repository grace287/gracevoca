import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AddWordPage extends StatefulWidget {
  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  final word = TextEditingController();
  final meaning = TextEditingController();
  final example = TextEditingController();

  final FlutterTts tts = FlutterTts();

  Future<void> _speak() async {
    if (word.text.trim().isNotEmpty) {
      await tts.speak(word.text);
    }
  }

  Future<void> _autoFill() async {
    // 나중에 OpenAI API 연결하면 여기서 자동 생성됨
    setState(() {
      meaning.text = "자동 생성된 뜻 예시";
      example.text = "자동 생성된 예문입니다.";
    });
  }

  void _save() {
    Navigator.pop(context, {
      "word": word.text,
      "meaning": meaning.text,
      "example": example.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("단어 추가"),
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: word,
                    decoration: const InputDecoration(labelText: "단어"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: _speak,
                )
              ],
            ),
            TextField(
              controller: meaning,
              decoration: const InputDecoration(labelText: "뜻"),
            ),
            TextField(
              controller: example,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "예문"),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _autoFill,
              child: const Text("자동 생성하기"),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("저장하기"),
            ),
          ],
        ),
      ),
    );
  }
}
