import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDFF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.book, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text(
                "GraceVoca",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text("AI 기반 자동화 단어장"),
              const SizedBox(height: 40),

              // ⬇⬇ 여기서 WordListPage로 이동!
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/wordList');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
                child: const Text("시작하기"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
