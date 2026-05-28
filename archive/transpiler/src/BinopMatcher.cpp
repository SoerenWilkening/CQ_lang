#include "BinopMatcher.h"

#include "OperandClass.h"

#include <clang/AST/Expr.h>
#include <clang/AST/OperationKinds.h>

namespace qct {

BinopMatch matchBinop(const clang::Expr *e) {
    // Default: no match. Callers see a `matched == false` result and
    // route through the classical / no-rewrite path.
    BinopMatch out{};
    out.matched = false;
    // Leave the opcode at its default (zero-initialised); callers must
    // gate on `matched` before reading it. We initialise lhs/rhs to
    // {Classical, nullptr} so an unfiltered consumer doesn't see
    // uninitialised data — same shape as `OperandClass::classify(nullptr)`.
    out.lhs = OperandInfo{OperandKind::Classical, nullptr};
    out.rhs = OperandInfo{OperandKind::Classical, nullptr};

    if (e == nullptr) {
        return out;
    }

    // Must be a BinaryOperator at the surface. We deliberately do NOT
    // peel ParenExpr / ImplicitCastExpr here — the caller is expected to
    // hand in an already-unwrapped Expr (matching how
    // DeclStmtRewrite::populateFromInit strips wrappers before invoking
    // the binop dispatch in Phase 2). Peeling inside the matcher would
    // be safe but redundant.
    //
    // CompoundAssignOperator inherits from BinaryOperator; we explicitly
    // exclude it here so AssignMatcher owns that case unambiguously
    // (Pattern 8 lives in AssignMatcher, not BinopMatcher). Without this
    // guard a `q += 1` would be dispatched twice — once by the assign
    // path and once as a regular binop.
    const auto *bo = clang::dyn_cast<clang::BinaryOperator>(e);
    if (bo == nullptr) {
        return out;
    }
    if (clang::isa<clang::CompoundAssignOperator>(bo)) {
        return out;
    }
    // BO_Assign is also a BinaryOperator (not a CompoundAssignOperator).
    // We exclude it here for the same reason: the assignment path lives
    // in AssignMatcher. Phase 2's only binop opcode is BO_Add, so this
    // guard is forward-looking — once Phase 3 M11 widens the opcode
    // surface we won't accidentally match `q = …` through this matcher.
    if (bo->getOpcode() == clang::BO_Assign) {
        return out;
    }

    // Classify both sides through the shared OperandClass predicate.
    // `classify` peels paren/cast wrappers and returns the unwrapped
    // Expr* alongside the kind. This is the same predicate Phase 2's
    // inline binop dispatch uses, ensuring the extracted matcher's
    // contract matches the pre-split logic byte-exact.
    OperandInfo lhs = classify(bo->getLHS());
    OperandInfo rhs = classify(bo->getRHS());
    const bool lhsQ = (lhs.kind == OperandKind::Quantum);
    const bool rhsQ = (rhs.kind == OperandKind::Quantum);

    // At least one side must be quantum for this to be a binop the
    // rewriter cares about. A purely classical `1 + 2;` initializer
    // routes through the caller's ClassicalInit fallback, which splices
    // the original source text verbatim into `cq_init_<sfx>(...)`.
    if (!lhsQ && !rhsQ) {
        // Fill in the operand classifications so a curious caller can
        // still see what was classified, but mark unmatched.
        out.lhs = lhs;
        out.rhs = rhs;
        return out;
    }

    out.matched = true;
    out.opcode = bo->getOpcode();
    out.lhs = lhs;
    out.rhs = rhs;
    return out;
}

}  // namespace qct
