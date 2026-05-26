// UnaryMatcher: recognizes UnaryOperator expressions whose operand is a
// quantum-annotated VarDecl reference. Covers PRD Pattern 9, the full
// set of seven unary opcodes Phase 3 must handle on a quantum operand:
//
//   UO_Minus    — `-q`     arithmetic negate (int / fp)
//   UO_Not      — `~q`     bitwise NOT (int)
//   UO_LNot     — `!q`     logical NOT (yields i1; surface-level only
//                          — IR lowering goes through icmp eq 0)
//   UO_PreInc   — `++q`    prefix increment
//   UO_PostInc  — `q++`    postfix increment
//   UO_PreDec   — `--q`    prefix decrement
//   UO_PostDec  — `q--`    postfix decrement
//
// UO_Plus (`+q`) is intentionally not in this list: clang folds it away
// before the rewriter sees it on integer/fp operands (the AST node still
// exists for completeness but the operator is a no-op). If a future
// Phase needs `+q`, add it here and the LIT/e2e fixtures.
//
// The matcher returns the opcode and the classified operand. Codegen
// (M8) uses `opcode` to dispatch to the right emission shape:
//   - UO_Minus / UO_Not / UO_LNot — pure expression, no side effect.
//     Output shape: `<dest>.val = -<src>.val;`
//   - UO_PreInc / UO_PreDec — side effect THEN value.
//     Output shape: `<src>.val += 1; <dest>.val = <src>.val;`
//   - UO_PostInc / UO_PostDec — value THEN side effect.
//     Output shape: `<dest>.val = <src>.val; <src>.val += 1;`
//
// M7 (this issue) only produces results and adds unit tests; M8 owns
// the emission wiring.
#pragma once
#
#include <clang/AST/OperationKinds.h>

#include "OperandClass.h"

namespace clang {
class Expr;
class Stmt;
}  // namespace clang

namespace qct {

// Result of attempting to recognize a unary operator on a quantum
// operand. `matched == false` means the Stmt was not a recognized
// UnaryOperator (not a UnaryOperator at all, the opcode is not in
// Phase 3's set, or the operand is not quantum). When `matched == true`,
// `opcode` is one of the seven Phase 3 unary opcodes and `operand` is
// the classified (Quantum, peeled) operand.
struct UnaryMatch {
    bool matched;
    clang::UnaryOperatorKind opcode;
    OperandInfo operand;
};

// Attempt to recognize `s` as a UnaryOperator with a quantum operand.
// Accepts both Stmt* and Expr* at the entry point (Expr inherits from
// Stmt). Returns `matched == false` when:
//   - `s` is nullptr;
//   - `s` is not a UnaryOperator;
//   - the operator is not one of the seven Phase 3 opcodes listed in
//     the header docstring;
//   - the operand is not classified as Quantum (i.e. it's a literal,
//     classical var, sub-expression, etc.).
UnaryMatch matchUnary(const clang::Stmt *s);

}  // namespace qct
