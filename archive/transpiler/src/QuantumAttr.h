// QuantumAttr: thin predicates over Clang AST nodes used to decide
// whether a VarDecl (or the variable referenced by an expression) was
// annotated as `quantum` via `__attribute__((annotate("quantum")))`.
// Keeping these predicates in a dedicated module makes the rewrite
// logic readable and gives us a single place to evolve the marker
// convention if it ever changes.
#pragma once

namespace clang {
class VarDecl;
class Expr;
}  // namespace clang

namespace qct {

// True iff `vd` is non-null and carries an `AnnotateAttr` whose
// annotation string equals exactly "quantum".
bool hasQuantumAttr(const clang::VarDecl *vd);

// True iff `e` (after unwrapping ParenExpr and ImplicitCastExpr layers)
// is a DeclRefExpr that refers to a quantum-annotated VarDecl. Returns
// false for null inputs and for any expression that does not bottom
// out at a DeclRefExpr-to-VarDecl.
bool refersToQuantumVar(const clang::Expr *e);

}  // namespace qct
