# CLOSING MEASUREMENTS — session 2026-09-14, main @ `66428ddc`

Closing-measurement agent. Everything below was **run on this machine**, in the
main checkout `/Users/sorenwilkening/Desktop/CQ_lang`, on `main` at HEAD
`66428ddc`. Every claim carries the command that produced it (Rule 19). No file
under `ir-pass/ include/ runtime/ tests/ tools/` was edited; nothing was
committed or pushed.

---

## THE HEADLINE

**The owner's file compiles. `opt` exit 0, stderr 0 bytes, 35 trace lines, and
the trace is BYTE-IDENTICAL to the shipped golden.**

The owner's report was correct **and** the diagnosis was correct: the primary
`build/` was holding the frozen **pre-merge ORACLE** binary. It had not been
rebuilt since the six increments landed. Nothing else moved.

| | before rebuild (what the owner saw) | after rebuild |
|---|---|---|
| `cq-opt` sha256 | `f7b65d8ccd7bc472…` (pre-merge oracle) | `5c6f7490a81c7505…` |
| `libCQPass.so` sha256 | `f9e898badfd4207a…` | `5276f7ab7416b36b…` |
| `example/grover/grover_oracle_uncompute.c` | **exit 1**, declines | **exit 0**, stderr empty |

Both rebuilt hashes reproduce the merge gate's expected values
(`cq-opt 5c6f7490a81c7505…` / `libCQPass.so 5276f7ab7416b36b…`) **exactly**, so
main's tree and the gated tree produce the same binary bit for bit.

---

## 1. Baseline — the state the owner was measuring

```
$ shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so
f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc  build/ir-pass/cq-opt
f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d  build/ir-pass/libCQPass.so
```

That is the **frozen pre-merge oracle** named in the brief. On it:

```
$ LLVM=/usr/local/opt/llvm@19/bin
$ "$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S \
      example/grover/grover_oracle_uncompute.c -o /tmp/base.s1.ll      # exit 0
$ build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so \
      -passes=cq-lowering -S /tmp/base.s1.ll -o /tmp/base.s2.ll
exit=1
```

stderr, **185 bytes, verbatim**:

```
error: example/grover/grover_oracle_uncompute.c:93:14: in function main i32 (): cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
```

Line 93 col 14 is `b0 = cq_theta(b0, 0.5);` — i.e. the **F2 state-prep fence**,
anchored on `b0`'s theta and **not** on the region that declined, which is
exactly the anchoring behaviour recorded in the header of
`tests/e2e/slice_control_cascade_three_bools.c` and the shape bd `om35` closed.
So the baseline decline is the **known pre-`om35` string**, not a new one.

## 2. Rebuild

```
$ cmake --build build -j8            # full build, NOT --target CQPass alone
... [100%] Built target CQPass       # 1:13 wall, 2 pre-existing -Wunused-parameter warnings
$ shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so
5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8  build/ir-pass/cq-opt
5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4  build/ir-pass/libCQPass.so
```

**Both match the merge gate's expected hashes.** No STOP-AND-REPORT condition.
The two compiler warnings (`TaintPropagation.cpp:304` `PhiFns`,
`:2046` `M`) are pre-existing unused-parameter notes, not new.

## 3. The owner's real file, unmodified, at its own path

```
$ "$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S \
      example/grover/grover_oracle_uncompute.c -o /tmp/g.s1.ll
$ build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so \
      -passes=cq-lowering -S /tmp/g.s1.ll -o /tmp/g.s2.ll
exit=0
--- stderr bytes:        0 ---
$ python3 tools/free_pairing_check.py /tmp/g.s2.ll
free_pairing_check: 1 file(s), 9 rail mint(s) of which 7 left allocated, \
3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven
$ "$LLVM/clang" /tmp/g.s2.ll build/runtime/libcq_templates.a \
      build/runtime/libcq_runtime.a -o /tmp/g && /tmp/g
```

- **exit code: 0**
- **stderr: 0 bytes** — no error, and **no warning** either
- **trace: 35 lines**
- **stage 2b (STRICT, no `--allow-unproven`): `9 rail mint(s) of which 7 left
  allocated, 3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven`**

Link and run were both exit 0 (the three `ld: warning: object file … built for
newer 'macOS' version` lines are the pre-existing ones documented in
`CLAUDE.md`; run stderr was empty).

## 4. Trace comparison against the shipped golden

```
$ diff /tmp/g.trace.log tests/e2e/slice_control_cascade_three_bools.expected.log
BYTE-IDENTICAL (diff exit=0)
sha256 owner-trace: 3c1dda4a48e8d2ca903d2921f9bf4c9566e57af7d5ba22c3954d537e01748a09
sha256 golden:      3c1dda4a48e8d2ca903d2921f9bf4c9566e57af7d5ba22c3954d537e01748a09
```

**Identical, all 35 lines.** The invariants the fixture header says to read off
the golden hold on the owner's own file: `h0` and `h5` (the user's registers)
appear only as CNOT arg-0 controls, as the control of `cqrt_ry_i1_controlled`,
or in a measure — never `cqrt_x`-bracketed, never freed; every `cqrt_x` is on
an ancilla (`h1`, `h7`) whose `x ⊕ x = 0` return makes its free a proven-`|0⟩`
one; `h9` is the third region's flag, one mint / one strip / one free.

The owner's file differs from the shipped slice only in harness-level spellings
— `#include <math.h>`, `main` vs `slice`, `bool` vs `_Bool`, and `(int)` casts
on three measures. The **live quantum code lines are identical**, and `b0` is
**initialised** (`bool b0 = 0;`) in the file as it stands today.

### 4b. The bd `z9t1` RETIREMENT TRIGGER HAS FIRED

The slice header carries an L8 retirement trigger saying the uninitialised
`_Bool b0;` spelling compiles but "differs in exactly ONE literal"
(`cqrt_alloc_i1(1)` on line 1), and that the difference disappears when bd
`z9t1` lands. `z9t1` **did** land, at `f28e435a`. Measured on the rebuilt
binary, with the only edit being `bool b0 = 0;` → `bool b0;` in a `/tmp` copy:

```
undef-spelling exit=0, stderr 0 bytes
free_pairing_check: 9 rail mint(s) of which 7 left allocated, 3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven
diff undef-trace vs golden → BYTE-IDENTICAL
```

So the trigger's prediction was **character-for-character correct**, and the
fixture header's sentence "the trace differs in exactly ONE literal" is now
**stale on this binary** (the two spellings are byte-identical). That is a
DOC-ONLY follow-on in `tests/e2e/slice_control_cascade_three_bools.c`; this
agent did not edit it (hard constraint).

## 5. Full suite on the rebuilt primary

```
$ ctest --test-dir build -j6 --output-on-failure
100% tests passed, 0 tests failed out of 442
Total Test time (real) = 436.73 sec
```

**442/442 — main reproduces the merge gate's result exactly.** No failure, so
no serial re-run was needed. The 436 s wall is the loaded/warm figure with
`e2e-loop-twin-matrix` as the long pole at 436.70 s (it starts first and
finishes last); the suite's real elapsed time equals that test's.

## 6. Closing counts, measured at `66428ddc` on the rebuilt tree

```
$ ctest --test-dir build -N | grep -c '^  Test'                      → 442
$ ctest --test-dir build -N | grep -c 'e2e-'                         → 432
$ ctest --test-dir build -N | grep -c 'e2e-slice-'                   → 381
$ ctest --test-dir build -N | grep -c 'twin-identical'               →  40
$ ls ir-pass/test/*.ll | wc -l                                       → 1994
$ ls tests/e2e/*.expected.log | wc -l                                → 383
$ grep -c '^m_' tools/loop_twin_matrix.expected.txt                  → 309
$ grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt             →  29
                                            twin-matrix cells total  → 338
```

For reference, 2026-09-13 at `59ac5b7`: 420 · 410 · 365 · 34 · 1928 · 367 ·
259+29 = 288 cells. The twin matrix grew 288 → 338 because bd `uq96`
(`49b7f7bc`) gave it an `i1` axis. Re-measure rather than quote these.

---

## THE ONE LESSON

The owner's file never stopped compiling; the **binary under it was three
increments old**. A stale `build/` is indistinguishable from a regression from
the outside — the decline string it printed was a real, correct, historically
accurate diagnostic, just one emitted by a compiler that predates the fix. The
cheap discriminator is the hash: `shasum -a 256 build/ir-pass/cq-opt` **before**
believing any decline, and the sibling trap is the one `CLAUDE.md` already
records — `--target CQPass` alone leaves `cq-opt` stale and lit reports false
green. The same symptom, two directions: a stale `cq-opt` makes a *fixed*
program look broken here, and makes a *broken* pass look green in lit.
