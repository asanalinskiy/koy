import 'token.dart';

class KoyLexer {
  final String source;
  final List<Token> tokens = [];
  int _start = 0;
  int _current = 0;
  int _line = 1;

  static final Map<String, TokenType> _keywords = {
    'var': TokenType.kwVar,
    'signal': TokenType.kwSignal,
    'async': TokenType.kwAsync,
    'void': TokenType.kwVoid,
    'await': TokenType.kwAwait,
    'if': TokenType.kwIf,
    'else': TokenType.kwElse,
    'while': TokenType.kwWhile,
    'return': TokenType.kwReturn,
    'true': TokenType.booleanLiteral,
    'false': TokenType.booleanLiteral,
  };

  KoyLexer(this.source);

  List<Token> scanTokens() {
    while (!_isAtEnd()) {
      _start = _current;
      _scanToken();
    }

    tokens.add(Token(TokenType.eof, '', null, _line));
    return tokens;
  }

  bool _isAtEnd() => _current >= source.length;

  void _scanToken() {
    char c = _advance();
    switch (c) {
      case '(': _addToken(TokenType.lParen); break;
      case ')': _addToken(TokenType.rParen); break;
      case '{': _addToken(TokenType.lBrace); break;
      case '}': _addToken(TokenType.rBrace); break;
      case '[': _addToken(TokenType.lBracket); break;
      case ']': _addToken(TokenType.rBracket); break;
      case ',': _addToken(TokenType.comma); break;
      case '.': _addToken(TokenType.dot); break;
      case ';': _addToken(TokenType.semicolon); break;
      case '+': _addToken(TokenType.plus); break;
      case '-': _addToken(TokenType.minus); break;
      case '*': _addToken(TokenType.star); break;
      case '=':
        _addToken(_match('=') ? TokenType.equal : TokenType.assign);
        break;
      case '!':
        if (_match('=')) {
          _addToken(TokenType.notEqual);
        } else {
          // Unexpected char
        }
        break;
      case '>': _addToken(TokenType.greater); break;
      case '<': _addToken(TokenType.less); break;
      case '/':
        if (_match('/')) {
          // // комментарий на Koy
          while (_peek() != '\n' && !_isAtEnd()) {
            _advance();
          }
          String commentText = source.substring(_start, _current);
          tokens.add(Token(TokenType.comment, commentText, commentText, _line));
        } else {
          _addToken(TokenType.slash);
        }
        break;
      case ' ':
      case '\r':
      case '\t':
        break;
      case '\n':
        _line++;
        break;
      case '"':
        _string();
        break;
      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          print('Error on line $_line: Unexpected character "$c"');
        }
        break;
    }
  }

  char _advance() => source[_current++];

  bool _match(char expected) {
    if (_isAtEnd()) return false;
    if (source[_current] != expected) return false;
    _current++;
    return true;
  }

  char _peek() => _isAtEnd() ? '\0' : source[_current];

  void _addToken(TokenType type, [dynamic literal]) {
    String text = source.substring(_start, _current);
    tokens.add(Token(type, text, literal, _line));
  }

  void _string() {
    while (_peek() != '"' && !_isAtEnd()) {
      if (_peek() == '\n') _line++;
      _advance();
    }

    if (_isAtEnd()) {
      print('Error on line $_line: Unterminated string.');
      return;
    }

    _advance(); // Closing "
    String value = source.substring(_start + 1, _current - 1);
    _addToken(TokenType.stringLiteral, value);
  }

  void _number() {
    while (_isDigit(_peek())) _advance();

    if (_peek() == '.' && _isDigit(_peekNext())) {
      _advance(); // consume '.'
      while (_isDigit(_peek())) _advance();
    }

    dynamic val = double.parse(source.substring(_start, _current));
    if (val == val.toInt()) {
      val = val.toInt();
    }
    _addToken(TokenType.numberLiteral, val);
  }

  char _peekNext() {
    if (_current + 1 >= source.length) return '\0';
    return source[_current + 1];
  }

  void _identifier() {
    while (_isAlphaNumeric(_peek())) _advance();

    String text = source.substring(_start, _current);
    TokenType type = _keywords[text] ?? TokenType.identifier;
    
    dynamic literal;
    if (type == TokenType.booleanLiteral) {
      literal = (text == 'true');
    }
    _addToken(type, literal);
  }

  bool _isDigit(char c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  bool _isAlpha(char c) {
    int code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
           (code >= 97 && code <= 122) ||
           c == '_';
  }

  bool _isAlphaNumeric(char c) => _isAlpha(c) || _isDigit(c);
}

typedef char = String;
