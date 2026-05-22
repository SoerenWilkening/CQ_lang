// Codegen: pure string assembly for the rewritten C statement that
// replaces a quantum VarDecl (or a whole DeclStmt-worth of them).
//
// Deliberately Clang-free: the input is a plain struct (VarRewriteInput)
// populated by the AST-touching glue elsewhere, and the output is the
// final replacement text. This makes the rewrite logic trivially
// unit-testable without spinning up a CompilerInstance — which is the
// whole point of PLAN section 3.5.
//
// Phase 1 emission targets (PLAN §4.4.2). The form enum collapses from
// v1's five values to three: taint propagation in the IR pass makes the
// QQ/QC/CQ distinctions go away, so both quantum-touching adds use the
// same ".val arithmetic" pattern. The classify-and-decorate decision
// (whether to append ".val" to a given operand) is made upstream in
// DeclStmtRewrite via OperandClass; Codegen receives already-decorated
// strings and stays Clang-free.
//
//   Uninit         -> qint_mid_t <name> = cq_init_<W>(0);
//   ClassicalInit  -> qint_mid_t <name> = cq_init_<W>(<initText>);
//   QuantumAdd     -> qint_mid_t <name>; <name>.val = <lhsExpr> + <rhsExpr>;
//
// Width-suffix is the LLVM IR-style intrinsic suffix string (e.g.
// "i32") supplied by TypeMap::irWidthSuffix; it is spliced verbatim
// into the cq_init_<W> symbol name. Phase 1's tests exercise i32 only,
// but the renderer is width-agnostic.
#pragma once

#include <string>
#include <vector>

namespace qct {

struct VarRewriteInput {
    std::string name;           // e.g. "x"
    std::string widthSuffix;    // e.g. "i32" — from TypeMap::irWidthSuffix

    enum class Form {
        Uninit,         // `quantum int x;`               → cq_init_<W>(0)
        ClassicalInit,  // `quantum int x = E;`           → cq_init_<W>(E)
        QuantumAdd,     // `quantum int z = X + Y;`       → .val arithmetic
    } form;

    // ClassicalInit: the original initializer's source text, spliced
    // verbatim inside cq_init_<W>(...).
    std::string initText;

    // QuantumAdd: each side is already decorated by the caller —
    // quantum operands arrive as "a.val", classical operands as their
    // raw expression text ("5", "k", "1+2", ...). Codegen splices both
    // sides verbatim around a single " + ".
    std::string lhsExpr;
    std::string rhsExpr;
};

// Render a single VarRewriteInput as one rewritten C statement
// (no leading whitespace, trailing semicolon, no newline).
std::string renderVar(const VarRewriteInput &in);

// Render a sequence of VarRewriteInputs as the replacement for a
// DeclStmt: one renderVar per element, joined by a single space.
std::string renderDeclStmt(const std::vector<VarRewriteInput> &vars);

}  // namespace qct
