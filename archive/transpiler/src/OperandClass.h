// OperandClass: classifies a Clang Expr as Quantum or Classical for the
// mixed-operand rewrite rule. An expression is Quantum iff (after
// stripping ParenExpr / ImplicitCastExpr layers) it is a DeclRefExpr to
// a quantum-annotated VarDecl. Everything else — literals, references
// to classical variables, function calls, binary operators, etc. — is
// Classical. The classifier returns both the OperandKind and the
// unwrapped Expr* so callers (e.g. codegen) can splice the underlying
// expression text directly.
#pragma once

namespace clang {
class Expr;
}  // namespace clang

namespace qct {

enum class OperandKind { Quantum, Classical };

struct OperandInfo {
    OperandKind kind;
    const clang::Expr *expr;  // The unwrapped expression (Paren/ImplicitCast stripped)
};

// Classify `e` as Quantum or Classical. Quantum iff `e` (after
// unwrapping ParenExpr and ImplicitCastExpr layers) is a DeclRefExpr
// to a quantum-annotated VarDecl. All other expressions — literals,
// classical-var references, function calls, binops, etc. — are
// Classical. Null `e` → Classical with `expr == nullptr`.
OperandInfo classify(const clang::Expr *e);

// Classify the left-hand side of an assignment (BinaryOperator with
// opcode BO_Assign, or any CompoundAssignOperator). The LHS is
// Quantum iff `e` (after peeling ParenExpr/ImplicitCastExpr layers)
// is a DeclRefExpr to a quantum-annotated VarDecl. Semantically this
// distinguishes Patterns 7 (`q = …`) and 8 (`q += …`): a quantum LHS
// must be rewritten to `q.val = …` so the mid-handle's payload is
// updated rather than its handle being aliased. The predicate is the
// same as `classify` — the helper exists so call sites read as
// "classify the assignment LHS" rather than "classify some Expr".
// Null `e` → Classical with `expr == nullptr`.
OperandInfo classifyAssignLHS(const clang::Expr *e);

// Classify the operand of a UnaryOperator (Pattern 9: `-q`, `~q`,
// `!q`, `++q`, `q++`, etc.). Quantum iff `e` (after peeling layers)
// is a DeclRefExpr to a quantum-annotated VarDecl. A quantum unary
// operand routes to `UnaryCodegen`, which materializes `b.val =
// -a.val;` (etc.); a classical operand falls through to stock C
// emission. Predicate matches `classify` / `classifyAssignLHS`; the
// distinct entry point keeps codegen call sites self-documenting and
// gives us a single seam if unary classification ever needs to
// diverge (e.g. excluding `!` for floating-point quantum operands).
// Null `e` → Classical with `expr == nullptr`.
OperandInfo classifyUnaryOperand(const clang::Expr *e);

}  // namespace qct
