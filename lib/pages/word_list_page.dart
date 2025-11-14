import 'package:flutter/material.dart';

class WordListPage extends StatefulWidget {
  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  List<Map<String, String>> words = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("내 단어장"),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),

      body: words.isEmpty
          ? _emptyView()
          : _listView(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          var result = await Navigator.pushNamed(context, "/addWord");
          if (result != null) {
            setState(() => words.add(result as Map<String, String>));
          }
        },
        backgroundColor: Colors.deepPurple,
        label: const Text("단어 추가"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.menu_book_outlined, size: 80, color: Colors.deepPurple),
          SizedBox(height: 20),
          Text("아직 단어가 없습니다.\n새로운 단어를 추가해 보세요."),
        ],
      ),
    );
  }

  Widget _listView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      itemBuilder: (_, i) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(words[i]["word"]!),
            subtitle: Text(words[i]["meaning"]!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, "/editWord",
                  arguments: {"index": i, "data": words[i]});
            },
          ),
        );
      },
    );
  }
}
