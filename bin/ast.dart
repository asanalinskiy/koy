abstract class ASTNode {}

// --- Выражения (Expressions) ---
abstract class Expr extends ASTNode {}

class LiteralExpr extends Expr {
  final dynamic value;
  LiteralExpr(this.value);
}

class VariableExpr extends Expr {
  final String name;
  VariableExpr(this.name);
}

class BinaryExpr extends Expr {
  final Expr left;
  final String operator;
  final Expr right;
  BinaryExpr(this.left, this.operator, this.right);
}

class CallExpr extends Expr {
  final Expr callee;
  final List<Expr> arguments;
  CallExpr(this.callee, this.arguments);
}

class GetExpr extends Expr {
  final Expr object;
  final String name;
  GetExpr(this.object, this.name);
}

class SetExpr extends Expr {
  final Expr object;
  final String name;
  final Expr value;
  SetExpr(this.object, this.name, this.value);
}

class AwaitExpr extends Expr {
  final Expr value;
  AwaitExpr(this.value);
}

class ListExpr extends Expr {
  final List<Expr> elements;
  ListExpr(this.elements);
}

class MapExpr extends Expr {
  final Map<Expr, Expr> entries;
  MapExpr(this.entries);
}

// --- Инструкции (Statements) ---
abstract class Stmt extends ASTNode {}

class ExpressionStmt extends Stmt {
  final Expr expression;
  ExpressionStmt(this.expression);
}

class VarDeclStmt extends Stmt {
  final String name;
  final Expr? initializer;
  final bool isSignal;
  VarDeclStmt(this.name, this.initializer, {this.isSignal = false});
}

class BlockStmt extends Stmt {
  final List<Stmt> statements;
  BlockStmt(this.statements);
}

class IfStmt extends Stmt {
  final Expr condition;
  final Stmt thenBranch;
  final Stmt? elseBranch;
  IfStmt(this.condition, this.thenBranch, this.elseBranch);
}

class FunctionDeclStmt extends Stmt {
  final String name;
  final List<String> params;
  final BlockStmt body;
  final bool isAsync;
  FunctionDeclStmt(this.name, this.params, this.body, {this.isAsync = false});
}

class ReturnStmt extends Stmt {
  final Expr? value;
  ReturnStmt(this.value);
}
