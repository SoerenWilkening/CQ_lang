#include "SourceText.h"

#include <clang/AST/Expr.h>
#include <clang/Basic/LangOptions.h>
#include <clang/Basic/SourceLocation.h>
#include <clang/Basic/SourceManager.h>
#include <clang/Lex/Lexer.h>
#include <llvm/ADT/StringRef.h>

namespace qct {

std::string getExprText(const clang::Expr *e,
                        const clang::SourceManager &sm,
                        const clang::LangOptions &lo) {
    if (e == nullptr) {
        return {};
    }
    // CharSourceRange::getTokenRange means "include the final token in
    // full"; Lexer::getSourceText then expands the range to cover the
    // full extent of that last token.
    auto range = clang::CharSourceRange::getTokenRange(e->getSourceRange());
    if (range.isInvalid()) {
        return {};
    }
    llvm::StringRef text = clang::Lexer::getSourceText(range, sm, lo);
    return text.str();
}

}  // namespace qct
