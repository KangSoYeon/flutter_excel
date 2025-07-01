// lib/widgets/folder_tile.dart
import 'package:flutter/material.dart';
import '../models/folder_node.dart'; // FolderNode 모델 임포트 확인

class FolderTile extends StatelessWidget {
  final FolderNode folder;
  final int level; // 들여쓰기를 위한 레벨

  const FolderTile({Key? key, required this.folder, this.level = 0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 줄바꿈 문자를 Text 위젯이 올바르게 렌더링하도록 함
    final folderTitleWidget = Text(
      folder.name,
      softWrap: true, // 여러 줄로 표시 가능
      maxLines: null, // 줄 수 제한 없음
    );

    if (folder.children.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: level * 16.0), // 들여쓰기
        child: ListTile(
          leading: const Icon(Icons.folder),
          title: folderTitleWidget, // 수정된 Text 위젯 사용
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(left: level * 16.0), // 들여쓰기
        child: ExpansionTile(
          leading: const Icon(Icons.folder),
          title: folderTitleWidget, // 수정된 Text 위젯 사용
          children:
              folder.children
                  .map(
                    (childFolder) => FolderTile(
                      folder: childFolder,
                      level: level + 1, // 자식은 레벨 증가
                    ),
                  )
                  .toList(),
        ),
      );
    }
  }
}
