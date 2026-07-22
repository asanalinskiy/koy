enum TokenType {
  // Keywords
  kwVar,
  kwSignal,
  kwAsync,
  kwVoid,
  kwAwait,
  kwIf,
  kwElse,
  kwWhile,
  kwReturn,
  
  // Literals & Identifiers
  identifier,
  stringLiteral,
  numberLiteral,
  booleanLiteral,

  // Operators & Symbols
  assign,          // =
  plus,            // +
  minus,           // -
  star,            // *
  slash,           // /
  equal,           // ==
  notEqual,        // !=
  greater,         // >
  less,            // <
  dot,             // .
  comma,           // ,
  semicolon,       // ;
  lParen,          // (
  rParen,          // )
  lBrace,          // {
  rBrace,          // }
  lBracket,        // [
  rBracket,        // ]

  comment,
  eof
}

class Token {
  final TokenType type;
  final String lexeme;
  final dynamic literal;
  final int line;

  Token(this.type, this.lexeme, this.literal, this.line);

  @override
  String toString() => 'Token($type, "$lexeme", $literal, line $line)';
}
