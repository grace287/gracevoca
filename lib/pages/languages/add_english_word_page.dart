import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddEnglishWordPage extends StatefulWidget {
  const AddEnglishWordPage({Key? key}) : super(key: key);
  
  @override
  State<AddEnglishWordPage> createState() => _AddEnglishWordPageState();
}

class _AddEnglishWordPageState extends State<AddEnglishWordPage> {
  final wordController = TextEditingController();
  final meaningController = TextEditingController();
  
  bool isLoading = false;
  String phonetic = "";
  List<Map<String, String>> meanings = [];
  List<String> examples = [];
  String searchedWord = "";
  String? selectedNotebook;
  List<String> notebooks = ['기본 단어장'];
  List<String> recommendedWords = ['hello', 'world', 'flutter', 'beautiful', 'amazing'];
  
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    _loadNotebooks();
    _loadRecommendedWords();
  }

  Future<void> _loadNotebooks() async {
    final prefs = await SharedPreferences.getInstance();
    final notebooksJson = prefs.getString('notebooks_by_language');
    if (notebooksJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(notebooksJson);
        final englishNotebooks = data['english'] as List?;
        if (englishNotebooks != null) {
          setState(() {
            notebooks = List<String>.from(englishNotebooks);
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

  Future<void> _loadRecommendedWords() async {
    final prefs = await SharedPreferences.getInstance();
    final recommended = prefs.getStringList('recommendedEnglishWords');
    if (recommended != null) {
      setState(() => recommendedWords = recommended);
    }
  }

  Future<void> fetchWord() async {
    String word = wordController.text.trim();
    if (word.isEmpty) return;

    setState(() {
      isLoading = true;
      searchedWord = word.toLowerCase();
    });

    try {
      final url = "https://api.dictionaryapi.dev/api/v2/entries/en/$word";
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)[0];
        
        phonetic = data["phonetic"]?.toString() ?? "";
        if (phonetic.isEmpty && data["phonetics"] != null) {
          for (var p in data["phonetics"]) {
            if (p["text"] != null && p["text"].toString().isNotEmpty) {
              phonetic = p["text"].toString();
              break;
            }
          }
        }
        
        meanings.clear();
        examples.clear();
        if (data["meanings"] != null) {
          for (var meaning in data["meanings"]) {
            String pos = _getPosAbbr(meaning["partOfSpeech"]?.toString() ?? "");
            var defs = meaning["definitions"] as List;
            for (int i = 0; i < defs.length && meanings.length < 5; i++) {
              meanings.add({
                "pos": pos,
                "definition": defs[i]["definition"]?.toString() ?? "",
              });
              if (defs[i]["example"] != null && examples.length < 4) {
                examples.add(defs[i]["example"].toString());
              }
            }
          }
        }
        
        if (meanings.isNotEmpty) {
          String toTranslate = meanings.take(3).map((m) => "${m['pos']} ${m['definition']}").join("; ");
          meaningController.text = await _translateToKorean(toTranslate);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('단어를 찾을 수 없습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }

    setState(() => isLoading = false);
  }

  String _getPosAbbr(String pos) {
    switch (pos.toLowerCase()) {
      case 'noun': return 'n.';
      case 'verb': return 'v.';
      case 'adjective': return 'adj.';
      case 'adverb': return 'adv.';
      case 'pronoun': return 'pron.';
      case 'preposition': return 'prep.';
      case 'conjunction': return 'conj.';
      default: return pos.isNotEmpty ? pos : '';
    }
  }

  Future<String> _translateToKorean(String text) async {
    try {
      final url = "https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=en|ko";
      final resp = await http.get(Uri.parse(url));
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body)["responseData"]["translatedText"]?.toString() ?? text;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            _buildSearchField(),
            SizedBox(height: 20),
            
            // 추천 단어
            Text('⭐ 추천 단어', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            _buildRecommendedWordsRow(),
            SizedBox(height: 20),
            
            if (phonetic.isNotEmpty) ...[
              _buildPhoneticCard(),
              SizedBox(height: 16),
            ],
            
            if (meanings.isNotEmpty) ...[
              _buildMeaningsSection(),
              SizedBox(height: 16),
            ],
            
            _buildMeaningField(),
            
            if (examples.isNotEmpty) ...[
              SizedBox(height: 20),
              Text('💬 예문', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              ...examples.take(3).map((ex) => _buildExampleCard(ex)),
            ],
            
            SizedBox(height: 20),
            _buildNotebookSelector(),
            
            SizedBox(height: 24),
            _buildSaveButton(),
            
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: TextField(
        controller: wordController,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: '영어 단어 입력',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.all(16),
          suffixIcon: isLoading 
              ? Padding(padding: EdgeInsets.all(12), child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
              : IconButton(icon: Icon(Icons.search, color: Colors.blue), onPressed: fetchWord),
        ),
        onSubmitted: (_) => fetchWord(),
      ),
    );
  }

  Widget _buildRecommendedWordsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: recommendedWords.map((word) {
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                wordController.text = word;
                fetchWord();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhoneticCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Text("🔤", style: TextStyle(fontSize: 22)),
          SizedBox(width: 12),
          Expanded(child: Text("[ $phonetic ]", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
          IconButton(
            icon: Icon(Icons.volume_up, color: Colors.blue),
            onPressed: () => flutterTts.speak(wordController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildMeaningsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📖 정의', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(height: 12),
          ...meanings.take(3).toList().asMap().entries.map((entry) {
            int idx = entry.key;
            var m = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: idx < 2 ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (m['pos']?.isNotEmpty == true)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(m['pos']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.blue.shade700)),
                    ),
                  if (m['pos']?.isNotEmpty == true) SizedBox(width: 8),
                  Expanded(
                    child: Text(m['definition'] ?? '', style: TextStyle(fontSize: 14, height: 1.4)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMeaningField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: TextField(
        controller: meaningController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: '한국어 뜻',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildExampleCard(String example) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: _buildHighlightedText(example),
    );
  }

  Widget _buildHighlightedText(String text) {
    if (searchedWord.isEmpty) {
      return Text(text, style: TextStyle(fontSize: 14, height: 1.5));
    }
    
    List<TextSpan> spans = [];
    RegExp exp = RegExp(searchedWord, caseSensitive: false);
    int lastMatchEnd = 0;
    
    for (var match in exp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(backgroundColor: Colors.yellow.shade200, fontWeight: FontWeight.w700),
      ));
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }
    
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
        children: spans,
      ),
    );
  }

  Widget _buildNotebookSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📚 단어장 선택', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: selectedNotebook,
              isExpanded: true,
              underline: SizedBox(),
              items: notebooks.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => selectedNotebook = newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (wordController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('단어를 입력해주세요')),
            );
            return;
          }
          
          Navigator.pop(context, {
            "word": wordController.text.trim(),
            "meaning": meaningController.text.trim(),
            "language": "english",
            "phonetic": phonetic,
            "example": examples.isNotEmpty ? examples.first : null,
            "examples": examples,
            "notebook": selectedNotebook ?? '기본 단어장',
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('저장', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
