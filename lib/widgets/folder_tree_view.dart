import 'package:flutter/material.dart';
import '../models/folder_node.dart';

// Enum for menu actions, also used by home_screen
enum FolderAction { edit, add, delete }

class FolderTreeView extends StatelessWidget {
  final List<FolderNode> folders;
  final Future<void> Function(FolderAction, FolderNode, List<FolderNode>) onActionSelected;

  const FolderTreeView({Key? key, required this.folders, required this.onActionSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return const Center(
        child: Text(
          '표시할 폴더가 없습니다.\n상단의 \'+\' 버튼을 눌러 최상위 폴더를 추가하세요.',
          textAlign: TextAlign.center, // 옮겨진 속성
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        return _RecursiveFolderTile(
          node: folders[index],
          parentList: folders,
          onActionSelected: onActionSelected,
        );
      },
    );
  }
}

// A recursive tile that builds itself and its children
class _RecursiveFolderTile extends StatelessWidget {
  final FolderNode node;
  final List<FolderNode> parentList;
  final int level;
  final Future<void> Function(FolderAction, FolderNode, List<FolderNode>)
      onActionSelected;

  const _RecursiveFolderTile({
    Key? key,
    required this.node,
    required this.parentList,
    required this.onActionSelected,
    this.level = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      contentPadding: EdgeInsets.only(left: level * 16.0 + 16.0, right: 8.0),
      leading: Icon(node.children.isEmpty ? Icons.folder_open_outlined : Icons.folder_copy_outlined),
      title: Text(node.name.replaceAll('\n', ' / ')),
      trailing: PopupMenuButton<FolderAction>(
        onSelected: (action) => onActionSelected(action, node, parentList),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: FolderAction.edit,
            child: Text('이름 변경'),
          ),
          PopupMenuItem(
            value: FolderAction.add,
            child: Text('하위 폴더 추가'),
          ),
          PopupMenuDivider(),
          PopupMenuItem(
            value: FolderAction.delete,
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (node.children.isEmpty) {
      return tile;
    } else {
      return ExpansionTile(
        key: PageStorageKey(node.name + level.toString()), // Preserve expanded state
        tilePadding: EdgeInsets.only(left: level * 16.0, right: 0),
        title: tile,
        children: node.children
            .map((child) => _RecursiveFolderTile(
                  node: child,
                  parentList: node.children,
                  onActionSelected: onActionSelected,
                  level: level + 1,
                ))
            .toList(),
      );
    }
  }
}
