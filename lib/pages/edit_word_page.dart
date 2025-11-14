import 'package:flutter/material.dart';

class EditWordPage extends StatefulWidget {
  @override
  State<EditWordPage> createState() => _EditWordPageState();
}

class _EditWordPageState extends State<EditWordPage> {
  TextEditingController word = TextEditingController();
  TextEditingController meaning = TextEditingController();
  TextEditingController example = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    word.text = args["data"]["word"];
    meaning.text = args["data"]["meaning"];
    example.text = args["data"]["example"];

    return Scaffold(
      appBar: AppBar(
        title: Text("기본 단어장"),
        elevation: 0.5,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: word, decoration: InputDecoration(labelText: "단어")),
            TextField(controller: meaning, decoration: InputDecoration(labelText: "뜻")),
            TextField(controller: example, decoration: InputDecoration(labelText: "예문"), maxLines: 2),
            Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("저장하기"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: Size(double.infinity, 50),
              ),
            )
          ],
        ),
      ),
    );
  }
}
