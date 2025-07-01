import 'package:flutter/material.dart';
import '../models/folder_node.dart';
import 'folder_tile.dart';

class FolderTreeView extends StatelessWidget {
  final List<FolderNode> folders;

  const FolderTreeView({Key? key, required this.folders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return const Center(child: Text('폴더 구조가 없습니다.'));
    }
    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        // 각 최상위 폴더에 대해 FolderTile 위젯을 생성합니다.
        // level은 0으로 시작하여 들여쓰기의 기준이 됩니다.
        return FolderTile(folder: folders[index], level: 0);
      },
    );
  }
}
