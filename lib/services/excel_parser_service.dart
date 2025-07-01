import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import '../models/folder_node.dart';

class ExcelParserService {
  Future<List<FolderNode>> parseExcel(String filePath) async {
    ByteData data;
    try {
      print('엑셀 파일 로드 시도: $filePath');
      data = await rootBundle.load(filePath);
      print('엑셀 파일 로드 성공 (바이트 길이: ${data.lengthInBytes})');
    } catch (e) {
      print('엑셀 파일 로드 실패: $e');
      return [];
    }

    var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    var excel = Excel.decodeBytes(bytes);

    List<FolderNode> rootFolders = [];

    if (excel.tables.isNotEmpty) {
      print('엑셀 시트 발견. 첫 번째 시트 이름: ${excel.tables.keys.first}');
      var sheet = excel.tables[excel.tables.keys.first];

      if (sheet != null) {
        print('시트 행 개수: ${sheet.rows.length}');

        Map<int, String> lastValidColumnValues = {}; // 각 컬럼별로 마지막 유효값 캐시

        for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
          // --- 이 부분에 첫 행을 건너뛰는 로직 추가 ---
          if (rowIndex == 0) {
            print('첫 번째 행 (헤더) 건너뛰기: $rowIndex');
            continue; // 첫 번째 행은 파싱하지 않고 다음 행으로 넘어갑니다.
          }
          // --- 여기까지 수정 ---

          var row = sheet.rows[rowIndex];
          if (row.isEmpty) {
            print('빈 행 건너뛰기: $rowIndex');
            continue;
          }
          print('처리 중인 행 $rowIndex: ${row.map((e) => e?.value).toList()}');

          Map<int, FolderNode> currentPathNodes = {}; // 현재 행에서 각 뎁스별 폴더 참조

          for (int i = 0; i < row.length; i++) {
            var cellValue = row[i]?.value;
            String currentCellValue = cellValue?.toString().trim() ?? '';

            String columnValue = currentCellValue;
            if (columnValue.isEmpty) {
              columnValue = lastValidColumnValues[i] ?? '';
            } else {
              lastValidColumnValues[i] = columnValue;
            }

            if (columnValue.isEmpty) {
              continue;
            }

            int currentDepth = (i ~/ 2) + 1;
            bool isKoreanColumn = (i % 2) != 0;

            if (isKoreanColumn) {
              String engValue = lastValidColumnValues[i - 1] ?? '';
              String korValue = columnValue;

              String effectiveFolderName;
              if (korValue.isNotEmpty && engValue.isNotEmpty) {
                effectiveFolderName = '$engValue\n$korValue';
              } else if (korValue.isNotEmpty) {
                effectiveFolderName = korValue;
              } else if (engValue.isNotEmpty) {
                effectiveFolderName = engValue;
              } else {
                continue;
              }

              print(
                '  셀 ($rowIndex, $i) - 뎁스 $currentDepth 최종 폴더 이름 결정: "$effectiveFolderName"',
              );

              List<FolderNode> targetChildrenList;
              if (currentDepth == 1) {
                targetChildrenList = rootFolders;
              } else {
                FolderNode? parentNode = currentPathNodes[currentDepth - 1];
                if (parentNode == null) {
                  print(
                    '  경고: 뎁스 ${currentDepth - 1}의 부모 폴더를 찾을 수 없습니다. (폴더: $effectiveFolderName)',
                  );
                  continue;
                }
                targetChildrenList = parentNode.children;
              }

              FolderNode? existingFolder;
              try {
                existingFolder = targetChildrenList.firstWhere(
                  (node) => node.name == effectiveFolderName,
                );
                print('  기존 폴더 발견: "$effectiveFolderName" (뎁스: $currentDepth)');
              } catch (e) {
                // 해당 이름의 폴더가 없으면 새로 생성
              }

              if (existingFolder == null) {
                var newFolder = FolderNode(name: effectiveFolderName);
                targetChildrenList.add(newFolder);
                print('  새 폴더 추가됨: "$effectiveFolderName" (뎁스: $currentDepth)');
                currentPathNodes[currentDepth] = newFolder;
              } else {
                currentPathNodes[currentDepth] = existingFolder;
              }
            } else {
              print('  ENGn 컬럼 ($columnValue)은 KORn 컬럼에서 통합 처리될 예정입니다.');
            }
          }
        }
      } else {
        print('첫 번째 시트가 null 입니다.');
      }
    } else {
      print('엑셀 파일에 시트가 없습니다.');
    }

    print('최종 파싱된 루트 폴더 구조:');
    _printFolderStructure(rootFolders);
    return rootFolders;
  }

  void _printFolderStructure(List<FolderNode> nodes, {int depth = 0}) {
    for (var node in nodes) {
      print('${'  ' * depth}- ${node.name.replaceAll('\n', ' / ')}');
      if (node.children.isNotEmpty) {
        _printFolderStructure(node.children, depth: depth + 1);
      }
    }
  }
}
