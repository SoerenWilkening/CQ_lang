// Unit tests for DeclStmtRewrite. Build a real in-process AST via
// `buildASTFromCodeWithArgs`, walk it to collect DeclStmts, then call
// `qct::buildRewrite` and assert the returned replacement string equals
// the byte-exact Phase 1 emission for the matching pattern.
//
// Per PLAN §4.4.3 the dispatch in `populateFromInit` collapses the v1
// four-way QQ/QC/CQ/CC binop classification: any add with at least one
// quantum operand produces a single `QuantumAdd` form, and the C+C
// fallback splices the whole binop into `cq_init_<W>(...)`. The cases
// covered below are the canonical list in PLAN §4.4.3:
//
//   - Pattern 1   uninitialized            quantum int x;
//   - Pattern 2   classical literal init   quantum int x = 7;
//   - Pattern 2   classical var init       quantum int x = c;
//   - Pattern 3   Q+Q add                  quantum int z = a + b;
//   - Pattern 4   Q+C add                  quantum int z = a + 5;
//   - Pattern 4   C+Q add (commuted)       quantum int z = 5 + a;
//   - Multi-decl join                      quantum int a = 3, b = 2;
//   - Defensive   non-quantum DeclStmt early-out
//
// The widthSuffix flows from `TypeMap::irWidthSuffix(QualType, TargetInfo)`,
// which on the default in-process target resolves `int` to "i32"; the
// `DeclStmtRewrite` call site then prefixes "s" (Phase 2 M3 transitional;
// see DeclStmtRewrite.cpp:170) to give the signedness-bearing intrinsic
// suffix "si32" that's spliced into the emitted symbol names below.
// The AST-walking helpers intentionally duplicate the ones in
// test_source_text.cpp and test_operand_class.cpp; factoring them into
// a shared header is its own change and explicitly out of scope.
#include <gtest/gtest.h>

#include <memory>
#include <optional>
#include <string>
#include <vector>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Stmt.h>
#include <clang/Frontend/ASTUnit.h>
#include <clang/Tooling/Tooling.h>

#include "DeclStmtRewrite.h"

namespace {

std::unique_ptr<clang::ASTUnit> parseC11(const std::string &code) {
    return clang::tooling::buildASTFromCodeWithArgs(
        code, /*Args=*/{"-std=c11"}, /*FileName=*/"input.c");
}

// Collect every DeclStmt inside any function body in the TU, in source
// order. Top-level VarDecls are NOT wrapped in DeclStmts (they appear
// directly in the AST), so this helper only walks function bodies —
// which is fine because the quantum-VarDecl rewrite is targeted at
// statement-level decls.
void collectDeclStmts(const clang::Decl *d,
                      std::vector<const clang::DeclStmt *> *out) {
    if (d == nullptr) {
        return;
    }
    const auto *fd = clang::dyn_cast<clang::FunctionDecl>(d);
    if (fd == nullptr || !fd->hasBody()) {
        return;
    }
    std::vector<const clang::Stmt *> work{fd->getBody()};
    while (!work.empty()) {
        const clang::Stmt *s = work.back();
        work.pop_back();
        if (s == nullptr) {
            continue;
        }
        if (const auto *ds = clang::dyn_cast<clang::DeclStmt>(s)) {
            out->push_back(ds);
        }
        for (const clang::Stmt *child : s->children()) {
            work.push_back(child);
        }
    }
}

std::vector<const clang::DeclStmt *> allDeclStmts(clang::ASTUnit *unit) {
    std::vector<const clang::DeclStmt *> out;
    for (auto it = unit->top_level_begin(); it != unit->top_level_end(); ++it) {
        collectDeclStmts(*it, &out);
    }
    return out;
}

// Return true iff the first VarDecl in `ds` is named `name`. Used by
// the rewriteDeclFor helper below to pick out the DeclStmt under test
// when a function body contains several. Robust to traversal order: we
// pick by variable name rather than by index into allDeclStmts (whose
// LIFO walk produces a reverse-source-order list).
bool firstDeclNamed(const clang::DeclStmt *ds, const std::string &name) {
    for (const clang::Decl *d : ds->decls()) {
        if (const auto *vd = clang::dyn_cast<clang::VarDecl>(d)) {
            return vd->getNameAsString() == name;
        }
    }
    return false;
}

// Parse `body` wrapped in `void f(void) { ... }` (with `quantum`
// pre-defined as the annotate macro), find the DeclStmt whose first
// VarDecl is named `name`, and return its rewrite. Returns nullopt if
// no such DeclStmt is found or buildRewrite declines to rewrite it.
//
// The returned StmtRewrite's `range` member references SourceLocations
// owned by the ASTUnit, which is destroyed when this helper returns —
// so tests must only assert on `replacement` (a std::string that owns
// its own storage). All tests below comply with that contract.
std::optional<qct::StmtRewrite> rewriteDeclFor(const std::string &body,
                                               const std::string &name) {
    auto unit = parseC11(
        "#define quantum __attribute__((annotate(\"quantum\")))\n"
        "void f(void) {\n" +
        body + "\n}\n");
    if (unit == nullptr) {
        return std::nullopt;
    }
    auto stmts = allDeclStmts(unit.get());
    for (const clang::DeclStmt *ds : stmts) {
        if (firstDeclNamed(ds, name)) {
            return qct::buildRewrite(ds, unit->getASTContext());
        }
    }
    return std::nullopt;
}

}  // namespace

// ---------------------------------------------------------------------------
// Pattern 1: uninitialized quantum int.
//   `quantum int x;` -> `qint_mid_t x = cq_init_si32(0);`
// ---------------------------------------------------------------------------

TEST(DeclStmtRewriteTest, UninitProducesPattern1) {
    auto r = rewriteDeclFor("    quantum int x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t x = cq_init_si32(0);");
}

// ---------------------------------------------------------------------------
// Pattern 2: classical-literal initializer.
//   `quantum int x = 7;` -> `qint_mid_t x = cq_init_si32(7);`
// The classical expression survives verbatim inside cq_init_<W>(...).
// ---------------------------------------------------------------------------

TEST(DeclStmtRewriteTest, ClassicalLiteralInit) {
    auto r = rewriteDeclFor("    quantum int x = 7;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t x = cq_init_si32(7);");
}

// ---------------------------------------------------------------------------
// Pattern 2 (classvar): classical-variable initializer.
//   `quantum int x = c;` -> `qint_mid_t x = cq_init_si32(c);`
// `c` is a plain (non-quantum) classical int, so it's spliced verbatim
// rather than decorated with `.val`. Exercises the OperandClass path
// that keeps non-binop initializers in the ClassicalInit form even when
// they reference another (classical) variable.
// ---------------------------------------------------------------------------

TEST(DeclStmtRewriteTest, ClassicalVarInit) {
    auto r = rewriteDeclFor(
        "    int c = 3;\n"
        "    quantum int x = c;",
        "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t x = cq_init_si32(c);");
}

// ---------------------------------------------------------------------------
// Pattern 3: Q+Q add.
//   `quantum int z = a + b;` -> `qint_mid_t z; z.val = a.val + b.val;`
// Both operands are quantum-annotated VarDecls; DeclStmtRewrite decorates
// each with ".val" before handing them to Codegen.
// ---------------------------------------------------------------------------

TEST(DeclStmtRewriteTest, QuantumPlusQuantum) {
    auto r = rewriteDeclFor(
        "    quantum int a = 3;\n"
        "    quantum int b = 2;\n"
        "    quantum int z = a + b;",
        "z");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t z; z.val = a.val + b.val;");
}

// ---------------------------------------------------------------------------
// Pattern 4: Q+C add (quantum lhs, classical literal rhs).
//   `quantum int z = a + 5;` -> `qint_mid_t z; z.val = a.val + 5;`
// The classical rhs is spliced verbatim from source; only the quantum
// side gets the ".val" decoration.
// ---------------------------------------------------------------------------

TEST(DeclStmtRewriteTest, QuantumPlusClassical) {
    auto r = rewriteDeclFor(
        "    quantum int a = 3;\n"
        "    quantum int z = a + 5;",
        "z");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t z; z.val = a.val + 5;");
}

// ---------------------------------------------------------------------------
// Pattern 4 commuted: C+Q add (classical lhs, quantum rhs).
//   `quantum int z = 5 + a;` -> `qint_mid_t z; z.val = 5 + a.val;`
// Same emission path, just with the decoration on the right. Defends
// against accidentally hard-coding the lhs as the quantum side.
// ---------------------------------------------------------------------------

TEST(DeclStmtRewriteTest, ClassicalPlusQuantumCommuted) {
    auto r = rewriteDeclFor(
        "    quantum int a = 3;\n"
        "    quantum int z = 5 + a;",
        "z");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t z; z.val = 5 + a.val;");
}

// ---------------------------------------------------------------------------
// Multi-decl quantum statement: `quantum int a = 3, b = 2;` becomes
// two rewritten cq_init_si32 calls separated by a single space, matching
// the Codegen::renderDeclStmt join contract from PLAN §3.5 / §4.4.2.
// Also exercised by fixture 07 in P9 — covering it at unit level here
// keeps the join logic locked in.
// ---------------------------------------------------------------------------

TEST(DeclStmtRewriteTest, MultiQuantumDeclStmt) {
    auto r = rewriteDeclFor("    quantum int a = 3, b = 2;", "a");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement,
              "qint_mid_t a = cq_init_si32(3); qint_mid_t b = cq_init_si32(2);");
}

// ---------------------------------------------------------------------------
// Defensive: non-quantum DeclStmt -> buildRewrite returns nullopt so the
// caller leaves the statement untouched. Drives the matcher's "skip
// statements that have no quantum-annotated VarDecls" early-out.
// ---------------------------------------------------------------------------

TEST(DeclStmtRewriteTest, NonQuantumDeclStmtReturnsNullopt) {
    auto unit = parseC11(
        "void f(void) {\n"
        "    int x;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto stmts = allDeclStmts(unit.get());
    ASSERT_EQ(stmts.size(), 1u);

    std::optional<qct::StmtRewrite> r =
        qct::buildRewrite(stmts[0], unit->getASTContext());
    EXPECT_FALSE(r.has_value());
}
