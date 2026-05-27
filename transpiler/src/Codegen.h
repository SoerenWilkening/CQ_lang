// Codegen: pure string assembly for the rewritten C statement that
// replaces a quantum VarDecl (or a whole DeclStmt-worth of them).
//
// Deliberately Clang-free: the input is a plain struct (VarRewriteInput)
// populated by the AST-touching glue elsewhere, and the output is the
// final replacement text. This makes the rewrite logic trivially
// unit-testable without spinning up a CompilerInstance (PLAN §3.5).
//
// Phase 1 had three Forms; Phase 2 M9 added `QuantumCopy` for Pattern 6
// (`quantum T b = a;`, same canonical type). Phase 3 M8 (round 2) adds
// `QuantumUnaryInit` for Pattern 9 declaration-init forms — `quantum
// int b = -a;` etc. — per PLAN §4.8 acceptance and §6.4 ordering.
// Taint propagation in the IR pass collapses QQ/QC/CQ distinctions, so
// both quantum-touching adds use the same ".val arithmetic" pattern;
// classify-and-decorate (whether to append ".val" to an operand)
// happens upstream in DeclStmtRewrite via OperandClass.
//
//   Uninit            -> <midStructName> <name> = cq_init_<sfx>(0);
//   ClassicalInit     -> <midStructName> <name> = cq_init_<sfx>(<initText>);
//   QuantumAdd        -> <midStructName> <name>; <name>.val = <lhsExpr> + <rhsExpr>;
//   QuantumCopy       -> <midStructName> <name>; <name>.val = <sourceName>.val;
//   QuantumUnaryInit  -> <midStructName> <name>; <UnaryCodegen emission with
//                        destExpr=<name>.val>;
//                        Pure-unary (UO_Minus/Not/LNot):
//                          `<midStructName> <name>; <name>.val = <op><src>.val;`
//                        Prefix inc/dec (UO_PreInc/Dec):
//                          `<midStructName> <name>; <src>.val ±= 1; <name>.val = <src>.val;`
//                        Postfix inc/dec (UO_PostInc/Dec):
//                          `<midStructName> <name>; <name>.val = <src>.val; <src>.val ±= 1;`
//   QuantumCrossCopy  -> <midStructName> <name>; <name>.val = (<castTypeName>) <sourceName>.val;
//
// M10 widened `widthSuffix` from Phase 1's width-only `"i32"` form to
// the signedness-bearing `TypeMap::intrinsicSuffix` (e.g. "si32", "ui8",
// "sl", "f64"), and replaced the `qint_mid_t` hardcode with
// `TypeMap::midStructName(T)` so the same renderer handles all 14
// Phase 2 mid-struct types.
#pragma once

#include <string>
#include <vector>

#include <clang/AST/OperationKinds.h>

namespace qct {

struct VarRewriteInput {
    std::string name;           // e.g. "x"
    std::string widthSuffix;    // signedness-bearing intrinsic suffix
                                // from `TypeMap::intrinsicSuffix` (e.g.
                                // "si32", "ui8", "sl", "f64")
    std::string midStructName;  // per-type mid-struct typedef from
                                // `TypeMap::midStructName` (e.g.
                                // "qint_mid_t", "qfloat_mid_t")

    enum class Form {
        Uninit,            // `quantum T x;`            → cq_init_<sfx>(0)
        ClassicalInit,     // `quantum T x = E;`        → cq_init_<sfx>(E)
        QuantumAdd,        // `quantum T z = X + Y;`    → .val arithmetic
        QuantumCopy,       // `quantum T b = a;` (same canonical type)
                           //                           → split form, no intrinsic
        QuantumUnaryInit,  // `quantum T b = -a;` (or ~a/!a/++a/a++/--a/a--)
                           //                           → decl + UnaryCodegen
        QuantumCrossCopy,  // `quantum T b = q_other;` (cross-width Q→Q)
                           //                           → decl + cast on .val
    } form;

    // ClassicalInit: original initializer source text, spliced verbatim
    // inside cq_init_<sfx>(...).
    std::string initText;

    // QuantumAdd: each side is already decorated by the caller —
    // quantum operands arrive as "a.val", classical operands as their
    // raw expression text ("5", "k", "1+2", ...). Codegen splices both
    // sides verbatim around a single " + ".
    std::string lhsExpr;
    std::string rhsExpr;

    // QuantumCopy (Pattern 6 — M9): source-side VarDecl name (e.g. "a").
    // Codegen emits `<midStructName> <name>; <name>.val = <sourceName>.val;`
    // — no intrinsic call, because SROA erases this pattern in Phase 2's
    // scope (see PRD §"On assignment and surviving operations").
    std::string sourceName;

    // QuantumUnaryInit (Pattern 9 declaration-init — M8 round 2):
    // `unaryOpcode` is one of the seven Phase 3 unary opcodes (UO_Minus,
    // UO_Not, UO_LNot, UO_PreInc, UO_PostInc, UO_PreDec, UO_PostDec).
    // `sourceName` (reused from QuantumCopy) is the operand VarDecl's
    // bare identifier (e.g. "a"). Codegen emits the declaration then
    // routes through `UnaryCodegen::emitUnary` with `destExpr =
    // <name>.val`, producing the per-opcode shape documented above.
    clang::UnaryOperatorKind unaryOpcode;

    // QuantumCrossCopy (Patterns 10/11 — Phase 3 M9): cross-width Q→Q
    // init. `sourceName` carries the source quantum VarDecl name;
    // `castTypeName` is the destination's C type name for the cast (e.g.
    // "long" for `quantum long b = q_int;`). Codegen emits
    // `<midStructName> <name>; <name>.val = (<castTypeName>) <sourceName>.val;`
    std::string castTypeName;
};

// Render a single VarRewriteInput as one rewritten C statement
// (no leading whitespace, trailing semicolon, no newline).
std::string renderVar(const VarRewriteInput &in);

// Render a sequence of VarRewriteInputs as the replacement for a
// DeclStmt: one renderVar per element, joined by a single space.
std::string renderDeclStmt(const std::vector<VarRewriteInput> &vars);

}  // namespace qct
