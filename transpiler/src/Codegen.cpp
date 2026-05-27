#include "Codegen.h"

#include "BinopCodegen.h"
#include "UnaryCodegen.h"

#include <sstream>
#include <string>

#include <clang/AST/OperationKinds.h>

namespace qct {

namespace {

// Build "cq_init_<sfx>(<value>)". `value` is spliced verbatim — the
// caller passes either the literal "0" (Uninit) or the original source
// text of a classical initializer (ClassicalInit). The suffix is
// `TypeMap::intrinsicSuffix` (e.g. "si32", "ui8", "sl", "f64"),
// signedness-bearing per PRD §"Type map" (M10).
std::string cqInitCall(const std::string &widthSuffix,
                       const std::string &value) {
    std::ostringstream os;
    os << "cq_init_" << widthSuffix << "(" << value << ")";
    return os.str();
}

// Build "<midStructName> <name> = <rhs>;" — the common skeleton for
// Uninit and ClassicalInit, which both yield a single initializing
// assignment. The mid-struct name is supplied by the caller from
// `TypeMap::midStructName` so the same helper works uniformly for all
// 14 Phase 2 mid-struct types.
std::string declInitWith(const std::string &midStructName,
                         const std::string &name, const std::string &rhs) {
    std::ostringstream os;
    os << midStructName << " " << name << " = " << rhs << ";";
    return os.str();
}

// Build "<midStructName> <name>; <name>.val = <sourceName>.val;" — the
// QuantumCopy (Pattern 6) form. Like emitQuantumAdd this is one flat
// line containing two C statements (declaration + assignment), but with
// no intrinsic call: SROA collapses this into SSA aliasing in Phase 2's
// scope. The mid-struct name comes from `TypeMap::midStructName`.
std::string declThenCopy(const std::string &midStructName,
                         const std::string &name,
                         const std::string &sourceName) {
    std::ostringstream os;
    os << midStructName << " " << name << "; "
       << name << ".val = " << sourceName << ".val;";
    return os.str();
}

std::string declThenCrossCopy(const std::string &midStructName,
                              const std::string &name,
                              const std::string &sourceName,
                              const std::string &castTypeName) {
    std::ostringstream os;
    os << midStructName << " " << name << "; "
       << name << ".val = (" << castTypeName << ") " << sourceName << ".val;";
    return os.str();
}

// Predicate: opcode is a pure-unary (no side effect) operator.
bool isPureUnaryOpcode(clang::UnaryOperatorKind op) {
    return op == clang::UO_Minus || op == clang::UO_Not ||
           op == clang::UO_LNot;
}

// Build the QuantumUnaryInit form (Pattern 9 declaration-init — M8
// round 2). Emits the declaration `<midStructName> <name>;` followed by
// the UnaryCodegen emission with `destExpr = <name>.val`. For
// pure-unary opcodes (UO_Minus, UO_Not, UO_LNot) `emitUnary` returns
// the bare expression text (no semicolon), so we wrap it into an
// assignment statement here. For inc/dec opcodes `emitUnary` already
// returns the full two-statement form per PLAN §6.4, which we splice
// verbatim after the declaration.
std::string declThenUnary(const std::string &midStructName,
                          const std::string &name,
                          const std::string &sourceName,
                          clang::UnaryOperatorKind op) {
    UnaryEmitInput uin{};
    uin.opcode = op;
    uin.operandName = sourceName;
    uin.destExpr = name + ".val";
    std::ostringstream os;
    os << midStructName << " " << name << "; ";
    if (isPureUnaryOpcode(op)) {
        // emitUnary returns just the expression (no `;`); wrap it.
        os << name << ".val = " << emitUnary(uin) << ";";
    } else {
        // emitUnary returns one or two `;`-terminated statements
        // assembled per PLAN §6.4's prefix-vs-postfix ordering.
        os << emitUnary(uin);
    }
    return os.str();
}

}  // namespace

// Phase 3 M8 multiplex: this is the slimmed entry point. The
// QuantumAdd path now delegates to BinopCodegen (extracted verbatim
// from Phase 2); Uninit, ClassicalInit, and QuantumCopy remain inline
// here because they're trivial declaration-init shapes that don't need
// a sibling module. Patterns 7 (plain assign) / 8 (compound assign) /
// 9 (unary) live in AssignCodegen and UnaryCodegen respectively and
// are invoked by the assign/unary rewriters — they do not flow through
// this function (the form-based dispatch here is dedicated to DeclStmt
// rewrites).
std::string renderVar(const VarRewriteInput &in) {
    using Form = VarRewriteInput::Form;
    switch (in.form) {
    case Form::Uninit:
        return declInitWith(in.midStructName, in.name,
                            cqInitCall(in.widthSuffix, "0"));
    case Form::ClassicalInit:
        return declInitWith(in.midStructName, in.name,
                            cqInitCall(in.widthSuffix, in.initText));
    case Form::QuantumAdd:
        // BinopCodegen::emitQuantumAdd carries the Phase 2 emission
        // logic verbatim; the byte-exact output is unchanged from the
        // pre-split helper.
        return emitQuantumAdd(in.midStructName, in.name, in.lhsExpr,
                              in.rhsExpr);
    case Form::QuantumCopy:
        return declThenCopy(in.midStructName, in.name, in.sourceName);
    case Form::QuantumUnaryInit:
        // M8 round 2 — Pattern 9 declaration-init forms per PLAN §4.8
        // / §6.4. UnaryCodegen handles the per-opcode ordering; we
        // only contribute the declaration prefix here.
        return declThenUnary(in.midStructName, in.name, in.sourceName,
                             in.unaryOpcode);
    case Form::QuantumCrossCopy:
        return declThenCrossCopy(in.midStructName, in.name, in.sourceName,
                                 in.castTypeName);
    }
    // Unknown Form (e.g. a future enumerator that bypassed our switch):
    // fail safe by emitting an Uninit-style declaration so we still
    // produce parseable C rather than crashing the rewriter.
    return declInitWith(in.midStructName, in.name,
                        cqInitCall(in.widthSuffix, "0"));
}

std::string renderDeclStmt(const std::vector<VarRewriteInput> &vars) {
    if (vars.empty()) {
        return {};
    }
    std::string out;
    // Reserve a rough lower bound so typical multi-decls don't realloc.
    out.reserve(vars.size() * 32);
    for (size_t i = 0; i < vars.size(); ++i) {
        if (i != 0) {
            out += ' ';
        }
        out += renderVar(vars[i]);
    }
    return out;
}

}  // namespace qct
