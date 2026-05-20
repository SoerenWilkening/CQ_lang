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

}  // namespace qct
