import 'dart:io';
import 'lexer.dart';
import 'parser.dart';
import 'interpreter.dart';

void main(List<String> args) async {
  // 1. Проверяем, передан ли путь к .koy файлу через аргументы командной строки
  if (args.isEmpty) {
    print('Использование: koy <путь_к_файлу.koy>');
    print('Пример: dart run bin/main.dart script.koy');
    exit(64);
  }

  String filePath = args[0];
  File file = File(filePath);

  // 2. Проверяем существование файла
  if (!await file.exists()) {
    print('Ошибка: Файл "$filePath" не найден.');
    exit(66);
  }

  // 3. Считываем содержимое .koy файла
  String koyCode = await file.readAsString();

  try {
    // Лексический анализ (Lexer)
    KoyLexer lexer = KoyLexer(koyCode);
    var tokens = lexer.scanTokens();

    // Синтаксический анализ (Parser)
    KoyParser parser = KoyParser(tokens);
    var ast = parser.parse();

    // Выполнение кода (Interpreter)
    KoyInterpreter interpreter = KoyInterpreter();
    await interpreter.interpret(ast);
  } catch (e) {
    print('Ошибка выполнения файла $filePath:\n$e');
  }
}