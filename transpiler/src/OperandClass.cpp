#include "OperandClass.h"
#include "QuantumAttr.h"

#include <clang/AST/Expr.h>

namespace qct {

OperandInfo classify(const clang::Expr *e) {
    OperandInfo info{OperandKind::Classical, nullptr};
    if (e == nullptr) {
        return info;
    }
    // Peel paren+cast layers in either order until we hit a "real" node.
    // We expose the unwrapped node via info.expr so callers (codegen)
    // can splice the underlying text rather than the wrapped one.
    for (;;) {
        if (const auto *pe = clang::dyn_cast<clang::ParenExpr>(e)) {
            e = pe->getSubExpr();
            continue;
        }
        if (const auto *ice = clang::dyn_cast<clang::ImplicitCastExpr>(e)) {
            e = ice->getSubExpr();
            continue;
        }
        break;
    }
    info.expr = e;
    // Delegate the "is this a DeclRefExpr to a quantum VarDecl" decision
    // to QuantumAttr. refersToQuantumVar re-unwraps internally but the
    // double-walk is cheap; keeping the call here means there is exactly
    // one place that knows the quantum-attribute marker string.
    if (qct::refersToQuantumVar(e)) {
        info.kind = OperandKind::Quantum;
    }
    return info;
}

}  // namespace qct
