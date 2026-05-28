// UnaryCodegen: emit the rewritten text for Pattern 9 (unary on a
// quantum operand) per PRD §"Rewriter patterns" and PLAN §6.4.
//
// Two emission shapes, dispatched on the matched UnaryOperatorKind:
//
// Pure-unary (UO_Minus, UO_Not, UO_LNot):
//   Source : `-a`        →  Output expr text: `-a.val`
//            `~a`        →                    `~a.val`
//            `!a`        →                    `!a.val`
//   These are pure expressions with no side effect, embedded inside a
//   larger statement (an assignment, an initializer, etc.). The
//   emitter returns just the operator + decorated operand; the caller
//   splices the result into its surrounding context.
//
// Inc/dec multi-statement (UO_PreInc / UO_PostInc / UO_PreDec / UO_PostDec):
//   These have side effects (modify the operand) AND a value (the new
//   value for prefix, the prior value for postfix). When the inc/dec
//   appears as the value of an enclosing assignment like
//   `b = ++a;` or `quantum int b = a++;`, the emitter produces a
//   sequence of two statements that:
//     - prefix: modify operand FIRST, then propagate to destination.
//                `b = ++a;` →  `a.val += 1; b.val = a.val;`
//     - postfix: propagate operand value FIRST (capturing the prior
//                value semantics), then modify operand.
//                `b = a++;` →  `b.val = a.val; a.val += 1;`
//   PLAN §6.4 records this choice ("modify-then-propagate" vs
//   "propagate-then-modify"). The compound-assign form (`+=` / `-=`)
//   for the modification matches PLAN §6.5's preservation rule.
//
// When the inc/dec appears as a STANDALONE statement (`++a;` with no
// surrounding value consumer), the emitter returns just the
// modification: `a.val += 1;` or `a.val -= 1;`. The pre-vs-post
// distinction is irrelevant — both shapes have identical side effect
// and the discarded value cannot be observed.
//
// UnaryCodegen is Clang-free, mirroring Codegen.cpp / AssignCodegen.cpp.
// The AST-touching glue (UnaryRewrite) classifies the operand, decides
// whether a destination is in scope, and hands UnaryCodegen the bare
// names.
#pragma once

#include <string>

#include <clang/AST/OperationKinds.h>

namespace qct {

// Input for a single Pattern 9 emission.
//
//   - `opcode` is one of the seven Phase 3 unary opcodes UnaryMatcher
//     recognises (UO_Minus, UO_Not, UO_LNot, UO_PreInc, UO_PostInc,
//     UO_PreDec, UO_PostDec).
//
//   - `operandName` is the bare identifier of the quantum VarDecl the
//     unary applies to (e.g. "a"). The emitter appends `.val` itself.
//
//   - `destExpr` is the textual l-value expression that receives the
//     inc/dec's value, fully decorated (e.g. "b.val"). It is only read
//     for the inc/dec opcodes AND only when the caller knows a value
//     consumer exists; pure unaries ignore it, and standalone inc/dec
//     statements (no value consumer) pass it as the empty string.
struct UnaryEmitInput {
    clang::UnaryOperatorKind opcode;
    std::string operandName;
    std::string destExpr;
};

// Render Pattern 9 emission text. For pure unaries returns an
// expression (no trailing semicolon); for inc/dec returns one or two
// C statements (each terminated with `;`, joined by a single ASCII
// space when there are two). See header docstring for the per-opcode
// shapes and PLAN §6.4 for the dispatching rules.
//
// Examples:
//   emitUnary({UO_Minus,   "a", ""})       -> "-a.val"
//   emitUnary({UO_Not,     "a", ""})       -> "~a.val"
//   emitUnary({UO_LNot,    "a", ""})       -> "!a.val"
//   emitUnary({UO_PreInc,  "a", "b.val"})  -> "a.val += 1; b.val = a.val;"
//   emitUnary({UO_PostInc, "a", "b.val"})  -> "b.val = a.val; a.val += 1;"
//   emitUnary({UO_PreDec,  "a", "b.val"})  -> "a.val -= 1; b.val = a.val;"
//   emitUnary({UO_PostDec, "a", "b.val"})  -> "b.val = a.val; a.val -= 1;"
//   emitUnary({UO_PreInc,  "a", ""})       -> "a.val += 1;"
//   emitUnary({UO_PostInc, "a", ""})       -> "a.val += 1;"
std::string emitUnary(const UnaryEmitInput &in);

}  // namespace qct
