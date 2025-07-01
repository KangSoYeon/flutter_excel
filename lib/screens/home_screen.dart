import 'package:flutter/material.dart';
import '../models/folder_node.dart';
import '../services/excel_parser_service.dart';
import '../widgets/folder_tree_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FolderNode> _folderStructure = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFolderStructure();
  }

  Future<void> _loadFolderStructure() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 실제 엑셀 파일 경로를 여기에 넣어주세요.
      // 이 예시에서는 'assets/folder_structure.xlsx'를 사용합니다.
      // 프로젝트 루트에 'assets' 폴더를 만들고 엑셀 파일을 넣어주세요.
      _folderStructure = await ExcelParserService().parseExcel(
        'assets/folder_structure.xlsx',
      );
    } catch (e) {
      setState(() {
        _error = '엑셀 파일 로드 중 오류 발생: $e';
      });
      print('Error: $_error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('엑셀 기반 폴더 구조'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : _folderStructure.isEmpty
              ? const Center(child: Text('엑셀 파일에서 폴더 구조를 찾을 수 없습니다.'))
              : FolderTreeView(folders: _folderStructure),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadFolderStructure,
        child: const Icon(Icons.refresh),
        tooltip: '새로고침',
      ),
    );
  }
}
