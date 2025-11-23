import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'english';
  bool _autoAddEnglish = false;
  bool _autoAddJapanese = false;
  bool _autoAddChinese = false;
  bool _showMenu = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'english';
      _autoAddEnglish = prefs.getBool('autoAddEnglish') ?? false;
      _autoAddJapanese = prefs.getBool('autoAddJapanese') ?? false;
      _autoAddChinese = prefs.getBool('autoAddChinese') ?? false;
      _showMenu = prefs.getBool('showMenu') ?? false;
    });
  }

  Future<void> _saveLanguageSetting(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', value);
    setState(() {
      _selectedLanguage = value;
    });
  }

  Future<void> _toggleAutoAdd(String language, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (language == 'english') {
      await prefs.setBool('autoAddEnglish', value);
      setState(() {
        _autoAddEnglish = value;
      });
    } else if (language == 'japanese') {
      await prefs.setBool('autoAddJapanese', value);
      setState(() {
        _autoAddJapanese = value;
      });
    } else if (language == 'chinese') {
      await prefs.setBool('autoAddChinese', value);
      setState(() {
        _autoAddChinese = value;
      });
    }
  }

  Future<void> _toggleShowMenu(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showMenu', value);
    setState(() {
      _showMenu = value;
    });
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('전체 삭제'),
        content: Text('모든 단어를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // word_list_page에서 처리하도록 구현
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('기능 준비중입니다')),
              );
              Navigator.pop(context);
            },
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('⚙️ 설정', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 언어 설정 섹션
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '언어 설정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildLanguageOption('🇺🇸 영어', 'english'),
                        SizedBox(height: 12),
                        _buildLanguageOption('🇯🇵 일본어', 'japanese'),
                        SizedBox(height: 12),
                        _buildLanguageOption('🇨🇳 중국어', 'chinese'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // AI 자동 단어 추가 섹션
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'AI 자동 단어 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildAutoAddToggle(
                          '🇺🇸 영어 AI 자동 추가',
                          _autoAddEnglish,
                          (value) => _toggleAutoAdd('english', value),
                        ),
                        SizedBox(height: 12),
                        _buildAutoAddToggle(
                          '🇯🇵 일본어 AI 자동 추가',
                          _autoAddJapanese,
                          (value) => _toggleAutoAdd('japanese', value),
                        ),
                        SizedBox(height: 12),
                        _buildAutoAddToggle(
                          '🇨🇳 중국어 AI 자동 추가',
                          _autoAddChinese,
                          (value) => _toggleAutoAdd('chinese', value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Show Menu 설정 섹션
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '단어장 표시 설정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '모든 단어장 표시',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: _showMenu,
                          onChanged: _toggleShowMenu,
                          activeColor: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 단어 관리 섹션
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '단어 관리',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('내보내기 기능 준비중입니다')),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.upload, color: Colors.deepPurple),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  '내보내기',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('가져오기 기능 준비중입니다')),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.download, color: Colors.deepPurple),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  '가져오기',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        InkWell(
                          onTap: () => _showClearDialog(),
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever, color: Colors.red),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  '모든 단어 삭제',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.red),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 앱 정보 섹션
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '앱 정보',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('앱 이름'),
                            Text('GraceVoca', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('버전'),
                            Text('1.0.0', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, String value) {
    return InkWell(
      onTap: () => _saveLanguageSetting(value),
      child: Row(
        children: [
          Radio(
            value: value,
            groupValue: _selectedLanguage,
            onChanged: (newValue) {
              if (newValue != null) {
                _saveLanguageSetting(newValue);
              }
            },
            activeColor: Colors.deepPurple,
          ),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoAddToggle(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.deepPurple,
        ),
      ],
    );
  }
}
