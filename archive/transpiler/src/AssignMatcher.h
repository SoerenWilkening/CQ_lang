// AssignMatcher: recognizes assignment statements whose left-hand side
// is a quantum-annotated VarDecl reference. Covers PRD Patterns 7 and 8:
//
//   Pattern 7: plain assign           — `q = E;`        (BO_Assign)
//   Pattern 8: compound assign        — `q += E; q *= E; …`
//                                     — any CompoundAssignOperator
//
// In both cases the LHS must classify as Quantum (via
// `OperandClass::classifyAssignLHS`). The RHS is classified through the
// general `OperandClass::classify` predicate so callers can branch on
// Q+Q vs Q+C downstream — but unlike BinopMatcher, the RHS-quantum-ness
// is not a precondition: `q = 5;` (classical RHS) is still a valid
// assignment to rewrite, the rewriter emits `q.val = 5;`.
//
// Opcode reporting:
//   - BO_Assign carries the assignment opcode itself. When the RHS of a
//     BO_Assign is a binary expression like `a = a + 1`, callers can
//     re-match through BinopMatcher on `getRHS()` to expose the inner
//     opcode (M8 wires this).
//   - CompoundAssignOperator carries a compound opcode (BO_AddAssign,
//     BO_SubAssign, …); the result's `opcode` field is the
//     CompoundAssign opcode, and `compoundUnderlyingOpcode` exposes the
//     equivalent non-assign binop (e.g. BO_AddAssign → BO_Add) so the
//     downstream codegen can dispatch on the arithmetic opcode without
//     a second switch.
//
// Codegen (M8) consumes only the match result; M7 (this issue) only
// produces results and adds unit tests. The matcher does not modify the
// AST or apply rewrites.
#pragma once
#
#include <clang/AST/OperationKinds.h>

#include "OperandClass.h"

namespace clang {
class Expr;
class Stmt;
}  // namespace clang

namespace qct {

// Result of attempting to recognize an assignment with a quantum LHS.
// `matched == false` means the Stmt was not a recognized assignment
// (not a BinaryOperator/CompoundAssignOperator, or the LHS was not
// quantum). When `matched == true`:
//   - `opcode` holds the assignment opcode (BO_Assign for plain assign,
//     or one of BO_*Assign for compound assigns).
//   - `isCompound` is true iff the underlying node is a
//     CompoundAssignOperator.
//   - `compoundUnderlyingOpcode` is the non-assign binop opcode
//     equivalent (e.g. BO_AddAssign → BO_Add). For plain BO_Assign this
//     is left at its default and callers should not read it.
//   - `lhs` is the classified LHS operand (Quantum by construction —
//     match guarantees this).
//   - `rhs` is the classified RHS operand; either Quantum or Classical.
struct AssignMatch {
    bool matched;
    bool isCompound;
    clang::BinaryOperatorKind opcode;
    clang::BinaryOperatorKind compoundUnderlyingOpcode;
    OperandInfo lhs;
    OperandInfo rhs;
};

// Attempt to recognize `s` as an assignment to a quantum VarDecl.
//
// Accepted shapes:
//   - BinaryOperator with opcode BO_Assign and a quantum LHS
//     (Pattern 7). Returns `isCompound == false`.
//   - CompoundAssignOperator with a quantum LHS, for the full set of
//     PRD compound-assign opcodes covered by Phase 3:
//       BO_AddAssign, BO_SubAssign, BO_MulAssign, BO_DivAssign,
//       BO_RemAssign, BO_AndAssign, BO_OrAssign, BO_XorAssign,
//       BO_ShlAssign, BO_ShrAssign
//     Returns `isCompound == true` and populates
//     `compoundUnderlyingOpcode`.
//
// `s` may be nullptr; the matcher returns `matched == false`. No
// rewrites are applied.
AssignMatch matchAssign(const clang::Stmt *s);

}  // namespace qct
