# Quantum-C Transpiler v1 — Implementation Plan

Companion to [PRD.md](PRD.md). Optimized for: TDD, modules ≤ 300 LOC, clear separation between pure logic (unit-testable without a Clang invocation) and AST-touching glue (covered by end-to-end fixtures).

---

## 1. Guiding principles

1. **Tests precede implementation.** Each module ships with its tests in the same commit/PR; the test file is written first and starts red.
2. **Pure functions wherever possible.** AST-touching glue is thin; the heavy logic (type mapping, codegen string assembly, operand classification given an abstract input) is pure C++ and unit-testable without spinning up a `CompilerInstance`.
3. **One responsibility per module, ≤ 300 LOC per `.cpp`/`.h` pair (target ≤ 200).** If a module grows past 300, split it.
4. **End-to-end (e2e) tests are the source of truth for acceptance.** Unit tests catch logic regressions; e2e tests catch integration regressions and back the PRD's acceptance criteria.
5. **No premature features.** Anything outside the four PRD patterns is not implemented and not stubbed.

---

## 2. Final file layout

```
test_C_libtooling/
├── CMakeLists.txt              (existing — untouched)
├── main.c                       (existing — untouched, broader sandbox)
├── PRD.md
├── PLAN.md                      (this file)
├── qint.h                       (NEW — stub backend header)
├── example_v1.c                 (NEW — canonical v1 input)
├── example_v1.expected.c        (NEW — golden output for acceptance test)
└── transpiler/
    ├── CMakeLists.txt           (NEW — separate target, finds LLVM/Clang)
    ├── README.md                (NEW — short build/run note)
    ├── src/
    │   ├── main.cpp             (~80 LOC — driver: OptionsParser + ToolInvocation)
    │   ├── TypeMap.h/.cpp       (~60 LOC — C type → num_bits)
    │   ├── QuantumAttr.h/.cpp   (~60 LOC — VarDecl → is-quantum predicate)
    │   ├── SourceText.h/.cpp    (~80 LOC — Expr → original source text)
    │   ├── OperandClass.h/.cpp  (~120 LOC — Expr → Quantum | Classical)
    │   ├── Codegen.h/.cpp       (~250 LOC — VarDecl + init info → rewritten string)
    │   ├── DeclStmtRewrite.h/.cpp (~150 LOC — DeclStmt → final source replacement)
    │   └── Matcher.h/.cpp       (~120 LOC — MatchFinder wiring + callback)
    └── tests/
        ├── CMakeLists.txt
        ├── unit/
        │   ├── test_type_map.cpp
        │   ├── test_codegen.cpp
        │   └── test_source_text.cpp
        └── e2e/
            ├── run_e2e.sh              (driver script; CTest target)
            ├── acceptance.sh           (full PRD criterion 2-4 run)
            └── fixtures/
                ├── 01_uninit/input.c          + expected.c
                ├── 02_init_literal/input.c    + expected.c
                ├── 03_init_classvar/input.c   + expected.c
                ├── 04_q_plus_q/input.c        + expected.c
                ├── 05_q_plus_literal/input.c  + expected.c
                ├── 06_q_plus_classvar/input.c + expected.c
                ├── 07_multi_decl/input.c      + expected.c
                └── 08_full_example/input.c    + expected.c  (== example_v1.*)
```

Targets in `transpiler/CMakeLists.txt`:
- `quantum_transpiler` — the libtooling executable
- `quantum_transpiler_unit_tests` — GoogleTest binary linking the modules
- `check-quantum` — CTest target running unit + e2e

---

## 3. Module specifications

Each spec lists: responsibility, public API, dependencies, and what the unit tests must cover. Modules are listed in build order.

### 3.1 `TypeMap` (pure, no Clang dep beyond `BuiltinType` kind enum)

**Responsibility.** Map a C type to its `num_bits` per the PRD's bit-width table.

**Public API.**
```cpp
namespace qct {
// Returns num_bits for the bit-width table; 0 if unsupported.
unsigned numBitsForBuiltin(clang::BuiltinType::Kind k);
// Convenience over a clang::QualType (unwraps typedefs/quals).
unsigned numBitsForType(clang::QualType qt);
}
```

**Unit tests.** Table-driven: `Bool→1, Char_S/Char_U→8, Short/Int→16, Long→32, LongLong→64, Float→0, Double→0`.

**LOC target.** ~60.

---

### 3.2 `QuantumAttr` (thin Clang predicate)

**Responsibility.** Decide whether a given `VarDecl` (or `DeclRefExpr`) refers to a `quantum`-annotated variable.

**Public API.**
```cpp
bool hasQuantumAttr(const clang::VarDecl *vd);
bool refersToQuantumVar(const clang::Expr *e);  // unwraps ParenExpr, ImplicitCastExpr
```

**Unit tests.** Use a tiny in-process AST built with `clang::tooling::buildASTFromCode` over canned snippets (annotated vs not). Assert the predicate against the `VarDecl`s extracted via AST matchers.

**LOC target.** ~60.

---

### 3.3 `SourceText` (Clang Lexer wrapper)

**Responsibility.** Given any `Expr`, return the original token-range source text. Used to inline classical operands verbatim inside `init_qint(...)`.

**Public API.**
```cpp
std::string getExprText(const clang::Expr *e,
                        const clang::SourceManager &sm,
                        const clang::LangOptions &lo);
```

Implementation: `clang::Lexer::getSourceText(CharSourceRange::getTokenRange(e->getSourceRange()), sm, lo)`, falling back to empty string on invalid range.

**Unit tests.** `buildASTFromCode("int x = 5 + foo();")`, then extract the initializer `Expr*` for `x` and assert text equals `"5 + foo()"`. Repeat for literals, paren expressions, and a multi-line expression.

**LOC target.** ~80.

---

### 3.4 `OperandClass` (the classifier)

**Responsibility.** Given a `BinaryOperator*` whose result will be quantum, classify each operand as `Quantum` (a `DeclRefExpr` to a `quantum`-annotated `VarDecl`) or `Classical` (everything else within the v1 supported subset). Skips through `ParenExpr`/`ImplicitCastExpr`.

**Public API.**
```cpp
enum class OperandKind { Quantum, Classical };
struct OperandInfo {
    OperandKind kind;
    const clang::Expr *expr;       // the unwrapped expression
};
OperandInfo classify(const clang::Expr *e);
```

**Unit tests.** Build ASTs for: quantum var, classical var, literal, paren-wrapped quantum var, implicit cast. Each maps to the expected `OperandKind`.

**LOC target.** ~120.

---

### 3.5 `Codegen` (the heart — pure string assembly)

**Responsibility.** Given the *information* about one quantum `VarDecl`, return the single-statement rewritten string `qint_t x = …;`. Knows nothing about how to query the AST — its input is a plain struct so it's trivially unit-testable.

**Public API.**
```cpp
struct VarRewriteInput {
    std::string name;           // "x"
    unsigned numBits;           // from TypeMap
    enum class Form {
        Uninit,                 // pattern 1
        ClassicalInit,          // pattern 2 — initText is the expression text
        QuantumPlusQuantum,     // pattern 3 — lhsName, rhsName
        QuantumPlusClassical,   // pattern 4 — lhsName + rhsText
        ClassicalPlusQuantum,   // pattern 4 (commuted) — lhsText + rhsName
    } form;
    std::string initText;       // for ClassicalInit
    std::string lhsName, rhsName;
    std::string lhsText, rhsText;
};
std::string renderVar(const VarRewriteInput &in);
// For a DeclStmt: join one renderVar per VarDecl with " " separator.
std::string renderDeclStmt(const std::vector<VarRewriteInput> &vars);
```

**Unit tests.** One table-driven test per `Form`, plus one multi-decl test. Examples:
- `{name:"x", numBits:16, form:Uninit}` → `"qint_t x = init_qint(0, 16);"`
- `{name:"x", numBits:16, form:ClassicalInit, initText:"3+f()"}` → `"qint_t x = init_qint(3+f(), 16);"`
- `{name:"c", numBits:16, form:QuantumPlusQuantum, lhsName:"a", rhsName:"b"}` → `"qint_t c = add(a, b);"`
- `{name:"c", numBits:16, form:QuantumPlusClassical, lhsName:"a", rhsText:"5"}` → `"qint_t c = add(a, init_qint(5, 16));"`
- Multi-decl `[uninit a, classicalInit b=2]` → `"qint_t a = init_qint(0, 16); qint_t b = init_qint(2, 16);"`

**LOC target.** ~250.

---

### 3.6 `DeclStmtRewrite` (the AST-to-Codegen-input bridge)

**Responsibility.** Inspect a matched `DeclStmt`, build a `VarRewriteInput` for each contained quantum `VarDecl`, hand them to `Codegen::renderDeclStmt`, and return both the replacement string and the `SourceRange` to overwrite.

**Public API.**
```cpp
struct StmtRewrite {
    clang::SourceRange range;      // full DeclStmt range incl. semicolon
    std::string replacement;
};
std::optional<StmtRewrite> buildRewrite(const clang::DeclStmt *ds,
                                        const clang::ASTContext &ctx);
```

Internally:
- Walk `VarDecl`s in the `DeclStmt`. Skip non-quantum (unexpected in v1 but defensive).
- For each `VarDecl`, decide the `Form`:
  - No initializer → `Uninit`.
  - Initializer is a `BinaryOperator` with opcode `BO_Add` → use `OperandClass` on both sides:
    - Q + Q → `QuantumPlusQuantum`
    - Q + C → `QuantumPlusClassical`
    - C + Q → `ClassicalPlusQuantum`
    - C + C → `ClassicalInit` with initText = full expression
  - Any other initializer → `ClassicalInit` with initText = expression source text.
- Use `Lexer::getLocForEndOfToken` to extend the `DeclStmt`'s end-of-range past the trailing `;`.

**Unit tests.** Run `buildASTFromCode` on each fixture's input, match the `DeclStmt`, call `buildRewrite`, assert the returned replacement string equals the matching e2e fixture's expected snippet. (This is effectively a programmatic e2e test, but at module-API level.)

**LOC target.** ~150.

---

### 3.7 `Matcher` (libtooling integration)

**Responsibility.** Register an AST matcher for `declStmt(forEachDescendant(varDecl(hasAttr(attr::Annotate))))` (filtered by `hasQuantumAttr`), bind it, and on each match dispatch to `DeclStmtRewrite::buildRewrite` and apply the result via `clang::Rewriter`.

Also responsible for inserting a single `#include "qint.h"` at the top of each rewritten translation unit (once, tracked by a `std::set<FileID>` to avoid duplicate inserts).

**Public API.**
```cpp
class QuantumRewriteAction : public clang::ASTFrontendAction {
    // … standard libtooling boilerplate
};
```

**Unit tests.** Not unit-tested directly — covered by e2e tests.

**LOC target.** ~120.

---

### 3.8 `main.cpp` (driver)

**Responsibility.** Standard libtooling `main`: `CommonOptionsParser`, `ClangTool`, `newFrontendActionFactory<QuantumRewriteAction>()`. Writes rewritten output to stdout (or `-o <file>` if a CLI flag is added — kept simple in v1: output goes to stdout, e2e script redirects).

**LOC target.** ~80.

---

## 4. Backend files

### 4.1 `qint.h`

Self-contained header. Contents:
- `qint_t` struct (copied from [main.c:5-11](main.c#L5-L11)).
- Forward decls: `int amplitude(int); int phase(int);` — present so user source referencing them compiles, even though they aren't exercised by v1 rewrites.
- `static inline qint_t init_qint(int64_t value, unsigned num_bits)` — prints `"init_qint(<value>, <num_bits>)\n"`, returns `qint_t{ .qubits=NULL, .num_bits=num_bits, .value=value, .mask=0, .is_unsigned=false }`.
- `static inline qint_t add(qint_t a, qint_t b)` — prints `"add\n"`, returns a default `qint_t`.

Header-only `static inline` so no separate `.c` is required.

### 4.2 `example_v1.c`

Exercises all four patterns plus the multi-decl form. Skeleton:

```c
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    quantum int x;                  // pattern 1
    quantum int y = 5;              // pattern 2 (literal)
    int classic = 7;
    quantum int z = classic;        // pattern 2 (classical var)
    quantum int a = 3, b = 2;       // multi-decl, both pattern 2
    quantum int c = a + b;          // pattern 3 (Q + Q)
    quantum int d = a + 5;          // pattern 4 (Q + classical literal)
    quantum int e = a + classic;    // pattern 4 (Q + classical var)
    return 0;
}
```

`example_v1.expected.c` is its hand-written rewritten counterpart, used as the acceptance golden file.

---

## 5. Test strategy

### 5.1 Unit tests (GoogleTest, linked into one binary)

| Module | Tests |
|---|---|
| `TypeMap` | 6 cases covering the PRD table + 1 negative (`double` → 0). |
| `QuantumAttr` | quantum vs non-quantum `VarDecl`; `DeclRefExpr` walking through paren/cast. |
| `SourceText` | Literal, identifier, binop, paren, multi-line expression. |
| `OperandClass` | Q, C-literal, C-var, paren(Q), implicit-cast(Q). |
| `Codegen` | One per `Form` + 1 multi-decl + 1 ClassicalPlusQuantum case. |
| `DeclStmtRewrite` | One per e2e fixture, asserting replacement string from in-process AST. |

Build with `find_package(GTest)`. CTest target `quantum_unit`.

### 5.2 End-to-end tests (shell + diff)

`run_e2e.sh` iterates fixtures and:

```
for dir in tests/e2e/fixtures/*/; do
    actual=$(./quantum_transpiler "$dir/input.c" -- -D quantum=)
    diff -u "$dir/expected.c" <(echo "$actual") || fail
done
```

(Note: `-D quantum=` strips the macro for the *parsing* arguments since the tool needs the `__attribute__((annotate(...)))` expanded; alternatively, the input includes the `#define` directly — TBD during phase 1, whichever is cleaner with libtooling's preprocessing.)

### 5.3 Acceptance test (PRD criteria 2-4)

`acceptance.sh`:

```
./quantum_transpiler example_v1.c -- > example_v1.actual.c
diff -u example_v1.expected.c example_v1.actual.c
cc -std=c11 -include qint.h example_v1.actual.c -o example_v1.out
./example_v1.out > example_v1.actual.log
diff -u example_v1.expected.log example_v1.actual.log
```

Where `example_v1.expected.log` is a hand-written file listing the expected stub-debug output lines in order.

---

## 6. Phased implementation (TDD ordering)

Each phase ends with all tests green and a working transpiler for the patterns implemented so far. Out-of-scope patterns are left untouched per the PRD.

| Phase | Deliverable | Tests added |
|---|---|---|
| **P0** | Project skeleton: `transpiler/CMakeLists.txt` finds LLVM, builds an empty `main.cpp` that prints help. CI hook (or `make check-quantum`). | Build smoke test only. |
| **P1** | `qint.h` + `example_v1.c` + `example_v1.expected.c` + `example_v1.expected.log`. Hand-author all three. Compile `qint.h` standalone via a one-line `cc` sanity check. | Sanity: `cc -include qint.h -x c /dev/null -E` parses cleanly. |
| **P2** | `TypeMap` module + tests. | `test_type_map.cpp`. |
| **P3** | `QuantumAttr` + `SourceText` modules + tests. | `test_source_text.cpp` (covers both). |
| **P4** | `OperandClass` + tests. | `test_operand_class.cpp`. |
| **P5** | `Codegen` (pure) + tests. All five `Form`s and multi-decl pass at unit level. | `test_codegen.cpp`. |
| **P6** | `DeclStmtRewrite` + tests. `Matcher` + driver wired up. Pattern 1 fixture (`01_uninit`) passes e2e. | `test_decl_stmt_rewrite.cpp` + first e2e fixture. |
| **P7** | Add fixtures 02, 03 (pattern 2 variants). Iterate Codegen/DeclStmtRewrite if anything bends. | 2 new fixtures. |
| **P8** | Fixtures 04, 05, 06 (patterns 3 and 4). | 3 new fixtures. |
| **P9** | Fixture 07 (multi-decl). May require small fixes to `DeclStmtRewrite`'s range computation. | 1 new fixture. |
| **P10** | Fixture 08 == full `example_v1`. `#include "qint.h"` insertion lands here. Run `acceptance.sh`. PRD criteria 2-4 green. | Acceptance script. |
| **P11** | `transpiler/README.md`. Reference from `PRD.md` deliverables list. | None. |

---

## 7. Risk register

| Risk | Mitigation |
|---|---|
| `Rewriter::ReplaceText` on a `DeclStmt` whose source range stops *before* the trailing `;`. | Use `Lexer::getLocForEndOfToken(ds->getEndLoc(), 0, SM, LO)` and add 1 for the semicolon, validated by fixture 01. |
| Macro `quantum` not visible as `AnnotateAttr` if invoked with wrong preprocessor flags. | E2E driver passes `-- -D quantum=__attribute__((annotate(\"quantum\")))` if the file relies on the `#define`; otherwise the file `#define`s it directly. Resolved in P1. |
| `getSourceText` returning a stale buffer for macro-expanded operands. | Out-of-scope: PRD operands are literals and plain identifiers. Document the limitation in README. |
| LLVM/Clang dev install location varies per machine. | `find_package(Clang CONFIG REQUIRED)` with a documented `-DLLVM_DIR=` / `-DClang_DIR=` override in `transpiler/README.md`. |
| Multi-decl semicolon placement: each rewritten init must end in its own `;`. | `Codegen::renderDeclStmt` joins with a space; replacement overwrites the whole original `DeclStmt` including its single trailing `;`. Covered by fixture 07. |

---

## 8. Non-goals (PRD-aligned)

Explicitly **not** implemented in v1, even if tempting during the phases above:
- Any operator other than `+`.
- `amplitude` / `phase` rewrites.
- Quantum control flow, casts, arrays, function passing, floats.
- Error diagnostics for unsupported constructs (silent pass-through is correct per PRD).
- Touching [main.c](main.c) or the existing root [CMakeLists.txt](CMakeLists.txt).

---

## 9. Definition of done

All of:
1. `cmake --build build --target check-quantum` runs all unit and e2e tests, all green.
2. `acceptance.sh` produces a binary whose output exactly matches `example_v1.expected.log`.
3. Every `.cpp`/`.h` pair in `transpiler/src/` is ≤ 300 LOC.
4. `transpiler/README.md` documents: prerequisites (LLVM/Clang ≥ 16 dev install), configure command, build target list, how to run a single fixture.
