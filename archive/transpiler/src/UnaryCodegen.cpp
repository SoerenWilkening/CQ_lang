#include "UnaryCodegen.h"

#include <sstream>
#include <string>

#include <clang/AST/OperationKinds.h>

namespace qct {

namespace {

// Map a pure-unary opcode (UO_Minus, UO_Not, UO_LNot) to its C operator
// spelling. Returns an empty string for opcodes outside that set —
// callers gate on opcode before reaching this helper.
const char *pureUnaryToken(clang::UnaryOperatorKind op) {
    switch (op) {
    case clang::UO_Minus: return "-";
    case clang::UO_Not:   return "~";
    case clang::UO_LNot:  return "!";
    default:              return "";
    }
}

// Predicate: opcode is a pure-unary (no side effect) operator.
bool isPureUnary(clang::UnaryOperatorKind op) {
    return op == clang::UO_Minus || op == clang::UO_Not ||
           op == clang::UO_LNot;
}

// Predicate: opcode is a prefix inc/dec.
bool isPrefixIncDec(clang::UnaryOperatorKind op) {
    return op == clang::UO_PreInc || op == clang::UO_PreDec;
}

// Predicate: opcode is a postfix inc/dec.
bool isPostfixIncDec(clang::UnaryOperatorKind op) {
    return op == clang::UO_PostInc || op == clang::UO_PostDec;
}

// Map an inc/dec opcode to its modify operator (`+=` for inc, `-=` for
// dec). Per PLAN §6.4 / §6.5: we emit the compound-assign form rather
// than `a.val = a.val + 1` for symmetry with Pattern 8 emission.
const char *incDecModifyToken(clang::UnaryOperatorKind op) {
    switch (op) {
    case clang::UO_PreInc:
    case clang::UO_PostInc: return "+=";
    case clang::UO_PreDec:
    case clang::UO_PostDec: return "-=";
    default:                return "";
    }
}

// Emit just the modification statement for an inc/dec on `name`:
//   `a.val += 1;`  (inc)
//   `a.val -= 1;`  (dec)
// Identical for pre- and post-forms — the value-vs-side-effect ordering
// is enforced by the caller (`emitIncDec`).
std::string modifyStatement(const std::string &operandName,
                            clang::UnaryOperatorKind op) {
    std::ostringstream os;
    os << operandName << ".val " << incDecModifyToken(op) << " 1;";
    return os.str();
}

// Emit the destination propagate statement:
//   `b.val = a.val;`
std::string propagateStatement(const std::string &destExpr,
                               const std::string &operandName) {
    std::ostringstream os;
    os << destExpr << " = " << operandName << ".val;";
    return os.str();
}

// Compose the inc/dec multi-statement form per PLAN §6.4.
//
// - Prefix (++a / --a): modify operand FIRST, then propagate the new
//   value to the destination. Matches C's prefix semantics (the value
//   of `++a` is the *new* a).
// - Postfix (a++ / a--): propagate operand's CURRENT value to the
//   destination FIRST, then modify operand. Matches C's postfix
//   semantics (the value of `a++` is the *prior* a).
//
// When `destExpr` is empty there is no value consumer (e.g. a
// standalone `++a;` statement). In that case the value-propagation
// statement is omitted entirely and pre/post collapse to the same
// modification text — discarding the unobservable value.
std::string emitIncDec(const UnaryEmitInput &in) {
    if (in.destExpr.empty()) {
        // Standalone inc/dec — no value consumer. Just the side effect.
        return modifyStatement(in.operandName, in.opcode);
    }
    const std::string modify = modifyStatement(in.operandName, in.opcode);
    const std::string propagate = propagateStatement(in.destExpr,
                                                     in.operandName);
    std::ostringstream os;
    if (isPrefixIncDec(in.opcode)) {
        // Modify-then-propagate: the new value flows to the dest.
        os << modify << " " << propagate;
    } else {
        // Postfix: propagate-then-modify so the dest captures the
        // prior value.
        os << propagate << " " << modify;
    }
    return os.str();
}

}  // namespace

std::string emitUnary(const UnaryEmitInput &in) {
    if (isPureUnary(in.opcode)) {
        // Pure-unary returns an expression (no trailing semicolon).
        // Embed the decorated operand directly after the operator.
        std::ostringstream os;
        os << pureUnaryToken(in.opcode) << in.operandName << ".val";
        return os.str();
    }
    if (isPrefixIncDec(in.opcode) || isPostfixIncDec(in.opcode)) {
        return emitIncDec(in);
    }
    // Unknown opcode — defensive fallback. UnaryMatcher's
    // `isPhase3UnaryOpcode` gate means this branch is unreachable from
    // production callers, but returning a benign empty string keeps the
    // emitter total rather than UB on an out-of-set opcode.
    return {};
}

}  // namespace qct
