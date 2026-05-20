// Codegen: pure string assembly for the rewritten C statement that
// replaces a quantum VarDecl (or a whole DeclStmt-worth of them).
//
// Deliberately Clang-free: the input is a plain struct (VarRewriteInput)
// populated by the AST-touching glue elsewhere, and the output is the
// final replacement text. This makes the rewrite logic trivially
// unit-testable without spinning up a CompilerInstance — which is the
// whole point of PLAN section 3.5.
//
// Output shape (per PRD "Supported source patterns (v1)" table):
//   Uninit                 -> qint_t <name> = init_qint(0, <bits>);
//   ClassicalInit          -> qint_t <name> = init_qint(<initText>, <bits>);
//   QuantumPlusQuantum     -> qint_t <name> = add(<lhsName>, <rhsName>);
//   QuantumPlusClassical   -> qint_t <name> = add(<lhsName>, init_qint(<rhsText>, <bits>));
//   ClassicalPlusQuantum   -> qint_t <name> = add(init_qint(<lhsText>, <bits>), <rhsName>);
#pragma once

#include <string>
#include <vector>

namespace qct {

struct VarRewriteInput {
    std::string name;        // e.g. "x"
    unsigned numBits;        // from TypeMap

    enum class Form {
        Uninit,                 // pattern 1
        ClassicalInit,          // pattern 2 — initText is the expression text
        QuantumPlusQuantum,     // pattern 3 — lhsName + rhsName
        QuantumPlusClassical,   // pattern 4 — lhsName + rhsText
        ClassicalPlusQuantum,   // pattern 4 commuted — lhsText + rhsName
    } form;

    std::string initText;    // for ClassicalInit
    std::string lhsName, rhsName;
    std::string lhsText, rhsText;
};

// Render a single VarRewriteInput as one rewritten C statement
// (no leading whitespace, trailing semicolon, no newline).
std::string renderVar(const VarRewriteInput &in);

// Render a sequence of VarRewriteInputs as the replacement for a
// DeclStmt: one renderVar per element, joined by a single space.
std::string renderDeclStmt(const std::vector<VarRewriteInput> &vars);

}  // namespace qct
