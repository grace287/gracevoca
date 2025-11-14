import 'package:flutter/material.dart';

class FlashcardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;

    return Scaffold(
      appBar: AppBar(
        title: Text("Flashcard"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(30),
          width: 300,
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data["word"]!,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                data["meaning"]!,
                style: TextStyle(fontSize: 22),
              ),
              SizedBox(height: 20),
              Text(
                data["example"]!,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}
