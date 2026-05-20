# Quantum-C Transpiler — v1 PRD

## Goal

Build a clang-libtooling source-to-source transpiler that detects variables marked with a `quantum` attribute in C source and rewrites them — plus any `+` expressions involving them — into calls against a small runtime API. v1 is a proof-of-pipeline: it must demonstrate that the AST-matcher + Rewriter approach works end-to-end. The runtime is intentionally stubbed.

## Marker syntax (input)

A user's quantum C source begins with:

```c
#define quantum __attribute__((annotate("quantum")))
```

After preprocessing, clang sees `VarDecl`s carrying an `AnnotateAttr` with the string `"quantum"`. The transpiler matches on this attribute; the macro itself is not parsed specially.

## Supported source patterns (v1)

The transpiler rewrites *only* the four patterns below. Any other use of a `quantum`-annotated variable in v1 is out of scope (see "Out of scope").

| # | Source | Rewritten output |
|---|---|---|
| 1 | `quantum int x;` | `qint_t x = init_qint(0, 16);` |
| 2 | `quantum int x = E;` (E is an integer literal or classical expression) | `qint_t x = init_qint(E, 16);` |
| 3 | `quantum int x = a + b;` (both `a`, `b` are quantum) | `qint_t x = add(a, b);` |
| 4 | `quantum int x = a + E;` (`a` quantum, `E` classical literal or variable) | `qint_t x = add(a, init_qint(E, 16));` |

Multi-variable declarations (`quantum int a = 3, b = 2;`) are supported by replacing the whole `DeclStmt` with one rewritten init per variable, joined into the same source region.

Bit widths follow this table (only `int` and `bool` are exercised in v1, but the table is part of the spec):

| C type | `num_bits` arg to `init_qint` |
|---|---|
| `bool` | 1 |
| `char` | 8 |
| `short`, `int` | 16 |
| `long` | 32 |
| `long long` | 64 |

## Mixed-operand rule

In any binary operator whose result is quantum, classical operands are wrapped inline by the transpiler via `init_qint(<source-text-of-operand>, <bits>)`. This applies to literals (`5`) and to references to classical variables (`x`). The classical variable's original declaration is **not** touched. The runtime sees a uniform `qint_t × qint_t → qint_t` signature; classical-ness is encoded in the wrapped `qint_t` having `mask = 0` and no qubits allocated.

## Backend (`qint.h`) — stubs for v1

A single header `qint.h` provides:

- The `qint_t` struct (from existing `main.c`, fields: `qubits`, `num_bits`, `value`, `mask`, `is_unsigned`).
- Marker function *declarations* `int amplitude(int);` and `int phase(int);` (not used in v1's rewrite rules, but defined so the user's source compiles).
- Stub functions that each `printf` their own name and return a default-constructed `qint_t`:
  - `qint_t init_qint(int64_t value, unsigned num_bits);`
  - `qint_t add(qint_t a, qint_t b);`

`init_qint` is permitted to also store its `value` arg into the returned struct for the user's debug visibility; it must not allocate any qubits.

No other runtime functions are implemented in v1.

## Architecture

```
+-----------------+        +-----------------+        +-----------------+
|  example_v1.c   |  -->   | transpiler tool |  -->   |  rewritten .c   |  -->  cc + qint.h
|  (quantum src)  |        |  (libtooling)   |        |  (plain C)      |
+-----------------+        +-----------------+        +-----------------+
```

- **Frontend (transpiler):** C++ libtooling executable. Uses `ASTMatchFinder` to bind `declStmt` nodes containing a `VarDecl` with `AnnotateAttr("quantum")`, plus a small helper to walk binary-operator initializers. Emits rewritten source via `clang::Rewriter`.
- **Backend (`qint.h`):** stub C header, included by the rewritten output. No quantum semantics in v1.
- **Separation:** the transpiler depends on no backend symbol; the backend depends on no transpiler logic. The interface between them is the textual API documented above.

## Out of scope for v1 (deferred, see future versions)

- Any operator other than `+` (xor, and, not, comparisons).
- `amplitude(…) + k` / `phase(…) + k` rewrites (R_y / R_z).
- `if (quantum_cond) { … }` lowering to `controlled_*`.
- Nested-if folding via `and(c, d)`.
- Casts (`(int) c`) → `measure`.
- Arrays of quantum (`quantum int arr[10];`).
- Passing quantum to user-defined functions (monomorphization).
- Quantum doubles / floating point.
- Auto-uncomputation, scope/lifetime analysis.
- Transpiler-error diagnostics for unsupported constructs. In v1, unsupported constructs are simply left untouched in the output (they will likely fail downstream compilation — that's acceptable, the user is expected to feed v1 only the supported subset).

## Acceptance criteria

v1 is done when:

1. The transpiler executable builds against a local LLVM/Clang dev install.
2. Running the transpiler on a minimal `example_v1.c` containing the four supported patterns (including one multi-decl statement) produces output where every one of those patterns is rewritten correctly.
3. The rewritten output `#include "qint.h"`s the stub header and compiles with a plain C compiler without errors.
4. Running the compiled rewritten output prints the expected stub-debug lines (one `init_qint(...)` line per qint construction, one `add` line per `+`).

## Deliverables

- `qint.h` — stub backend header.
- `example_v1.c` — input file exercising the four supported patterns.
- `transpiler/transpiler.cpp` — the libtooling tool.
- `transpiler/CMakeLists.txt` — its build config (separate target; does not interfere with the existing `test_C_libtooling` C target).
- A short build/run note (can live in this PRD or a separate README).

## Note on file layout

The existing top-level `main.c` is the user's broader sandbox containing patterns beyond v1 scope. It is left untouched. v1 ships `example_v1.c` as the canonical v1 input, separate from `main.c`.
