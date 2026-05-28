#include "OperandClass.h"
#include "QuantumAttr.h"

#include <clang/AST/Expr.h>

namespace qct {

namespace {

// Shared peel-and-classify body for `classify`, `classifyAssignLHS`,
// and `classifyUnaryOperand`. All three public entry points have the
// same predicate (DeclRefExpr-to-quantum-VarDecl after peeling
// ParenExpr / ImplicitCastExpr layers); they differ only in what the
// call site is semantically asking. Factoring keeps OperandClass.cpp
// within its LOC budget and ensures the three entry points cannot
// drift out of agreement on what "quantum operand" means.
OperandInfo peelAndClassify(const clang::Expr *e) {
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

}  // namespace

OperandInfo classify(const clang::Expr *e) {
    return peelAndClassify(e);
}

OperandInfo classifyAssignLHS(const clang::Expr *e) {
    // Same predicate as `classify`: the LHS is quantum iff it ultimately
    // references a quantum VarDecl. See header for the semantic
    // distinction (callers asking about "an assignment target", not
    // "an arbitrary expression").
    return peelAndClassify(e);
}

OperandInfo classifyUnaryOperand(const clang::Expr *e) {
    // Same predicate as `classify`: a unary operand is quantum iff it
    // ultimately references a quantum VarDecl. See header for the
    // semantic distinction (callers asking about "the operand of a
    // UnaryOperator node").
    return peelAndClassify(e);
}

}  // namespace qct
