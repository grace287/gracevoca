import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'languages/add_english_word_page.dart';
import 'languages/add_japanese_word_page.dart';
import 'languages/add_chinese_word_page.dart';

// 단어 모델 클래스
class Word {
  String word;
  String meaning;
  String? phonetic;
  String? example;
  String notebook; // 단어장 이름
  String language; // 언어 ('english', 'japanese', 'chinese')
  bool isFavorite;
  DateTime createdAt;
  int reviewCount;
  int correctCount;
  DateTime? lastReviewed;
  
  // 일본어 전용
  String? kanji;
  String? hiragana;
  String? jlptLevel;
  
  // 중국어 전용
  String? simplified;
  String? pinyin;

  Word({
    required this.word,
    required this.meaning,
    this.phonetic,
    this.example,
    this.notebook = '기본 단어장',
    this.language = 'english',
    this.isFavorite = false,
    DateTime? createdAt,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.lastReviewed,
    this.kanji,
    this.hiragana,
    this.jlptLevel,
    this.simplified,
    this.pinyin,
  })  : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'word': word,
    'meaning': meaning,
    'phonetic': phonetic,
    'example': example,
    'notebook': notebook,
    'language': language,
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
    'reviewCount': reviewCount,
    'correctCount': correctCount,
    'lastReviewed': lastReviewed?.toIso8601String(),
    'kanji': kanji,
    'hiragana': hiragana,
    'jlptLevel': jlptLevel,
    'simplified': simplified,
    'pinyin': pinyin,
  };

  factory Word.fromJson(Map<String, dynamic> json) => Word(
    word: json['word'] ?? '',
    meaning: json['meaning'] ?? '',
    phonetic: json['phonetic'],
    example: json['example'],
    notebook: json['notebook'] ?? json['tags']?.first ?? '기본 단어장',
    language: json['language'] ?? 'english',
    isFavorite: json['isFavorite'] ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    reviewCount: json['reviewCount'] ?? 0,
    correctCount: json['correctCount'] ?? 0,
    lastReviewed: json['lastReviewed'] != null
        ? DateTime.parse(json['lastReviewed'])
        : null,
    kanji: json['kanji'],
    hiragana: json['hiragana'],
    jlptLevel: json['jlptLevel'],
    simplified: json['simplified'],
    pinyin: json['pinyin'],
  );

  double get accuracy =>
      reviewCount > 0 ? (correctCount / reviewCount * 100) : 0;
}

enum SortType { newest, oldest, alphabetical, mostReviewed, accuracy }

class WordListPage extends StatefulWidget {
  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage>
    with SingleTickerProviderStateMixin {
  List<Word> words = [];
  List<Word> filteredWords = [];
  final FlutterTts flutterTts = FlutterTts();
  bool _isLoading = true;
  String? _ttsError;
  SortType _currentSort = SortType.newest;
  String? _selectedNotebook;
  bool _showFavoritesOnly = false;
  late TabController _tabController;

  // 필터 상태
  String _searchQuery = "";
  String? _accuracyFilter; // 'high', 'medium', 'low'
  String _selectedLanguage = 'all'; // 'all', 'english', 'japanese', 'chinese'

  // 언어별 단어장 목록 (독립적으로 관리)
  Map<String, List<String>> notebooksByLanguage = {
    'english': ['기본 단어장'],
    'japanese': ['기본 단어장'],
    'chinese': ['기본 단어장'],
  };
  
  // 현재 선택된 언어의 단어장 목록
  List<String> get notebooks {
    if (_selectedLanguage == 'all') {
      return ['기본 단어장']; // 전체 보기에서는 공통 단어장만
    }
    return notebooksByLanguage[_selectedLanguage] ?? ['기본 단어장'];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initTts();
    _loadWords();
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      flutterTts.setErrorHandler((msg) {
        setState(() => _ttsError = msg);
      });
    } catch (e) {
      setState(() => _ttsError = e.toString());
      debugPrint('TTS 초기화 실패: $e');
    }
  }

  Future<void> _loadWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? wordsJson = prefs.getString('words_v2');
      
      // 언어별 단어장 목록 로드
      final String? notebooksJson = prefs.getString('notebooks_by_language');
      if (notebooksJson != null) {
        final decoded = json.decode(notebooksJson) as Map<String, dynamic>;
        notebooksByLanguage = decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
      }

      if (wordsJson != null) {
        final List<dynamic> decoded = json.decode(wordsJson);
        setState(() {
          words = decoded.map((e) => Word.fromJson(e)).toList();
          _applyFilters();
          _isLoading = false;
        });
      } else {
        // 샘플 데이터
        _loadSampleData();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('단어 불러오기 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  void _loadSampleData() {
    words = [
      Word(
        word: 'serendipity',
        meaning: '뜻밖의 행운, 우연한 발견',
        phonetic: 'ˌserənˈdɪpəti',
        example: 'Finding you was pure serendipity.',
        notebook: '기본 단어장',
        isFavorite: true,
        reviewCount: 5,
        correctCount: 4,
      ),
      Word(
        word: 'ephemeral',
        meaning: '덧없는, 단명한',
        phonetic: 'ɪˈfem(ə)rəl',
        example: 'The beauty of cherry blossoms is ephemeral.',
        notebook: '기본 단어장',
        reviewCount: 3,
        correctCount: 3,
      ),
    ];
    _saveWords();
  }

  Future<void> _saveWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String wordsJson =
      json.encode(words.map((w) => w.toJson()).toList());
      await prefs.setString('words_v2', wordsJson);
    } catch (e) {
      debugPrint('단어 저장 실패: $e');
    }
  }

  void _applyFilters() {
    filteredWords = List.from(words);

    // 언어 필터
    if (_selectedLanguage != 'all') {
      filteredWords = filteredWords.where((w) => w.language == _selectedLanguage).toList();
    }

    // 즐겨찾기 필터
    if (_showFavoritesOnly) {
      filteredWords = filteredWords.where((w) => w.isFavorite).toList();
    }

    // 단어장 필터
    if (_selectedNotebook != null) {
      filteredWords = filteredWords.where((w) => w.notebook == _selectedNotebook).toList();
    }

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      filteredWords = filteredWords.where((w) =>
          w.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          w.meaning.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // 정확도 필터
    if (_accuracyFilter != null) {
      if (_accuracyFilter == 'high') {
        filteredWords = filteredWords.where((w) => w.reviewCount > 0 && w.accuracy >= 70).toList();
      } else if (_accuracyFilter == 'medium') {
        filteredWords = filteredWords.where((w) => w.reviewCount > 0 && w.accuracy >= 40 && w.accuracy < 70).toList();
      } else if (_accuracyFilter == 'low') {
        filteredWords = filteredWords.where((w) => w.reviewCount == 0 || w.accuracy < 40).toList();
      }
    }

    // 정렬
    switch (_currentSort) {
      case SortType.newest:
        filteredWords.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.oldest:
        filteredWords.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortType.alphabetical:
        filteredWords.sort((a, b) => a.word.compareTo(b.word));
        break;
      case SortType.mostReviewed:
        filteredWords.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case SortType.accuracy:
        filteredWords.sort((a, b) => b.accuracy.compareTo(a.accuracy));
        break;
    }
  }

  Future<void> _speakWord(String word) async {
    if (_ttsError != null) return;
    try {
      await flutterTts.speak(word);
    } catch (e) {
      debugPrint('음성 재생 실패: $e');
    }
  }

  Future<void> _navigateAndAddWord() async {
    // 현재 필터된 언어를 사용, 'all'인 경우 다이얼로그 표시
    String language = _selectedLanguage;
    
    if (_selectedLanguage == 'all') {
      // 언어 선택 다이얼로그
      String? selected = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('언어 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: Text('영어'),
                onTap: () => Navigator.pop(context, 'english'),
              ),
              ListTile(
                leading: Text('🇯🇵', style: TextStyle(fontSize: 24)),
                title: Text('일본어'),
                onTap: () => Navigator.pop(context, 'japanese'),
              ),
              ListTile(
                leading: Text('🇨🇳', style: TextStyle(fontSize: 24)),
                title: Text('중국어'),
                onTap: () => Navigator.pop(context, 'chinese'),
              ),
            ],
          ),
        ),
      );
      
      if (selected == null) return;
      language = selected;
    }

    // 언어에 따라 적절한 페이지로 이동
    Widget pageToNavigate;
    if (language == 'english') {
      pageToNavigate = AddEnglishWordPage();
    } else if (language == 'japanese') {
      pageToNavigate = AddJapaneseWordPage();
    } else if (language == 'chinese') {
      pageToNavigate = AddChineseWordPage();
    } else {
      return; // 알 수 없는 언어
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pageToNavigate),
    );

    if (result != null && result is Map<String, dynamic>) {
      // 언어별 AddWordPage에서 반환된 Map을 Word 객체로 변환
      String wordLanguage = result['language'] ?? language;
      String notebookName = result['notebook'] ?? _selectedNotebook ?? '기본 단어장';
      
      // 해당 언어의 단어장 목록에 없으면 기본 단어장 사용
      if (!notebooksByLanguage.containsKey(wordLanguage)) {
        notebooksByLanguage[wordLanguage] = ['기본 단어장'];
      }
      if (!notebooksByLanguage[wordLanguage]!.contains(notebookName)) {
        notebookName = '기본 단어장';
      }
      
      final newWord = Word(
        word: result['word'] ?? '',
        meaning: result['meaning'] ?? '',
        phonetic: result['phonetic'],
        example: result['example'] ?? (result['examples']?.isNotEmpty == true ? result['examples'][0] : null),
        notebook: notebookName,
        language: wordLanguage,
        kanji: result['kanji'],
        hiragana: result['hiragana'],
        jlptLevel: result['jlptLevel'],
        simplified: result['simplified'],
        pinyin: result['pinyin'],
      );
      
      setState(() {
        words.add(newWord);
        _applyFilters();
      });
      await _saveWords();
      
      // 단어장 목록도 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notebooks_by_language', json.encode(notebooksByLanguage));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('단어가 추가되었습니다! 🎉'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _toggleFavorite(Word word) {
    setState(() {
      word.isFavorite = !word.isFavorite;
      _applyFilters();
    });
    _saveWords();
  }



  @override
  void dispose() {
    flutterTts.stop();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildLanguageTabs(),
            _buildStatsCard(),
            _buildFiltersBar(),
            if (filteredWords.isEmpty) _buildEmptyView() else _buildWordList(),
          ],
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          '내 단어장',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple, Colors.deepPurple.shade700],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          tooltip: '검색',
          onPressed: () {
            showSearch(
              context: context,
              delegate: WordSearchDelegate(words, _speakWord),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final totalWords = words.length;
    final favoriteWords = words.where((w) => w.isFavorite).length;
    final reviewedWords = words.where((w) => w.reviewCount > 0).length;
    final avgAccuracy = words.isEmpty
        ? 0.0
        : words.map((w) => w.accuracy).reduce((a, b) => a + b) / words.length;

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Quick Add Section
          Container(
            margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.add_circle_outline, color: Colors.deepPurple, size: 24),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '빠른 단어 추가',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _navigateAndAddWord,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.search, color: Colors.grey.shade600),
                                  SizedBox(width: 12),
                                  Text(
                                    '영어 단어를 입력하세요...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _navigateAndAddWord,
                          child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats Card
          Container(
            margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(Icons.library_books, '전체', '$totalWords'),
                      _buildStatItem(Icons.star, '즐겨찾기', '$favoriteWords'),
                      _buildStatItem(Icons.check_circle, '학습완료', '$reviewedWords'),
                      _buildStatItem(
                        Icons.trending_up,
                        '정확도',
                        '${avgAccuracy.toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLanguageTabs() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.grey[100],
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildLanguageTab('전체', 'all', Icons.language, Colors.deepPurple),
              SizedBox(width: 8),
              _buildLanguageTab('영어', 'english', Icons.g_translate, Colors.blue),
              SizedBox(width: 8),
              _buildLanguageTab('일본어', 'japanese', Icons.flag, Colors.red),
              SizedBox(width: 8),
              _buildLanguageTab('중국어', 'chinese', Icons.flag_outlined, Colors.amber.shade700),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTab(String label, String language, IconData icon, Color color) {
    bool selected = _selectedLanguage == language;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLanguage = language;
          _applyFilters();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 검색바
            Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilters();
                  });
                },
                decoration: InputDecoration(
                  hintText: '단어 또는 뜻으로 검색...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchQuery = "";
                              _applyFilters();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            // 단어장 및 필터
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          '📖 모든 단어',
                          _selectedNotebook == null && !_showFavoritesOnly,
                              () {
                            setState(() {
                              _selectedNotebook = null;
                              _showFavoritesOnly = false;
                              _applyFilters();
                            });
                          },
                        ),
                        _buildFilterChip(
                          '⭐ 즐겨찾기',
                          _showFavoritesOnly,
                              () {
                            setState(() {
                              _showFavoritesOnly = !_showFavoritesOnly;
                              _selectedNotebook = null;
                              _applyFilters();
                            });
                          },
                        ),
                        ...notebooks.map(
                              (notebook) => _buildFilterChip(
                            '📓 $notebook',
                            _selectedNotebook == notebook,
                                () {
                              setState(() {
                                _selectedNotebook = _selectedNotebook == notebook ? null : notebook;
                                _showFavoritesOnly = false;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16, color: Colors.deepPurple),
                                SizedBox(width: 4),
                                Text('단어장 추가'),
                              ],
                            ),
                            onPressed: _addNotebook,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.deepPurple, width: 2),
                            labelStyle: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    // 정확도 필터
                    PopupMenuButton<String?>(
                      icon: Icon(
                        Icons.military_tech,
                        color: _accuracyFilter != null ? Colors.deepPurple : Colors.grey,
                      ),
                      tooltip: '정확도 필터',
                      onSelected: (value) {
                        setState(() {
                          _accuracyFilter = value;
                          _applyFilters();
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.clear, size: 18),
                              SizedBox(width: 8),
                              Text('전체'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'high',
                          child: Row(
                            children: [
                              Icon(Icons.workspace_premium, size: 18, color: Colors.amber),
                              SizedBox(width: 8),
                              Text('높음 (70% 이상)'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'medium',
                          child: Row(
                            children: [
                              Icon(Icons.star_half, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('중간 (40-70%)'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'low',
                          child: Row(
                            children: [
                              Icon(Icons.trending_down, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('낮음 (40% 미만)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // 정렬
                    PopupMenuButton<SortType>(
                      icon: Icon(Icons.sort, color: Colors.deepPurple),
                      tooltip: '정렬',
                      onSelected: (type) {
                        setState(() {
                          _currentSort = type;
                          _applyFilters();
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: SortType.newest,
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 18),
                              SizedBox(width: 8),
                              Text('최신순'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: SortType.oldest,
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 18),
                              SizedBox(width: 8),
                              Text('오래된순'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: SortType.alphabetical,
                          child: Row(
                            children: [
                              Icon(Icons.sort_by_alpha, size: 18),
                              SizedBox(width: 8),
                              Text('알파벳순'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: SortType.mostReviewed,
                          child: Row(
                            children: [
                              Icon(Icons.repeat, size: 18),
                              SizedBox(width: 8),
                              Text('복습 많은순'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: SortType.accuracy,
                          child: Row(
                            children: [
                              Icon(Icons.stars, size: 18),
                              SizedBox(width: 8),
                              Text('정확도순'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white,
        selectedColor: Colors.deepPurple.shade100,
        labelStyle: TextStyle(
          color: selected ? Colors.deepPurple : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: selected ? Colors.deepPurple : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildWordList() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final word = filteredWords[index];
            return _buildWordCard(word, index);
          },
          childCount: filteredWords.length,
        ),
      ),
    );
  }

  Widget _buildWordCard(Word word, int index) {
    return Dismissible(
      key: ValueKey('${word.word}_${word.createdAt}'),
      background: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("단어 삭제"),
              content: Text("'${word.word}'를 삭제하시겠습니까?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("취소"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("삭제", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        setState(() {
          words.remove(word);
          _applyFilters();
        });
        await _saveWords();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("'${word.word}' 단어가 삭제되었습니다."),
              action: SnackBarAction(
                label: '실행취소',
                onPressed: () {
                  setState(() {
                    words.insert(index, word);
                    _applyFilters();
                  });
                  _saveWords();
                },
              ),
            ),
          );
        }
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        shadowColor: Colors.deepPurple.withOpacity(0.1),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WordDetailPage(
                  word: word,
                  notebooks: notebooks,
                ),
              ),
            );

            if (result == 'updated') {
              setState(() => _applyFilters());
              _saveWords();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple,
                            Colors.deepPurple.shade300
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          word.word.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  word.word,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  word.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: word.isFavorite
                                      ? Colors.amber
                                      : Colors.grey,
                                ),
                                onPressed: () => _toggleFavorite(word),
                              ),
                              IconButton(
                                icon: Icon(Icons.volume_up,
                                    color: Colors.deepPurple),
                                onPressed: () => _speakWord(word.word),
                              ),
                            ],
                          ),
                          if (word.phonetic != null) ...[
                            Text(
                              '[ ${word.phonetic} ]',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  word.meaning,
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                if (word.example != null) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.format_quote, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            word.example!,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (word.reviewCount > 0) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.repeat, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '복습 ${word.reviewCount}회',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        '정확도 ${word.accuracy.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 80,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 30),
            Text(
              _selectedNotebook != null || _showFavoritesOnly
                  ? "필터 조건에 맞는 단어가 없어요"
                  : "단어장이 비어있어요",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "새로운 단어를 추가하고\n영어 실력을 키워보세요!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.5),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _navigateAndAddWord,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        label: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              "AI로 단어 추가",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.5,
                color: Colors.white,
            
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<void> _addNotebook() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('새 단어장 추가'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '단어장 이름을 입력하세요',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(Icons.book),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: Text('추가', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && !notebooks.contains(result)) {
      String lang = _selectedLanguage == 'all' ? 'english' : _selectedLanguage;
      
      setState(() {
        if (!notebooksByLanguage.containsKey(lang)) {
          notebooksByLanguage[lang] = ['기본 단어장'];
        }
        if (!notebooksByLanguage[lang]!.contains(result)) {
          notebooksByLanguage[lang]!.add(result);
        }
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notebooks_by_language', json.encode(notebooksByLanguage));
      
      if (mounted) {
        String langName = lang == 'english' ? '영어' : lang == 'japanese' ? '일본어' : '중국어';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$result" 단어장이 $langName에 추가되었습니다'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// 검색 Delegate
class WordSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final List<Word> words;
  final Function(String) onSpeak;

  WordSearchDelegate(this.words, this.onSpeak);

  @override
  String get searchFieldLabel => '단어 또는 뜻 검색';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.deepPurple,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: Colors.white),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = words.where((word) {
      final wordText = word.word.toLowerCase();
      final meaning = word.meaning.toLowerCase();
      final q = query.toLowerCase();
      return wordText.contains(q) || meaning.contains(q);
    }).toList();

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('단어나 뜻을 검색해보세요', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("'$query'에 대한 검색 결과가 없습니다"),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final word = results[index];
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(Icons.book_outlined, color: Colors.deepPurple),
            title: Text(word.word, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(word.meaning, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: Icon(Icons.volume_up_outlined, color: Colors.deepPurple),
              onPressed: () => onSpeak(word.word),
            ),
          ),
        );
      },
    );
  }
}

// 단어 상세 페이지
class WordDetailPage extends StatefulWidget {
  final Word word;
  final List<String> notebooks;

  WordDetailPage({required this.word, required this.notebooks});

  @override
  _WordDetailPageState createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage> {
  late TextEditingController _wordController;
  late TextEditingController _meaningController;
  late TextEditingController _phoneticController;
  late TextEditingController _exampleController;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.word.word);
    _meaningController = TextEditingController(text: widget.word.meaning);
    _phoneticController = TextEditingController(text: widget.word.phonetic ?? '');
    _exampleController = TextEditingController(text: widget.word.example ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('단어 상세'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              widget.word.word = _wordController.text.trim();
              widget.word.meaning = _meaningController.text.trim();
              widget.word.phonetic = _phoneticController.text.trim().isEmpty
                  ? null
                  : _phoneticController.text.trim();
              widget.word.example = _exampleController.text.trim().isEmpty
                  ? null
                  : _exampleController.text.trim();
              Navigator.pop(context, 'updated');
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _wordController,
            decoration: InputDecoration(
              labelText: '단어',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _meaningController,
            decoration: InputDecoration(
              labelText: '뜻',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _phoneticController,
            decoration: InputDecoration(
              labelText: '발음기호',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _exampleController,
            decoration: InputDecoration(
              labelText: '예문',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16),
          Text('단어장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: widget.word.notebook,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.book),
            ),
            items: widget.notebooks.map((notebook) {
              return DropdownMenuItem(
                value: notebook,
                child: Text(notebook),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  widget.word.notebook = value;
                });
              }
            },
          ),
          SizedBox(height: 24),
          if (widget.word.reviewCount > 0) ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('학습 통계', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('${widget.word.reviewCount}',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                            Text('복습 횟수', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('${widget.word.correctCount}',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                            Text('정답 횟수', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('${widget.word.accuracy.toStringAsFixed(0)}%',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                            Text('정확도', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 퀴즈 페이지
class QuizPage extends StatefulWidget {
  final List<Word> words;

  QuizPage({required this.words});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late List<Word> quizWords;
  int currentIndex = 0;
  List<Map<String, dynamic>> results = [];
  List<String> options = [];

  @override
  void initState() {
    super.initState();
    quizWords = (widget.words.toList()..shuffle()).take(min(10, widget.words.length)).toList();
    _generateOptions();
  }

  void _generateOptions() {
    final currentWord = quizWords[currentIndex];
    options = [currentWord.meaning];

    final otherWords = widget.words.where((w) => w.word != currentWord.word).toList()..shuffle();
    options.addAll(otherWords.take(3).map((w) => w.meaning));
    options.shuffle();
  }

  void _selectAnswer(String answer) {
    final isCorrect = answer == quizWords[currentIndex].meaning;
    results.add({
      'word': quizWords[currentIndex].word,
      'correct': isCorrect,
    });

    if (currentIndex < quizWords.length - 1) {
      setState(() {
        currentIndex++;
        _generateOptions();
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    final correctCount = results.where((r) => r['correct']).length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('퀴즈 완료! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$correctCount / ${results.length}',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            Text('정답률: ${(correctCount / results.length * 100).toStringAsFixed(0)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {'results': results});
            },
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (currentIndex + 1) / quizWords.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('퀴즈 ${currentIndex + 1}/${quizWords.length}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress, minHeight: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '다음 단어의 뜻은?',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      quizWords[currentIndex].word,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  SizedBox(height: 48),
                  ...options.map((option) => Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _selectAnswer(option),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(option, style: TextStyle(fontSize: 16)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 통계 페이지
class StatisticsPage extends StatelessWidget {
  final List<Word> words;

  StatisticsPage({required this.words});

  @override
  Widget build(BuildContext context) {
    final totalWords = words.length;
    final reviewedWords = words.where((w) => w.reviewCount > 0).length;
    final totalReviews = words.fold<int>(0, (sum, w) => sum + w.reviewCount);
    final avgAccuracy = words.isEmpty
        ? 0.0
        : words.where((w) => w.reviewCount > 0).fold<double>(0, (sum, w) => sum + w.accuracy) /
        (reviewedWords > 0 ? reviewedWords : 1);

    final topWords = (words.toList()
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount)))
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('학습 통계'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('전체 통계', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('총 단어', '$totalWords개', Icons.book),
                      _buildStatItem('학습한 단어', '$reviewedWords개', Icons.check_circle),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('총 복습', '$totalReviews회', Icons.repeat),
                      _buildStatItem('평균 정확도', '${avgAccuracy.toStringAsFixed(0)}%', Icons.stars),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('가장 많이 복습한 단어 TOP 5',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  ...topWords.asMap().entries.map((entry) {
                    final index = entry.key;
                    final word = entry.value;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text('${index + 1}', style: TextStyle(color: Colors.white)),
                      ),
                      title: Text(word.word, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${word.reviewCount}회 복습 • 정확도 ${word.accuracy.toStringAsFixed(0)}%'),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.deepPurple),
        SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}