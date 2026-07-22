import 'ast.dart';
import 'token.dart';

class KoyParser {
  final List<Token> tokens;
  int _current = 0;

  KoyParser(this.tokens);

  List<Stmt> parse() {
    List<Stmt> statements = [];
    while (!_isAtEnd()) {
      if (_match([TokenType.comment])) continue; // Игнорируем комментарии
      statements.add(_declaration());
    }
    return statements;
  }

  Stmt _declaration() {
    if (_check(TokenType.kwAsync) || _check(TokenType.kwVoid) || (_check(TokenType.identifier) && _peekNext().type == TokenType.identifier)) {
      if (_lookAheadIsFunction()) {
        return _functionDeclaration();
      }
    }
    if (_match([TokenType.kwVar])) return _varDeclaration(isSignal: false);
    if (_match([TokenType.kwSignal])) return _varDeclaration(isSignal: true);
    return _statement();
  }

  bool _lookAheadIsFunction() {
    int temp = _current;
    if (tokens[temp].type == TokenType.kwAsync) temp++;
    if (tokens[temp].type == TokenType.kwVoid || tokens[temp].type == TokenType.identifier) temp++;
    return temp < tokens.length && tokens[temp].type == TokenType.identifier && temp + 1 < tokens.length && tokens[temp + 1].type == TokenType.lParen;
  }

  Stmt _functionDeclaration() {
    bool isAsync = _match([TokenType.kwAsync]);
    if (_match([TokenType.kwVoid])) {} else {
      _match([TokenType.identifier]); // Игнорируем возвращаемый тип для динамической типизации
    }

    Token nameToken = _consume(TokenType.identifier, 'Ожидается имя функции.');
    _consume(TokenType.lParen, 'Ожидается "(" после имени функции.');

    List<String> params = [];
    if (!_check(TokenType.rParen)) {
      do {
        // Опциональный тип параметра
        if (_check(TokenType.identifier) && _peekNext().type == TokenType.identifier) {
          _advance();
        }
        Token param = _consume(TokenType.identifier, 'Ожидается имя параметра.');
        params.add(param.lexeme);
      } while (_match([TokenType.comma]));
    }
    _consume(TokenType.rParen, 'Ожидается ")" после параметров.');

    _consume(TokenType.lBrace, 'Ожидается "{" перед телом функции.');
    BlockStmt body = _block();

    return FunctionDeclStmt(nameToken.lexeme, params, body, isAsync: isAsync);
  }

  Stmt _varDeclaration({required bool isSignal}) {
    Token name = _consume(TokenType.identifier, 'Ожидается имя переменной.');

    Expr? initializer;
    if (_match([TokenType.assign])) {
      initializer = _expression();
    }

    _consume(TokenType.semicolon, 'Ожидается ";" после объявления переменной.');
    return VarDeclStmt(name.lexeme, initializer, isSignal: isSignal);
  }

  Stmt _statement() {
    if (_match([TokenType.kwIf])) return _ifStatement();
    if (_match([TokenType.kwReturn])) return _returnStatement();
    if (_match([TokenType.lBrace])) return _block();

    return _expressionStatement();
  }

  Stmt _ifStatement() {
    _consume(TokenType.lParen, 'Ожидается "(" после "if".');
    Expr condition = _expression();
    _consume(TokenType.rParen, 'Ожидается ")" после условия if.');

    Stmt thenBranch = _statement();
    Stmt? elseBranch;
    if (_match([TokenType.kwElse])) {
      elseBranch = _statement();
    }

    return IfStmt(condition, thenBranch, elseBranch);
  }

  Stmt _returnStatement() {
    Expr? value;
    if (!_check(TokenType.semicolon)) {
      value = _expression();
    }
    _consume(TokenType.semicolon, 'Ожидается ";" после return.');
    return ReturnStmt(value);
  }

  BlockStmt _block() {
    List<Stmt> statements = [];
    while (!_check(TokenType.rBrace) && !_isAtEnd()) {
      if (_match([TokenType.comment])) continue;
      statements.add(_declaration());
    }
    _consume(TokenType.rBrace, 'Ожидается "}" после блока.');
    return BlockStmt(statements);
  }

  Stmt _expressionStatement() {
    Expr expr = _expression();
    _consume(TokenType.semicolon, 'Ожидается ";" после выражения.');
    return ExpressionStmt(expr);
  }

  Expr _expression() {
    return _assignment();
  }

  Expr _assignment() {
    Expr expr = _equality();

    if (_match([TokenType.assign])) {
      Expr value = _assignment();

      if (expr is VariableExpr) {
        return BinaryExpr(expr, '=', value);
      } else if (expr is GetExpr) {
        return SetExpr(expr.object, expr.name, value);
      }
      throw 'Недопустимая цель присваивания.';
    }

    return expr;
  }

  Expr _equality() {
    Expr expr = _comparison();
    while (_match([TokenType.equal, TokenType.notEqual])) {
      Token op = _previous();
      Expr right = _comparison();
      expr = BinaryExpr(expr, op.lexeme, right);
    }
    return expr;
  }

  Expr _comparison() {
    Expr expr = _term();
    while (_match([TokenType.greater, TokenType.less])) {
      Token op = _previous();
      Expr right = _term();
      expr = BinaryExpr(expr, op.lexeme, right);
    }
    return expr;
  }

  Expr _term() {
    Expr expr = _factor();
    while (_match([TokenType.plus, TokenType.minus])) {
      Token op = _previous();
      Expr right = _factor();
      expr = BinaryExpr(expr, op.lexeme, right);
    }
    return expr;
  }

  Expr _factor() {
    Expr expr = _unary();
    while (_match([TokenType.star, TokenType.slash])) {
      Token op = _previous();
      Expr right = _unary();
      expr = BinaryExpr(expr, op.lexeme, right);
    }
    return expr;
  }

  Expr _unary() {
    if (_match([TokenType.kwAwait])) {
      return AwaitExpr(_unary());
    }
    return _call();
  }

  Expr _call() {
    Expr expr = _primary();

    while (true) {
      if (_match([TokenType.lParen])) {
        expr = _finishCall(expr);
      } else if (_match([TokenType.dot])) {
        Token name = _consume(TokenType.identifier, 'Ожидается имя свойства после ".".');
        expr = GetExpr(expr, name.lexeme);
      } else {
        break;
      }
    }

    return expr;
  }

  Expr _finishCall(Expr callee) {
    List<Expr> arguments = [];
    if (!_check(TokenType.rParen)) {
      do {
        arguments.add(_expression());
      } while (_match([TokenType.comma]));
    }
    _consume(TokenType.rParen, 'Ожидается ")" после аргументов.');
    return CallExpr(callee, arguments);
  }

  Expr _primary() {
    if (_match([TokenType.booleanLiteral, TokenType.numberLiteral, TokenType.stringLiteral])) {
      return LiteralExpr(_previous().literal);
    }
    if (_match([TokenType.identifier])) {
      return VariableExpr(_previous().lexeme);
    }
    if (_match([TokenType.lParen])) {
      Expr expr = _expression();
      _consume(TokenType.rParen, 'Ожидается ")" после выражения.');
      return expr;
    }
    if (_match([TokenType.lBracket])) {
      List<Expr> elements = [];
      if (!_check(TokenType.rBracket)) {
        do {
          elements.add(_expression());
        } while (_match([TokenType.comma]));
      }
      _consume(TokenType.rBracket, 'Ожидается "]" после списка.');
      return ListExpr(elements);
    }

    throw 'Ожидается выражение на токене ${_peek().lexeme}.';
  }

  bool _match(List<TokenType> types) {
    for (TokenType type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  bool _isAtEnd() => _peek().type == TokenType.eof;
  Token _peek() => tokens[_current];
  Token _peekNext() => _current + 1 < tokens.length ? tokens[_current + 1] : tokens.last;
  Token _previous() => tokens[_current - 1];

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw 'Ошибка синтаксиса: $message (Получен ${_peek().lexeme})';
  }
}
