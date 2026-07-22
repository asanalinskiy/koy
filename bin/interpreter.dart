import 'dart:async';
import 'ast.dart';
import 'signal.dart';

class Environment {
  final Environment? enclosing;
  final Map<String, dynamic> _values = {};

  Environment([this.enclosing]);

  void define(String name, dynamic value) {
    _values[name] = value;
  }

  dynamic get(String name) {
    if (_values.containsKey(name)) {
      return _values[name];
    }
    if (enclosing != null) {
      return enclosing!.get(name);
    }
    throw 'Неопределенная переменная "$name".';
  }

  void assign(String name, dynamic value) {
    if (_values.containsKey(name)) {
      _values[name] = value;
      return;
    }
    if (enclosing != null) {
      enclosing!.assign(name, value);
      return;
    }
    throw 'Неопределенная переменная "$name".';
  }
}

class KoyFunction {
  final FunctionDeclStmt declaration;
  final Environment closure;

  KoyFunction(this.declaration, this.closure);

  Future<dynamic> call(KoyInterpreter interpreter, List<dynamic> arguments) async {
    Environment environment = Environment(closure);
    for (int i = 0; i < declaration.params.length; i++) {
      environment.define(declaration.params[i], arguments[i]);
    }

    try {
      await interpreter.executeBlock(declaration.body.statements, environment);
    } on ReturnValue catch (returnValue) {
      return returnValue.value;
    }
    return null;
  }
}

class ReturnValue {
  final dynamic value;
  ReturnValue(this.value);
}

// Google Apps Script Моки / Встроенные API
class KoyLogger {
  void log(dynamic message) {
    print('[Koy Logger] $message');
  }
}

class KoyUrlFetchApp {
  Future<Map<String, dynamic>> fetch(String url) async {
    print('[UrlFetchApp] Запрос к GET $url ...');
    await Future.delayed(Duration(milliseconds: 300));
    return {
      'status': 200,
      'body': '{"id": 101, "title": "Koy Power"}',
      'json': () => {'id': 101, 'title': 'Koy Power'}
    };
  }
}

class KoySpreadsheet {
  final String name;
  KoySpreadsheet(this.name);

  KoySheet getSheetByName(String sheetName) {
    return KoySheet(sheetName);
  }
}

class KoySheet {
  final String name;
  KoySheet(this.name);

  void appendRow(List<dynamic> row) {
    print('[SpreadsheetApp -> $name] Добавлена строка: $row');
  }
}

class KoySpreadsheetApp {
  KoySpreadsheet getActiveSpreadsheet() {
    return KoySpreadsheet("MainSpreadsheet");
  }
}

class KoyInterpreter {
  final Environment globals = Environment();
  late Environment _environment;

  KoyInterpreter() {
    _environment = globals;
    // Регистрируем встроенные Apps Script библиотеки
    globals.define('Logger', KoyLogger());
    globals.define('UrlFetchApp', KoyUrlFetchApp());
    globals.define('SpreadsheetApp', KoySpreadsheetApp());
    globals.define('DateTime', {
      'now': () => DateTime.now().toIso8601String()
    });
  }

  Future<void> interpret(List<Stmt> statements) async {
    try {
      for (Stmt stmt in statements) {
        await _execute(stmt);
      }
    } catch (error) {
      print('Ошибка выполнения Koy: $error');
    }
  }

  Future<void> _execute(Stmt stmt) async {
    if (stmt is VarDeclStmt) {
      dynamic value;
      if (stmt.initializer != null) {
        value = await _evaluate(stmt.initializer!);
      }
      if (stmt.isSignal) {
        _environment.define(stmt.name, KoySignal(value));
      } else {
        _environment.define(stmt.name, value);
      }
    } else if (stmt is ExpressionStmt) {
      await _evaluate(stmt.expression);
    } else if (stmt is BlockStmt) {
      await executeBlock(stmt.statements, Environment(_environment));
    } else if (stmt is IfStmt) {
      dynamic cond = await _evaluate(stmt.condition);
      if (_isTruthy(cond)) {
        await _execute(stmt.thenBranch);
      } else if (stmt.elseBranch != null) {
        await _execute(stmt.elseBranch!);
      }
    } else if (stmt is FunctionDeclStmt) {
      KoyFunction function = KoyFunction(stmt, _environment);
      _environment.define(stmt.name, function);
    } else if (stmt is ReturnStmt) {
      dynamic value;
      if (stmt.value != null) {
        value = await _evaluate(stmt.value!);
      }
      throw ReturnValue(value);
    }
  }

  Future<void> executeBlock(List<Stmt> statements, Environment environment) async {
    Environment previous = _environment;
    try {
      _environment = environment;
      for (Stmt statement in statements) {
        await _execute(statement);
      }
    } finally {
      _environment = previous;
    }
  }

  Future<dynamic> _evaluate(Expr expr) async {
    if (expr is LiteralExpr) {
      return expr.value;
    } else if (expr is VariableExpr) {
      return _environment.get(expr.name);
    } else if (expr is BinaryExpr) {
      if (expr.operator == '=') {
        dynamic val = await _evaluate(expr.right);
        if (expr.left is VariableExpr) {
          String varName = (expr.left as VariableExpr).name;
          dynamic target = _environment.get(varName);
          if (target is KoySignal) {
            target.value = val;
          } else {
            _environment.assign(varName, val);
          }
        }
        return val;
      }

      dynamic left = await _evaluate(expr.left);
      dynamic right = await _evaluate(expr.right);

      switch (expr.operator) {
        case '+': return left + right;
        case '-': return left - right;
        case '*': return left * right;
        case '/': return left / right;
        case '==': return left == right;
        case '!=': return left != right;
        case '>': return left > right;
        case '<': return left < right;
      }
    } else if (expr is GetExpr) {
      dynamic object = await _evaluate(expr.object);
      if (object is KoySignal) {
        if (expr.name == 'value') return object.value;
        // ✅ СТАЛО:
if (expr.name == 'listen') return (void Function(dynamic) callback) => object.listen(callback);
      }
      if (object is Map && object.containsKey(expr.name)) {
        return object[expr.name];
      }
      // Доступ к методу/свойству объекта Dart
      return _getNativeProperty(object, expr.name);
    } else if (expr is SetExpr) {
      dynamic object = await _evaluate(expr.object);
      dynamic value = await _evaluate(expr.value);
      if (object is KoySignal && expr.name == 'value') {
        object.value = value;
        return value;
      }
      throw 'Нельзя установить свойство ${expr.name}';
    } else if (expr is CallExpr) {
      dynamic callee = await _evaluate(expr.callee);
      List<dynamic> args = [];
      for (Expr arg in expr.arguments) {
        args.add(await _evaluate(arg));
      }

      if (callee is KoyFunction) {
        return await callee.call(this, args);
      } else if (callee is Function) {
        return Function.apply(callee, args);
      } else if (callee is KoyMethodBinding) {
        return await callee.invoke(args);
      }
      throw 'Вызываемый объект не является функцией.';
    } else if (expr is AwaitExpr) {
      dynamic val = await _evaluate(expr.value);
      if (val is Future) {
        return await val;
      }
      return val;
    } else if (expr is ListExpr) {
      List<dynamic> list = [];
      for (Expr e in expr.elements) {
        list.add(await _evaluate(e));
      }
      return list;
    }
    return null;
  }

  dynamic _getNativeProperty(dynamic object, String name) {
    if (object is KoyLogger) {
      if (name == 'log') return (dynamic msg) => object.log(msg);
    } else if (object is KoyUrlFetchApp) {
      if (name == 'fetch') return (String url) => object.fetch(url);
    } else if (object is KoySpreadsheetApp) {
      if (name == 'getActiveSpreadsheet') return () => object.getActiveSpreadsheet();
    } else if (object is KoySpreadsheet) {
      if (name == 'getSheetByName') return (String sName) => object.getSheetByName(sName);
    } else if (object is KoySheet) {
      if (name == 'appendRow') return (List row) => object.appendRow(row);
    }
    throw 'Свойство "$name" не найдено в объекте $object.';
  }

  bool _isTruthy(dynamic object) {
    if (object == null) return false;
    if (object is bool) return object;
    return true;
  }
}

class KoyMethodBinding {
  final dynamic target;
  final String methodName;
  KoyMethodBinding(this.target, this.methodName);

  Future<dynamic> invoke(List<dynamic> args) async {
    return null;
  }
}
