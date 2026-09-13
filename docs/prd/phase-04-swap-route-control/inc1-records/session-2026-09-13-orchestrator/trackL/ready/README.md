# `ready/` — the bd `boi6` **H-10 pins**, ready to land unchanged

Written 2026-09-13 by the Track-L SCOPING agent. Everything here was measured on the frozen
**ORACLE** `build/ir-pass/cq-opt` sha256 `fbbe0820ef4b176a…` (`libCQPass.so` `40e9c7a51e8120bb…`,
built from `e96f89c`). **`lit` and `ctest` were NOT run — the scoping row of `PROTOCOL.md` forbids
them.** What WAS run, on these exact files:

```
# the two fixtures, through the pass, as lit would (minus FileCheck):
build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering \
    -S ready/control_phase_kickback_rail_inloop_carried_theta_first.ll            # exit 0
build/ir-pass/cq-opt … -S ready/control_phase_kickback_rail_inloop_carried_theta_first_negated.ll  # exit 0
# every CHECK line in both files was copied from that output, never guessed.

# the two slices, the whole e2e pipeline, STRICT stage 2b:
clang -Iinclude -include CQ.h -O1 -emit-llvm -S ready/slice_…_carried_theta_first.c -o s1.ll
cq-opt … -S s1.ll -o s2.ll                                   # exit 0, 50 lowered lines
python3 tools/free_pairing_check.py s2.ll
#   1 rail mint(s) of which 1 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven
clang s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o a && ./a
diff <trace> ready/slice_…_carried_theta_first.expected.log              # IDENTICAL
#   …_unrolled: exit 0, 42 lowered lines, same STRICT 2b line, golden IDENTICAL
diff ready/slice_…_carried_theta_first.expected.log \
     ready/slice_…_carried_theta_first_unrolled.expected.log             # IDENTICAL -> the compare_files gate passes
```

**K-independence (the ROLLED claim), measured without `-g`** — debug metadata inflates the count,
so a number taken with `-g` is not comparable:

| source | lowered IR lines | trace lines |
|---|---|---|
| `p2.c` (the slice's shape), K=3 | **50** | 9 |
| `p2k1000.c` (the same at K=1000) | **50** | 2003 |
| `p2u.c` (hand-unrolled K=3) | 42 | 9 |

The IR is byte-for-byte the same module at K=3 and K=1000 except for the trip-count constant: one
`cqrt_alloc_i1` in the preheader, one `cqrt_ry_i1` + one `cqrt_rz_i1` in the single body block.

## The six files and where they go

| file | destination | note |
|---|---|---|
| `control_phase_kickback_rail_inloop_carried_theta_first.ll` | `ir-pass/test/` | glob-picked; no CMake edit |
| `control_phase_kickback_rail_inloop_carried_theta_first_negated.ll` | `ir-pass/test/` | `cqrt_rz_i1(%h, −θ)`, sign bit only |
| `slice_control_phase_bool_carried_theta_first.c` | `tests/e2e/` | the ROLLED slice |
| `slice_control_phase_bool_carried_theta_first.expected.log` | `tests/e2e/` | 9 lines, measured |
| `slice_control_phase_bool_carried_theta_first_unrolled.c` | `tests/e2e/` | the hand-unrolled twin |
| `slice_control_phase_bool_carried_theta_first_unrolled.expected.log` | `tests/e2e/` | 9 lines, byte-identical |
| `CMakeLists.lines.txt` | append to `tests/e2e/CMakeLists.txt` | 3 entries: 2 slices + 1 `compare_files` twin gate, placed after `e2e-phase-bool-loop-twin-identical` (line 5181 at `01c89b5`) |

Counts after landing: `ir-pass/test/*.ll` 1893 → **1895**; `tests/e2e/*.expected.log` 355 → **357**;
ctest 403 → **406**. (Source of truth is `ctest -N` and `ls | wc -l` — re-measure, do not quote.)

## What the landing agent still owes

1. `cd build && lit -v ir-pass/test --filter 'carried_theta_first'` — **2 fixtures, must be green on
   the unmodified pass**; these pin a SHIPPED accept and are RED on nothing. That is the point
   (CLAUDE.md Rule 12(c) inverted: a pin whose subject already works is still the discriminator).
2. `ctest --test-dir build -R 'carried-theta-first'` — 3 entries.
3. The injection matrix over the two fixtures (an injected `cqrt_x` on the register, an extra
   `cqrt_free`, an extra uncontrolled `cqrt_ry` on the condition register, a `cqrt_cswap`, a rail
   handle in a classical immediate slot, **and a gate moved OUT of the loop body** — SCOPE_boi6 §5)
   and report MISSED. The `RYCNT`/`ACNT`/`MDCNT`/`MDTAG` prefixes exist for exactly the
   moved-gate and extra-gate mutants; `NOROUTE-NOT: phi i1` exists for "the collapse did not run".
4. No other gate: nothing in the pass changed, so `cq-opt-equivalence-full` is not owed
   (PROTOCOL.md's table — it is owed only when a decline string or analysis site moves).
