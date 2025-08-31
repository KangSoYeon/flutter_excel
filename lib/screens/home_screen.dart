import 'dart:io';
import 'package:excel_example/services/excel_writer_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
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
      final structure = await ExcelParserService().parseExcel(
        'assets/folder_structure.xlsx',
      );
      setState(() {
        _folderStructure = structure;
      });
    } catch (e) {
      setState(() {
        _error = '엑셀 파일 로드 중 오류 발생: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFolderAction(
      FolderAction action, FolderNode node, List<FolderNode> parentList) async {
    if (action == FolderAction.edit) {
      _showEditDialog(existingNode: node);
    } else if (action == FolderAction.add) {
      _showEditDialog(parentNode: node);
    } else if (action == FolderAction.delete) {
      _showDeleteConfirmation(node, parentList);
    }
  }

  Future<void> _showEditDialog({
    FolderNode? existingNode,
    FolderNode? parentNode,
  }) async {
    final isEditing = existingNode != null;
    final nameController =
        TextEditingController(text: isEditing ? existingNode.name.replaceAll('\n', '/') : '');
    final formKey = GlobalKey<FormState>();

    final newNodeName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? '이름 변경' : (parentNode == null ? '최상위 폴더 추가' : '하위 폴더 추가')),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: '폴더 이름 (영문/한글)'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '이름을 입력하세요.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(nameController.text.trim());
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (newNodeName != null) {
      final formattedName = newNodeName.replaceAll('/', '\n');
      setState(() {
        if (isEditing) {
          existingNode.name = formattedName;
        } else if (parentNode != null) {
          parentNode.children.add(FolderNode(name: formattedName));
        } else {
          _folderStructure.add(FolderNode(name: formattedName));
        }
      });
    }
  }

  Future<void> _showDeleteConfirmation(
      FolderNode nodeToDelete, List<FolderNode> parentList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: Text("'${nodeToDelete.name.replaceAll('\n', ' ')}' 폴더와 모든 하위 폴더를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        parentList.remove(nodeToDelete);
      });
    }
  }

  Future<void> _saveFile() async {
    if (_folderStructure.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 데이터가 없습니다.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('파일 생성 중...')),
    );

    try {
      final fileBytes = await ExcelWriterService().generateExcelBytes(_folderStructure);
      if (fileBytes == null) {
        throw Exception('Excel 파일 생성 실패');
      }

      if (kIsWeb) {
        // Web: Trigger browser download
        final blob = html.Blob([fileBytes],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "folder_structure_modified.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 다운로드가 시작되었습니다.')),
        );
      } else {
        // Mobile/Desktop: Save to documents directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/folder_structure_modified.xlsx';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일이 저장되었습니다: $filePath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 저장/생성 중 오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('엑셀 폴더 편집기'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _showEditDialog(), // Add root folder
            tooltip: '최상위 폴더 추가',
          ),
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _saveFile,
            tooltip: 'Excel로 저장/다운로드',
          ),
        ],
      ),
      body: _isLoading
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
              : FolderTreeView(
                  folders: _folderStructure,
                  onActionSelected: _handleFolderAction,
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadFolderStructure,
        child: const Icon(Icons.refresh),
        tooltip: '원본 다시 불러오기',
      ),
    );
  }
}
