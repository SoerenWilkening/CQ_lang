#include "Codegen.h"

#include <sstream>
#include <string>

namespace qct {

namespace {

// Build "cq_init_<W>(<value>)". `value` is spliced verbatim — the caller
// is expected to pass either the literal "0" (Uninit) or the original
// source text of a classical initializer (ClassicalInit).
std::string cqInitCall(const std::string &widthSuffix,
                       const std::string &value) {
    std::ostringstream os;
    os << "cq_init_" << widthSuffix << "(" << value << ")";
    return os.str();
}

// Build "qint_mid_t <name> = <rhs>;" — the common skeleton for Uninit
// and ClassicalInit, which both yield a single initializing assignment.
std::string declInitWith(const std::string &name, const std::string &rhs) {
    std::ostringstream os;
    os << "qint_mid_t " << name << " = " << rhs << ";";
    return os.str();
}

// Build "qint_mid_t <name>; <name>.val = <lhsExpr> + <rhsExpr>;" — the
// QuantumAdd form. Two statements joined by a single ASCII space so
// the result is a flat one-line replacement that still parses as two
// C statements (a declaration followed by an assignment). Operand
// strings are spliced verbatim; the caller is responsible for
// appending ".val" to quantum operands (see DeclStmtRewrite).
std::string declThenAdd(const std::string &name,
                        const std::string &lhsExpr,
                        const std::string &rhsExpr) {
    std::ostringstream os;
    os << "qint_mid_t " << name << "; "
       << name << ".val = " << lhsExpr << " + " << rhsExpr << ";";
    return os.str();
}

}  // namespace

std::string renderVar(const VarRewriteInput &in) {
    using Form = VarRewriteInput::Form;
    switch (in.form) {
    case Form::Uninit:
        // `quantum int x;` -> initialized to literal 0 with the
        // resolved width suffix.
        return declInitWith(in.name, cqInitCall(in.widthSuffix, "0"));
    case Form::ClassicalInit:
        // `quantum int x = E;` -> splice E verbatim inside cq_init_<W>
        // so the original source expression survives the transform
        // (preserving precedence, spacing, calls, etc.).
        return declInitWith(in.name, cqInitCall(in.widthSuffix, in.initText));
    case Form::QuantumAdd:
        // `quantum int z = X + Y;` -> decl + .val arithmetic. Operand
        // strings already carry their decoration ("a.val" for quantum,
        // raw text for classical) per DeclStmtRewrite's contract; both
        // sides are spliced verbatim around a single " + ".
        return declThenAdd(in.name, in.lhsExpr, in.rhsExpr);
    }
    // Unknown Form (e.g. a future enumerator that bypassed our switch):
    // fail safe by emitting an Uninit-style declaration so we still
    // produce parseable C rather than crashing the rewriter.
    return declInitWith(in.name, cqInitCall(in.widthSuffix, "0"));
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
