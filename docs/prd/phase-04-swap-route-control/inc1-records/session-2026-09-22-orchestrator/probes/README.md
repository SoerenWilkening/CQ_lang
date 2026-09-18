# Probes — session 2026-09-22 (bd `test_C_libtooling-fn1q`)

**Committed because a bisection recorded without its probes is not reproducible**
(bd `test_C_libtooling-5zwz`). bd `fn1q`'s own bisection named variants in prose,
none was committed, and three of its claims turned out to be wrong.

Binaries these were measured on:
```
ORACLE  (main e107a177)  cq-opt 3368af1262695d7e4c…  libCQPass.so 48b8b4db61777082e9…
SUBJECT (increment 1)    cq-opt 3497126f3528e8ea47…  libCQPass.so fb28f4f644641a4363…
```

| probe | what it exhibits |
|---|---|
| `owner.c` | the owner's program as bd `fn1q` records it (arrays in condition AND arm) |
| `cK_zK_pK.c` / `cA_zK_pK.c` | the 2×2×2 corners that REFUTE the bead's "Va": an array-valued THRESHOLD with a constant arm ACCEPTS (110 / 120 lowered lines) |
| `cK_zK_pA.c` / `cA_zA_pK.c` | the two declining corners and their two different strings |
| `wide4.c` / `wide2.c` | ⚠ the exhibit that says the family is not about loops, arrays or loads: a flat, loop-free, ALL-CONSTANT **four**-variable arm declines; its two-variable sibling accepts at 69 lines (bd `test_C_libtooling-s9xi`) |
| `flat_unroll.c` | the hand-unrolled twin — read its **stage-1** IR, not its verdict: `-O1` const-folds the local arrays to `select i1 %1, i32 4, i32 5` and there is no value-arm branch left to lower |
| `flat_gidx.c` | the same shape with a GLOBAL array at a runtime index, LOOP-FREE — declines, which is what actually refutes "hand-unroll it and it compiles" |
| `flat_qc_load.c` | loop-free Q+C add whose classical operand is a variable-index load — `impure value arm` on BOTH binaries, and **correctly**: (K4) cannot prove the load safe to run unconditionally |
| `cone_arith.c` / `cone_arith_pre.c` | increment 1's subject, in both source spellings — ⚠ they produce **byte-identical stage-1 IR** because `-O1` SINKS the computation into the arm |
| `armonly_p.c` | the `walkValueChain`-empty wall (a CLASSICAL accumulator), untouched by increment 1 |
| `rolled.c` / `unrolled.c` / `flat_trailing.c` / `trail_arm.c` / `trail_arm_pre.c` | the standing rolled-vs-unrolled probe with a TRAILING NON-DIAGONAL gate (protocol item 5 / G-13) |

⚠ **`rolled.c` was WRONG on its first writing and bd `46oo` is why it was caught.**
Its first version accumulated a loop-INVARIANT value, so `-O1` rewrote the
accumulation to a closed form and **deleted the loop** — `!llvm.loop` count 0.
A probe for a control-flow shape must be checked at STAGE 1 for the shape it
claims. The committed version makes the cone index-dependent (`k*i`).

## Harness

* `one.sh` — A/B one fixture on two binaries (exit code, decline string, lowered-IR sha). Per-file `mktemp` dirs so it is safe under `xargs -P6`. ⚠ `rc=$?` on the line AFTER the command, never after a pipe.
* `corpus_ab.sh` — the serial form, kept for reference.
* `mutants.sh` — the (K1)–(K4) conjunct mutation matrix, with a null boundary control that runs first.
