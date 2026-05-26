#include "AssignMatcher.h"

#include "OperandClass.h"

#include <clang/AST/Expr.h>
#include <clang/AST/OperationKinds.h>
#include <clang/AST/Stmt.h>

namespace qct {

namespace {

// Map a CompoundAssignOperator's opcode to the equivalent non-assign
// binop opcode. Codegen consumes this to dispatch on the arithmetic
// opcode without a second switch (M8). The PRD §"Operator surface"
// names the ten compound-assign opcodes Phase 3 must recognize; any
// opcode not in that list returns BO_Assign as a sentinel meaning "no
// underlying binop opcode" — callers should not request the underlying
// opcode for that case but the sentinel is safer than leaving the
// field garbage.
clang::BinaryOperatorKind underlyingOpcode(clang::BinaryOperatorKind op) {
    switch (op) {
    case clang::BO_AddAssign: return clang::BO_Add;
    case clang::BO_SubAssign: return clang::BO_Sub;
    case clang::BO_MulAssign: return clang::BO_Mul;
    case clang::BO_DivAssign: return clang::BO_Div;
    case clang::BO_RemAssign: return clang::BO_Rem;
    case clang::BO_AndAssign: return clang::BO_And;
    case clang::BO_OrAssign:  return clang::BO_Or;
    case clang::BO_XorAssign: return clang::BO_Xor;
    case clang::BO_ShlAssign: return clang::BO_Shl;
    case clang::BO_ShrAssign: return clang::BO_Shr;
    default:                  return clang::BO_Assign;
    }
}

// Predicate: is `op` one of the ten Phase 3 compound-assign opcodes?
// `CompoundAssignOperator::getOpcode()` returns the assign-variant; we
// double-check it's in our known list rather than blindly accepting any
// CompoundAssignOperator (defends against future Clang AST additions
// like pointer-arithmetic compound assigns we don't model).
bool isKnownCompoundAssign(clang::BinaryOperatorKind op) {
    switch (op) {
    case clang::BO_AddAssign:
    case clang::BO_SubAssign:
    case clang::BO_MulAssign:
    case clang::BO_DivAssign:
    case clang::BO_RemAssign:
    case clang::BO_AndAssign:
    case clang::BO_OrAssign:
    case clang::BO_XorAssign:
    case clang::BO_ShlAssign:
    case clang::BO_ShrAssign:
        return true;
    default:
        return false;
    }
}

}  // namespace

AssignMatch matchAssign(const clang::Stmt *s) {
    AssignMatch out{};
    out.matched = false;
    out.isCompound = false;
    out.lhs = OperandInfo{OperandKind::Classical, nullptr};
    out.rhs = OperandInfo{OperandKind::Classical, nullptr};

    if (s == nullptr) {
        return out;
    }

    // The matcher accepts both Stmt and Expr at the entry point: most
    // call sites hand in a Stmt* (whatever the parent block iterator
    // returns), but inner-Expr lookups (e.g. the initializer of a
    // VarDecl) hand in an Expr*. Both inherit from Stmt so the dyn_cast
    // below works uniformly.
    //
    // Try CompoundAssignOperator first: it inherits from BinaryOperator
    // so a `dyn_cast<BinaryOperator>` would also match — guarding the
    // compound path first keeps the branch logic explicit. Pattern 8.
    if (const auto *cao = clang::dyn_cast<clang::CompoundAssignOperator>(s)) {
        const clang::BinaryOperatorKind op = cao->getOpcode();
        if (!isKnownCompoundAssign(op)) {
            // Unknown compound-assign opcode — leave matched=false.
            // Defensive: as of Phase 3 the ten PRD opcodes are all of
            // them, but Clang may add more in the future.
            return out;
        }
        OperandInfo lhs = classifyAssignLHS(cao->getLHS());
        if (lhs.kind != OperandKind::Quantum) {
            // Classical LHS — not a rewrite target. Pure C compound
            // assign passes through unchanged.
            return out;
        }
        out.matched = true;
        out.isCompound = true;
        out.opcode = op;
        out.compoundUnderlyingOpcode = underlyingOpcode(op);
        out.lhs = lhs;
        out.rhs = classify(cao->getRHS());
        return out;
    }

    // Fall through to plain BinaryOperator(BO_Assign). Pattern 7.
    if (const auto *bo = clang::dyn_cast<clang::BinaryOperator>(s)) {
        if (bo->getOpcode() != clang::BO_Assign) {
            // Any other binop — not an assignment. The caller may want
            // to route through BinopMatcher in that case.
            return out;
        }
        OperandInfo lhs = classifyAssignLHS(bo->getLHS());
        if (lhs.kind != OperandKind::Quantum) {
            return out;
        }
        out.matched = true;
        out.isCompound = false;
        out.opcode = clang::BO_Assign;
        // compoundUnderlyingOpcode left at its default; per the header,
        // callers should not read it when isCompound == false.
        out.lhs = lhs;
        out.rhs = classify(bo->getRHS());
        return out;
    }

    return out;
}

}  // namespace qct
