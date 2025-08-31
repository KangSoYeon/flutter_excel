// models/folder_node.dart
class FolderNode {
  String name; // final 제거
  final List<FolderNode> children; // final을 유지

  // **반드시 이 형태로 되어야 합니다.**
  // children을 외부에서 넘겨주지 않으면, 빈 **수정 가능한** 리스트가 할당됩니다.
  // 'const []' 대신 '<FolderNode>[]' 또는 '[]'를 사용해야 합니다.
  FolderNode({required this.name, List<FolderNode>? children})
    : this.children = children ?? <FolderNode>[];

  // 디버깅을 위한 toString 오버라이드
  @override
  String toString() {
    return 'FolderNode(name: $name, children: ${children.length} children)';
  }
}
