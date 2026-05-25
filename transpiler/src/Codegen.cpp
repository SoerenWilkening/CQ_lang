#include "Codegen.h"

#include <sstream>
#include <string>

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
// 14 Phase 2 mid-struct types (M10 widened this from a `qint_mid_t`
// hardcode; PRD §"Rewriter patterns" rows 1–2 use per-type typedefs).
std::string declInitWith(const std::string &midStructName,
                         const std::string &name, const std::string &rhs) {
    std::ostringstream os;
    os << midStructName << " " << name << " = " << rhs << ";";
    return os.str();
}

// Build "<midStructName> <name>; <name>.val = <lhsExpr> + <rhsExpr>;" —
// the QuantumAdd form. Two statements joined by a single ASCII space so
// the result is a flat one-line replacement that still parses as two
// C statements (a declaration followed by an assignment). Operand
// strings are spliced verbatim; the caller is responsible for
// appending ".val" to quantum operands (see DeclStmtRewrite). Like
// declInitWith, the mid-struct name is per-type (M10).
std::string declThenAdd(const std::string &midStructName,
                        const std::string &name,
                        const std::string &lhsExpr,
                        const std::string &rhsExpr) {
    std::ostringstream os;
    os << midStructName << " " << name << "; "
       << name << ".val = " << lhsExpr << " + " << rhsExpr << ";";
    return os.str();
}

// Build "<midStructName> <name>; <name>.val = <sourceName>.val;" — the
// QuantumCopy (Pattern 6) form. Like declThenAdd this is one flat line
// containing two C statements (declaration + assignment), but with no
// intrinsic call: SROA collapses this into SSA aliasing in Phase 2's
// scope, so emitting an intermediate `cq_copy_<sfx>` would be both
// wasted work and trace-noise (PRD §"On assignment and surviving
// operations"). The mid-struct name is supplied by the caller from
// `TypeMap::midStructName` rather than hardcoded, so this code path
// works uniformly for all 14 Phase 2 mid-struct types.
std::string declThenCopy(const std::string &midStructName,
                         const std::string &name,
                         const std::string &sourceName) {
    std::ostringstream os;
    os << midStructName << " " << name << "; "
       << name << ".val = " << sourceName << ".val;";
    return os.str();
}

}  // namespace

std::string renderVar(const VarRewriteInput &in) {
    using Form = VarRewriteInput::Form;
    switch (in.form) {
    case Form::Uninit:
        // `quantum T x;` -> initialized to literal 0 with the resolved
        // width suffix and the per-type mid-struct typedef (both
        // supplied by the caller from TypeMap; M10 generalized this
        // from the i32-only Phase-1 hardcode).
        return declInitWith(in.midStructName, in.name,
                            cqInitCall(in.widthSuffix, "0"));
    case Form::ClassicalInit:
        // `quantum T x = E;` -> splice E verbatim inside cq_init_<sfx>
        // so the original source expression survives the transform
        // (preserving precedence, spacing, calls, etc.). Mid-struct
        // name + suffix are per-type (M10).
        return declInitWith(in.midStructName, in.name,
                            cqInitCall(in.widthSuffix, in.initText));
    case Form::QuantumAdd:
        // `quantum T z = X + Y;` -> decl + .val arithmetic. Operand
        // strings already carry their decoration ("a.val" for quantum,
        // raw text for classical) per DeclStmtRewrite's contract; both
        // sides are spliced verbatim around a single " + ". Mid-struct
        // name is per-type (M10).
        return declThenAdd(in.midStructName, in.name, in.lhsExpr, in.rhsExpr);
    case Form::QuantumCopy:
        // `quantum T b = a;` (a a quantum VarDecl of the same canonical
        // type) -> decl + .val pass-through. No intrinsic; the IR pass
        // never sees the assignment because SROA collapses it to SSA
        // aliasing in Phase 2's scope. Mid-struct name comes from
        // TypeMap (per-type, not hardcoded) so the same case handles
        // all 14 Phase 2 mid-struct types.
        return declThenCopy(in.midStructName, in.name, in.sourceName);
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
