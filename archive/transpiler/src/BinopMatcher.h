// BinopMatcher: recognizes a binary operator on quantum operand(s) and
// returns a structured match result for the rewriter / codegen path.
//
// In Phase 2, the binop recognition (dyn_cast to BinaryOperator, opcode
// check, LHS/RHS classification) was inlined inside
// `DeclStmtRewrite::populateFromInit`. Phase 3 M7 hoists that
// recognition out into a dedicated module so the same predicate can be
// reused by AssignMatcher (for the `a = a + b;` shape, where the
// initializer of the assignment is itself a binop) and so the split
// keeps each file under its 300-LOC ceiling.
//
// Scope:
//   - Phase 2 surface: BO_Add only — the current rewriter recognizes
//     exactly one opcode. Phase 3 M11 extends the IR-pass dispatch to
//     the full binary-opcode surface; the rewriter-side BinopMatcher
//     stays opcode-aware (carrying the BinaryOperatorKind in the
//     result) so a future widening here is a pure data-shape addition.
//   - The matcher is operator-agnostic in shape: it returns the opcode
//     in the result and lets the caller decide which opcodes are valid.
//
// Mixed-operand handling:
//   - Both LHS and RHS are classified through `OperandClass::classify`,
//     i.e. they are peeled through ParenExpr / ImplicitCastExpr and
//     reported as Quantum or Classical with the unwrapped Expr*.
//   - At least one side must be Quantum for the binop to be a quantum
//     rewrite candidate; if both sides are classical the binop is
//     irrelevant to the rewriter (it'll splice through ClassicalInit).
//
// Codegen consumes only the match result — never the original
// BinaryOperator node — so this layer is the seam between
// AST recognition and emission. M8 (Codegen split) plugs into this
// API; M7 (this issue) only produces results and adds unit tests.
#pragma once
#
#include <clang/AST/OperationKinds.h>

#include "OperandClass.h"

namespace clang {
class Expr;
}  // namespace clang

namespace qct {

// Result of attempting to recognize a binary operator on quantum
// operand(s). `matched == false` means the Expr was not a
// BinaryOperator we care about (either not a BinaryOperator at all, or
// neither operand was quantum). When `matched == true`, `opcode` holds
// the Clang BinaryOperatorKind, and `lhs` / `rhs` hold the classified
// operand sides (already peeled through paren/cast layers — see
// OperandInfo).
struct BinopMatch {
    bool matched;
    clang::BinaryOperatorKind opcode;
    OperandInfo lhs;
    OperandInfo rhs;
};

// Attempt to recognize `e` as a binary operator on quantum operand(s).
// The matcher peels at most no wrappers itself — the caller is expected
// to hand in an already-unwrapped Expr (in line with how
// DeclStmtRewrite calls `populateFromInit`, which strips
// ParenExpr/ImplicitCastExpr layers before dispatch). If `e` is not a
// BinaryOperator, returns `BinopMatch{false, …}`.
//
// Operator-agnostic in shape: the predicate is "Expr is a binop AND at
// least one operand is quantum". The caller is responsible for
// filtering by opcode (e.g. Phase 2's BO_Add gate). This keeps M7's
// matcher reusable when Phase 3 M11/M12 widens the opcode surface in
// the IR pass without forcing the rewriter to re-decide its scope on
// each opcode landing.
BinopMatch matchBinop(const clang::Expr *e);

}  // namespace qct
