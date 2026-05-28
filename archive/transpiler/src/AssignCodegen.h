// AssignCodegen: emit the rewritten text for Patterns 7 (plain assign)
// and 8 (compound assign) per PRD §"Rewriter patterns" and PLAN §4.8.
//
// Pattern 7 — plain assignment with quantum LHS:
//   Source : `a = b + 1;`             (a, b quantum)
//   Output : `a.val = b.val + 1;`
//
//   The RHS is the user's original source text, with any quantum
//   DeclRefExpr substring already rewritten to its `.val` accessor by
//   the caller (AssignRewrite, which walks the RHS expression tree).
//   Pattern 7 simply appends `.val` to the LHS identifier and splices
//   the decorated RHS verbatim, preserving the `=` operator.
//
// Pattern 8 — compound assignment with quantum LHS (per PLAN §6.5):
//   Source : `a += b;`                (a, b quantum)
//   Output : `a.val += b.val;`
//
//   The compound operator (`+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`,
//   `^=`, `<<=`, `>>=`) is preserved literally — we do NOT expand the
//   compound form into `a = a + b` style. PLAN §6.5 records this
//   decision (the compound shape is shorter, mirrors the user's source,
//   and Clang's `-O1` lowers both to identical IR).
//
// AssignCodegen is Clang-free: callers (AssignRewrite, the AST-touching
// glue) classify operands via OperandClass, walk the RHS to substitute
// `.val` on quantum sub-references, and hand AssignCodegen the
// already-decorated text. This keeps emit functions trivially
// unit-testable (mirrors Codegen.cpp's Phase 2 design).
#pragma once

#include <string>

#include <clang/AST/OperationKinds.h>

namespace qct {

// Input for a single Pattern 7 / Pattern 8 emission. The Phase 3 M7
// AssignMatcher returns enough metadata to populate this struct
// directly; AssignRewrite (the AST glue) fills it from the matched
// assignment node + its RHS source text after `.val` substitution.
struct AssignEmitInput {
    // The LHS quantum VarDecl's bare identifier (e.g. "a"). The emitter
    // appends `.val` here.
    std::string lhsName;

    // The RHS expression as text — already with `.val` appended to any
    // quantum DeclRefExpr substrings inside it. For a classical RHS
    // (`a = 5;`) this is just "5"; for a binop RHS (`a = b + 1;`) this
    // is "b.val + 1" once the caller has walked the binop and rewritten
    // `b` -> `b.val`.
    std::string rhsExpr;

    // For Pattern 8, the compound opcode (e.g. BO_AddAssign for `+=`).
    // For Pattern 7, must be BO_Assign. The emitter renders the matched
    // operator literally — preserving the compound form per PLAN §6.5.
    clang::BinaryOperatorKind opcode;
};

// Render a single Pattern 7 / Pattern 8 assignment as one C statement
// (no leading whitespace, trailing semicolon, no newline). The output
// is byte-exact according to the patterns documented in this header
// and PLAN §6.5.
//
// Examples:
//   emitAssign({"a", "b.val + 1", BO_Assign})    -> "a.val = b.val + 1;"
//   emitAssign({"a", "b.val",     BO_AddAssign}) -> "a.val += b.val;"
//   emitAssign({"a", "5",         BO_Assign})    -> "a.val = 5;"
std::string emitAssign(const AssignEmitInput &in);

// Map a BinaryOperatorKind (assign or compound-assign) to its C operator
// token. Returns the empty string for opcodes that are not assignments
// — callers should treat that as a programming error (only opcodes
// AssignMatcher reports should reach this helper).
//
// Exposed for unit testing and so the assignment-rewriter glue can use
// the same mapping without re-spelling it.
std::string assignOperatorToken(clang::BinaryOperatorKind op);

}  // namespace qct
