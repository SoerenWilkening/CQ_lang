#include "BinopCodegen.h"

#include <sstream>
#include <string>

namespace qct {

// Build "<midStructName> <name>; <name>.val = <lhsExpr> + <rhsExpr>;" —
// the QuantumAdd form, extracted verbatim from Phase 2's `Codegen.cpp`
// helper `declThenAdd`. Two statements joined by a single ASCII space
// so the result is a flat one-line replacement that still parses as two
// C statements (a declaration followed by an assignment). Operand
// strings are spliced verbatim; the caller is responsible for
// appending ".val" to quantum operands (see DeclStmtRewrite).
//
// Implementation note: this is the single point of textual emission for
// every Phase 2 QuantumAdd rewrite. Any future widening to other binary
// opcodes (Phase 3 M11 widens the IR-pass side; rewriter side is
// add-only until later) would extend the parameter set here; for now
// the operator token is `+`, hardcoded, matching the Phase 2 byte-exact
// contract.
std::string emitQuantumAdd(const std::string &midStructName,
                           const std::string &name,
                           const std::string &lhsExpr,
                           const std::string &rhsExpr) {
    std::ostringstream os;
    os << midStructName << " " << name << "; "
       << name << ".val = " << lhsExpr << " + " << rhsExpr << ";";
    return os.str();
}

}  // namespace qct
