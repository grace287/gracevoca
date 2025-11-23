import 'package:flutter/material.dart';

class FlashcardPage extends StatefulWidget {
  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage>
    with SingleTickerProviderStateMixin {
  late List<Map<String, String>> words;
  late int currentIndex;
  bool isFlipped = false;
  late TabController _tabController;
  int correctCount = 0;
  int wrongCount = 0;
  int? quizIndex;
  String? selectedAnswer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    currentIndex = 0;
    words = [];
    Future.delayed(Duration.zero, _loadWords);
  }

  void _loadWords() {
    final data = ModalRoute.of(context)?.settings.arguments;
    if (data != null && data is Map<String, dynamic>) {
      final loadedWords = data['words'];
      if (loadedWords is List && loadedWords.isNotEmpty) {
        setState(() {
          words = List<Map<String, String>>.from(
            loadedWords.map((w) => Map<String, String>.from(w as Map))
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _nextCard() {
    setState(() {
      isFlipped = false;
      if (words.isNotEmpty) {
        currentIndex = (currentIndex + 1) % words.length;
      }
    });
  }

  void _previousCard() {
    setState(() {
      isFlipped = false;
      if (words.isNotEmpty) {
        currentIndex = (currentIndex - 1 + words.length) % words.length;
      }
    });
  }

  void _toggleFlip() {
    setState(() => isFlipped = !isFlipped);
  }

  void _startQuiz() {
    setState(() {
      _tabController.index = 1;
      quizIndex = 0;
      selectedAnswer = null;
      correctCount = 0;
      wrongCount = 0;
    });
  }

  void _checkAnswer(bool isCorrect) {
    if (isCorrect) {
      correctCount++;
    } else {
      wrongCount++;
    }

    if (quizIndex! < words.length - 1) {
      setState(() {
        quizIndex = quizIndex! + 1;
        selectedAnswer = null;
      });
    } else {
      _showQuizResult();
    }
  }

  void _showQuizResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎉 퀴즈 완료!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('정답: $correctCount개',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            Text('오답: $wrongCount개',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
            SizedBox(height: 16),
            Text(
                '정답률: ${((correctCount / (correctCount + wrongCount)) * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                quizIndex = null;
                selectedAnswer = null;
                correctCount = 0;
                wrongCount = 0;
                _tabController.index = 0;
              });
            },
            child: Text('플래시카드로 돌아가기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('📚 학습'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('📚 학습 및 퀴즈'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '🎴 플래시카드'),
            Tab(text: '❓ 퀴즈'),
          ],
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFlashcardView(),
          _buildQuizView(),
        ],
      ),
    );
  }

  Widget _buildFlashcardView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          color: Colors.deepPurple.withOpacity(0.1),
          child: Column(
            children: [
              Text('${currentIndex + 1} / ${words.length}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.deepPurple)),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: (currentIndex + 1) / words.length,
                color: Colors.deepPurple,
                backgroundColor: Colors.grey[300],
                minHeight: 8,
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: _toggleFlip,
              child: _buildFlipCard(),
            ),
          ),
        ),
        if (words[currentIndex]['example']?.isNotEmpty == true)
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 예문', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
                SizedBox(height: 8),
                Text(words[currentIndex]['example'] ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _previousCard,
                icon: Icon(Icons.arrow_back),
                label: Text('이전'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
              ElevatedButton.icon(
                onPressed: _startQuiz,
                icon: Icon(Icons.quiz),
                label: Text('퀴즈 시작'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              ),
              ElevatedButton.icon(
                onPressed: _nextCard,
                icon: Icon(Icons.arrow_forward),
                label: Text('다음'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlipCard() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: _buildCardSide(
        key: ValueKey(isFlipped),
        title: isFlipped ? '📖 뜻' : '🔤 단어',
        content: isFlipped ? (words[currentIndex]['meaning'] ?? '뜻') : (words[currentIndex]['word'] ?? '단어'),
        color: isFlipped ? Colors.green : Colors.blue,
      ),
    );
  }

  Widget _buildCardSide({
    required Key key,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      key: key,
      width: 300,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w700)),
          SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Text(content,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text('탭하여 보기', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    if (quizIndex == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 80, color: Colors.deepPurple),
            SizedBox(height: 24),
            Text('퀴즈 시작', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('${words.length}개 단어를 학습했습니다', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startQuiz,
              icon: Icon(Icons.play_arrow),
              label: Text('퀴즈 시작하기'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            ),
          ],
        ),
      );
    }

    final quizWord = words[quizIndex!];
    final choices = _generateChoices(quizIndex!);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          color: Colors.deepPurple.withOpacity(0.1),
          child: Column(
            children: [
              Text('${quizIndex! + 1} / ${words.length}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.deepPurple)),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text('정답: $correctCount', style: TextStyle(color: Colors.green)), LinearProgressIndicator(value: correctCount / words.length, color: Colors.green)],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text('오답: $wrongCount', style: TextStyle(color: Colors.red)), LinearProgressIndicator(value: wrongCount / words.length, color: Colors.red)],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text('다음 단어의 뜻은?', style: TextStyle(fontSize: 14, color: Colors.blue.shade800, fontWeight: FontWeight.w700)),
                      SizedBox(height: 16),
                      Text(quizWord['word'] ?? '', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                ...choices.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String choice = entry.value;
                  bool isCorrect = choice == quizWord['meaning'];
                  bool isSelected = selectedAnswer == choice;

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: GestureDetector(
                      onTap: selectedAnswer == null ? () {
                        setState(() => selectedAnswer = choice);
                        Future.delayed(Duration(milliseconds: 600), () {
                          _checkAnswer(isCorrect);
                        });
                      } : null,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? (isCorrect ? Colors.green.shade100 : Colors.red.shade100) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? (isCorrect ? Colors.green : Colors.red) : Colors.grey.shade300, width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? (isCorrect ? Colors.green : Colors.red) : Colors.grey.shade300,
                              ),
                              child: Center(
                                child: Text(String.fromCharCode(65 + idx),
                                    style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(child: Text(choice, style: TextStyle(fontSize: 16))),
                            if (isSelected) Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red, size: 28),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> _generateChoices(int correctIndex) {
    List<String> choices = [words[correctIndex]['meaning'] ?? ''];
    List<int> indices = [];
    while (indices.length < 3 && indices.length < words.length - 1) {
      int randomIndex = (DateTime.now().millisecondsSinceEpoch + indices.length) % words.length;
      if (randomIndex != correctIndex && !indices.contains(randomIndex)) {
        indices.add(randomIndex);
        choices.add(words[randomIndex]['meaning'] ?? '');
      }
    }
    choices.shuffle();
    return choices;
  }
}
