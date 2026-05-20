#include "Codegen.h"

#include <sstream>
#include <string>

namespace qct {

namespace {

// Build the canonical "init_qint(<value>, <bits>)" call. `value` is
// spliced verbatim — the caller is expected to pass either a literal
// like "0" or the original source text of a classical expression.
std::string initQintCall(const std::string &value, unsigned numBits) {
    std::ostringstream os;
    os << "init_qint(" << value << ", " << numBits << ")";
    return os.str();
}

// Build "qint_t <name> = <rhs>;" — the common skeleton for every Form.
std::string declWith(const std::string &name, const std::string &rhs) {
    std::ostringstream os;
    os << "qint_t " << name << " = " << rhs << ";";
    return os.str();
}

}  // namespace

std::string renderVar(const VarRewriteInput &in) {
    using Form = VarRewriteInput::Form;
    switch (in.form) {
    case Form::Uninit:
        // Pattern 1: `quantum int x;` -> initialized to literal 0.
        return declWith(in.name, initQintCall("0", in.numBits));
    case Form::ClassicalInit:
        // Pattern 2: `quantum int x = E;` -> splice E verbatim inside
        // init_qint so the original source expression survives the
        // transform (preserving precedence, spacing, calls, etc.).
        return declWith(in.name, initQintCall(in.initText, in.numBits));
    case Form::QuantumPlusQuantum: {
        // Pattern 3: both operands are already qint_t — direct add().
        std::ostringstream os;
        os << "add(" << in.lhsName << ", " << in.rhsName << ")";
        return declWith(in.name, os.str());
    }
    case Form::QuantumPlusClassical: {
        // Pattern 4: quantum + classical -> wrap the classical operand
        // in init_qint(...) so the runtime sees a uniform qint_t × qint_t.
        std::ostringstream os;
        os << "add(" << in.lhsName << ", "
           << initQintCall(in.rhsText, in.numBits) << ")";
        return declWith(in.name, os.str());
    }
    case Form::ClassicalPlusQuantum: {
        // Pattern 4 commuted: classical + quantum — same rule, wrap the
        // classical (lhs) operand.
        std::ostringstream os;
        os << "add(" << initQintCall(in.lhsText, in.numBits) << ", "
           << in.rhsName << ")";
        return declWith(in.name, os.str());
    }
    }
    // Unknown Form (e.g. a future enumerator that bypassed our switch):
    // fail safe by emitting an Uninit-style declaration so we still
    // produce parseable C rather than crashing the rewriter.
    return declWith(in.name, initQintCall("0", in.numBits));
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
