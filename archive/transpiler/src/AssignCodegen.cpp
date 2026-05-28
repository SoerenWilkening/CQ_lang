#include "AssignCodegen.h"

#include <sstream>
#include <string>

#include <clang/AST/OperationKinds.h>

namespace qct {

// Map a BinaryOperatorKind to its C operator spelling. Covers BO_Assign
// (Pattern 7) and the ten Phase 3 compound-assign opcodes (Pattern 8,
// per PRD §"Operator surface" and AssignMatcher's `isKnownCompoundAssign`
// set). Any opcode outside that set is a contract violation upstream —
// AssignMatcher only ever reports opcodes from this list — so we return
// an empty string and let the caller's defensive emission produce an
// obviously-malformed output rather than silently picking a wrong token.
std::string assignOperatorToken(clang::BinaryOperatorKind op) {
    switch (op) {
    case clang::BO_Assign:    return "=";
    case clang::BO_AddAssign: return "+=";
    case clang::BO_SubAssign: return "-=";
    case clang::BO_MulAssign: return "*=";
    case clang::BO_DivAssign: return "/=";
    case clang::BO_RemAssign: return "%=";
    case clang::BO_AndAssign: return "&=";
    case clang::BO_OrAssign:  return "|=";
    case clang::BO_XorAssign: return "^=";
    case clang::BO_ShlAssign: return "<<=";
    case clang::BO_ShrAssign: return ">>=";
    default:                  return {};
    }
}

// Emit one Pattern 7 / Pattern 8 statement. Both shapes flow through
// the same template:
//
//   <lhsName>.val <op> <rhsExpr>;
//
// where `<op>` is the literal C operator token (`=` for Pattern 7, the
// compound spelling for Pattern 8). Per PLAN §6.5, Pattern 8 preserves
// the compound operator — we never expand `a += b` into `a = a + b`.
//
// Per PRD §"Rewriter patterns" Patterns 7/8 are mechanical: any
// quantum DeclRefExpr in the LHS or RHS is suffixed with `.val`. The
// LHS substitution happens here (`lhsName` + `.val`); the RHS arrives
// pre-decorated from the caller (AssignRewrite walks the RHS subtree
// substituting `.val` on quantum sub-references and hands us the
// finished text).
std::string emitAssign(const AssignEmitInput &in) {
    const std::string op = assignOperatorToken(in.opcode);
    std::ostringstream os;
    os << in.lhsName << ".val " << op << " " << in.rhsExpr << ";";
    return os.str();
}

}  // namespace qct
