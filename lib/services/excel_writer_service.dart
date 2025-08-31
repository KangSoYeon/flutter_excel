import 'package:excel/excel.dart';
import '../models/folder_node.dart';

class ExcelWriterService {
  Future<List<int>?> generateExcelBytes(
      List<FolderNode> rootFolders) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    // Add header row - pass strings directly
    sheet.appendRow([
      'ENG1',
      'KOR1',
      'ENG2',
      'KOR2',
      'ENG3',
      'KOR3',
      'ENG4',
      'KOR4',
    ]);

    int rowIndex = 1;
    for (var node in rootFolders) {
      rowIndex = _writeNode(node, rowIndex, 0, sheet, List.filled(8, null));
    }

    // Return the file bytes
    return excel.save();
  }

  // Use List<Object?> instead of List<CellValue?>
  int _writeNode(FolderNode node, int currentRow, int level,
      Sheet sheet, List<Object?> parentRowData) {
    List<Object?> newRowData = List.from(parentRowData);

    // Split name by newline. First line to ENG, second to KOR.
    // If no newline, all goes to KOR.
    final parts = node.name.split('\n');
    String engName = '';
    String korName = '';

    if (parts.length > 1) {
      engName = parts[0];
      korName = parts.sublist(1).join('\n');
    } else {
      korName = node.name;
    }

    int engCol = level * 2;
    int korCol = level * 2 + 1;

    if (engCol < newRowData.length) {
      newRowData[engCol] = engName; // Assign string directly
    }
    if (korCol < newRowData.length) {
      newRowData[korCol] = korName; // Assign string directly
    }

    // If there are no children, this is a leaf, so write the row.
    if (node.children.isEmpty) {
      sheet.appendRow(newRowData);
      return currentRow + 1;
    } else {
      // If there are children, recursively write them
      int nextRow = currentRow;
      for (var child in node.children) {
        nextRow = _writeNode(child, nextRow, level + 1, sheet, newRowData);
      }
      return nextRow;
    }
  }
}