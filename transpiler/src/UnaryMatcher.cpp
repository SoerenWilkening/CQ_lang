#include "UnaryMatcher.h"

#include "OperandClass.h"

#include <clang/AST/Expr.h>
#include <clang/AST/OperationKinds.h>
#include <clang/AST/Stmt.h>

namespace qct {

namespace {

// Predicate: is `op` one of the seven Phase 3 unary opcodes we
// recognize on a quantum operand?
//   - Arithmetic / bitwise / logical:  UO_Minus, UO_Not, UO_LNot
//   - Side-effecting (inc/dec):        UO_PreInc, UO_PostInc,
//                                      UO_PreDec, UO_PostDec
// UO_Plus is excluded (clang folds it away on integer/fp operands; the
// AST node may exist but the operator is a no-op). UO_AddrOf and the
// other pointer/coroutine unary kinds are also excluded — they don't
// apply to a quantum value type (we have no quantum addresses or
// coroutines in Phase 3).
bool isPhase3UnaryOpcode(clang::UnaryOperatorKind op) {
    switch (op) {
    case clang::UO_Minus:
    case clang::UO_Not:
    case clang::UO_LNot:
    case clang::UO_PreInc:
    case clang::UO_PostInc:
    case clang::UO_PreDec:
    case clang::UO_PostDec:
        return true;
    default:
        return false;
    }
}

}  // namespace

UnaryMatch matchUnary(const clang::Stmt *s) {
    UnaryMatch out{};
    out.matched = false;
    out.operand = OperandInfo{OperandKind::Classical, nullptr};

    if (s == nullptr) {
        return out;
    }

    const auto *uo = clang::dyn_cast<clang::UnaryOperator>(s);
    if (uo == nullptr) {
        return out;
    }

    const clang::UnaryOperatorKind op = uo->getOpcode();
    if (!isPhase3UnaryOpcode(op)) {
        // UnaryOperator with an opcode outside Phase 3's surface (e.g.
        // UO_Plus, UO_AddrOf, UO_Deref, UO_Real, UO_Imag, UO_Extension,
        // UO_Coawait). Not a rewrite target.
        return out;
    }

    // Classify the operand. The dedicated `classifyUnaryOperand` entry
    // point is semantically equivalent to `classify` (they share the
    // peel-and-check predicate in OperandClass.cpp), but using the
    // dedicated name keeps the call site self-documenting and matches
    // the seam Phase 3 M6 introduced for exactly this purpose.
    OperandInfo opnd = classifyUnaryOperand(uo->getSubExpr());
    if (opnd.kind != OperandKind::Quantum) {
        // Classical operand — falls through to stock C emission. The
        // rewriter ignores classical unary expressions; they pass
        // through the input source unchanged.
        out.operand = opnd;
        return out;
    }

    out.matched = true;
    out.opcode = op;
    out.operand = opnd;
    return out;
}

}  // namespace qct
