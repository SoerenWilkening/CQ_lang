// BinopCodegen: emit the Phase 2 QuantumAdd shape — `<midStructName>
// <name>; <name>.val = <lhsExpr> + <rhsExpr>;` — for a DeclStmt's
// quantum initializer of the form `quantum T z = X + Y;`.
//
// Phase 2 had this inlined as a private helper inside `Codegen.cpp`
// (the `declThenAdd` function in an anonymous namespace, dispatched by
// the `renderVar` switch on `VarRewriteInput::Form::QuantumAdd`). Phase
// 3 M8 hoists that helper out into a dedicated module so:
//   - `Codegen.cpp` stays at its multiplex role (entry point + form
//     dispatch) and slims to ~80 LOC.
//   - The new Patterns 7–9 (Assign, Unary) can have their own siblings
//     (`AssignCodegen.cpp`, `UnaryCodegen.cpp`) that mirror this layout.
//   - The extraction is mechanical: the function body is byte-identical
//     to the Phase 2 helper. Phase 2 goldens (76+/76+ baseline) must
//     remain byte-exact.
//
// Operand strings (`lhsExpr`, `rhsExpr`) are pre-decorated by the
// caller — quantum operands arrive as `<name>.val`, classical operands
// as their raw expression text. BinopCodegen splices both verbatim
// around a single ` + `; the operator token is hardcoded because Phase
// 2's rewriter only emits `BO_Add` (see PRD §"Operator surface" and
// PLAN §4.7 — the rewriter side stays add-only until later phases
// widen the surface).
#pragma once

#include <string>

namespace qct {

// Emit the QuantumAdd statement-pair text for one quantum initializer.
// `midStructName` is the per-type typedef (`qint_mid_t`, etc.) supplied
// by the caller; `name` is the new VarDecl's identifier; `lhsExpr` /
// `rhsExpr` are pre-decorated operand strings. Returns a single line
// containing two C statements joined by an ASCII space — the same flat
// form `Codegen::renderVar` (Phase 2) produced for `QuantumAdd`.
//
// Example: `emitQuantumAdd("qint_mid_t", "c", "a.val", "b.val")`
//   -> `"qint_mid_t c; c.val = a.val + b.val;"`
std::string emitQuantumAdd(const std::string &midStructName,
                           const std::string &name,
                           const std::string &lhsExpr,
                           const std::string &rhsExpr);

}  // namespace qct
