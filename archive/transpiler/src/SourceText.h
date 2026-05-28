// SourceText: thin wrapper over clang::Lexer::getSourceText for the
// common case of "give me the original token text of this Expr".
// Used by the rewrite path to splice classical operands verbatim into
// `init_qint(...)` calls so user-visible expressions like `5 + foo()`
// survive the transform unchanged.
#pragma once

#include <string>

namespace clang {
class Expr;
class SourceManager;
class LangOptions;
}  // namespace clang

namespace qct {

// Returns the original token-range source text covering `e`, exactly
// as it appears in the input buffer. Returns the empty string when
// `e` is null or its source range is invalid (e.g. compiler-synthesised
// expressions with no real on-disk location).
std::string getExprText(const clang::Expr *e,
                        const clang::SourceManager &sm,
                        const clang::LangOptions &lo);

}  // namespace qct
