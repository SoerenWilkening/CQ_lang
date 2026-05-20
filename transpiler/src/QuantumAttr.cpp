#include "QuantumAttr.h"

#include <clang/AST/Attr.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Expr.h>

namespace qct {

bool hasQuantumAttr(const clang::VarDecl *vd) {
    if (vd == nullptr) {
        return false;
    }
    for (const auto *attr : vd->specific_attrs<clang::AnnotateAttr>()) {
        if (attr->getAnnotation() == "quantum") {
            return true;
        }
    }
    return false;
}

bool refersToQuantumVar(const clang::Expr *e) {
    if (e == nullptr) {
        return false;
    }
    // Peel off paren and implicit-cast layers in any order until we
    // hit a "real" expression node.
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
    const auto *dre = clang::dyn_cast<clang::DeclRefExpr>(e);
    if (dre == nullptr) {
        return false;
    }
    const auto *vd = clang::dyn_cast<clang::VarDecl>(dre->getDecl());
    return hasQuantumAttr(vd);
}

}  // namespace qct
