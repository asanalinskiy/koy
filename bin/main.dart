import 'dart:io';
import 'lexer.dart';
import 'parser.dart';
import 'interpreter.dart';

void main(List<String> args) async {
  KoyInterpreter interpreter = KoyInterpreter();

  // ==========================================
  // 1. РЕЖИМ ИНТЕРАКТИВНОГО ТЕРМИНАЛА (REPL)
  // (Запускается, если аргументы не переданы)
  // ==========================================
  if (args.isEmpty) {
    // Красивый стилизованный баннер Koy
    print('\x1B[36m========================================\x1B[0m');
    print('\x1B[33m   Koy Programming Language v1.0.0      \x1B[0m');
    print('\x1B[36m========================================\x1B[0m');
    print('Type "exit()" to quit. Happy coding!\n');

    while (true) {
      // Зеленый промпт koy>
      stdout.write('\x1B[32mkoy>\x1B[0m ');
      String? line = stdin.readLineSync();

      // Выход из терминала
      if (line == null || line.trim() == 'exit()') {
        print('Goodbye!');
        break;
      }

      // Пропускаем пустые строки
      if (line.trim().isEmpty) continue;

      // Выполнение введенной строки
      try {
        KoyLexer lexer = KoyLexer(line);
        var tokens = lexer.scanTokens();

        KoyParser parser = KoyParser(tokens);
        var ast = parser.parse();

        await interpreter.interpret(ast);
      } catch (e) {
        print('\x1B[31mError:\x1B[0m $e');
      }
    }
    return;
  }

  // ==========================================
  // 2. РЕЖИМ ВЫПОЛНЕНИЯ ФАЙЛА (koy file.koy)
  // ==========================================
  String filePath = args[0];
  File file = File(filePath);

  if (!await file.exists()) {
    print('\x1B[31mError:\x1B[0m File "$filePath" not found.');
    exit(66);
  }

  String koyCode = await file.readAsString();

  try {
    KoyLexer lexer = KoyLexer(koyCode);
    var tokens = lexer.scanTokens();

    KoyParser parser = KoyParser(tokens);
    var ast = parser.parse();

    await interpreter.interpret(ast);
  } catch (e) {
    print('\x1B[31mError in $filePath:\x1B[0m\n$e');
  }
}