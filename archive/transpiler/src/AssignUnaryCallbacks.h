// AssignUnaryCallbacks: MatchFinder callbacks for Phase 3 M8's
// Pattern 7 / 8 (assignment) and Pattern 9 (standalone unary inc/dec)
// rewriters. These live outside `Matcher.cpp` to keep that file under
// its 300-LOC ceiling — the Phase 2 DeclStmt and Cast callbacks own
// the same number of LOC but are kept inside Matcher.cpp because
// removing them would be more disruptive (they predate the M7/M8
// modular split).
//
// Both callbacks share the same single-rewrite shape:
//   - dyn_cast the bound AST node,
//   - re-check the bound VarDecl carries the quantum annotation
//     (the matcher's hasAttr predicate accepts any AnnotateAttr),
//   - delegate to the corresponding build*Rewrite() helper for the
//     actual emission,
//   - apply the rewrite via Rewriter::ReplaceText and register the
//     FileID in `rewrittenFiles` so EndSourceFileAction can prepend
//     `#include <CQ.h>` once per affected TU.
#pragma once

#include <set>

#include <clang/ASTMatchers/ASTMatchFinder.h>
#include <clang/Basic/SourceLocation.h>
#include <clang/Rewrite/Core/Rewriter.h>

namespace qct {

// Callback for `binaryOperator(isAssignmentOperator(), …)` matches.
// Delegates to `buildAssignRewrite` for Pattern 7 / 8 emission.
class AssignCallback
    : public clang::ast_matchers::MatchFinder::MatchCallback {
public:
    AssignCallback(clang::Rewriter *rewriter,
                   std::set<clang::FileID> *rewrittenFiles);
    void run(const clang::ast_matchers::MatchFinder::MatchResult &result)
        override;

private:
    clang::Rewriter *rewriter_;
    std::set<clang::FileID> *rewrittenFiles_;
};

// Callback for `unaryOperator(…)` matches with a quantum operand.
// Delegates to `buildUnaryRewrite` for Pattern 9 (standalone inc/dec)
// emission. The pure-unary forms (`-a`, `~a`, `!a`) embedded in larger
// expressions are NOT handled here — AssignRewrite's RHS decoration
// covers them transparently. See `UnaryRewrite.h` for the inc/dec-as-
// value-of-assignment deferral.
class UnaryCallback
    : public clang::ast_matchers::MatchFinder::MatchCallback {
public:
    UnaryCallback(clang::Rewriter *rewriter,
                  std::set<clang::FileID> *rewrittenFiles);
    void run(const clang::ast_matchers::MatchFinder::MatchResult &result)
        override;

private:
    clang::Rewriter *rewriter_;
    std::set<clang::FileID> *rewrittenFiles_;
};

}  // namespace qct
