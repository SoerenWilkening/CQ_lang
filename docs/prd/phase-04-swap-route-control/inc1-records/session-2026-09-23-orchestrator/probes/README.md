# Probes — session 2026-09-23 (bd `test_C_libtooling-fn1q`, the re-derived fence map)

Committed because a bisection recorded without its probes is not reproducible
(bd `test_C_libtooling-5zwz`). Measured on:

```
ORACLE  main 2c08fa62  cq-opt 1b396ed08b01b8ecac7… libCQPass.so f3a372fc275bcf15f2b…
```
plus a temporary env-gated measurement build derived from it, whose patched source is
kept here verbatim as `PredMuxFlatten.relaxed-measurement.cpp.txt` (bypasses
`CQ_PREDMUX_NOE2` / `NOE6` / `NOE4`). The tree itself is pristine and the rebuilt
binary is bit-identical to the hashes above.

Build one:
```
LLVM=/usr/local/opt/llvm@19/bin
$LLVM/clang -Iinclude -include CQ.h -O1 -emit-llvm -S probes/X.c -o /tmp/X.s1.ll
CQ_PREDMUX_DBG=1 build/ir-pass/cq-opt -passes=cq-lowering -S /tmp/X.s1.ll -o /dev/null
```
⚠ `rc=$?` on the line AFTER the command, never after a pipe.

| probe | what it exhibits |
|---|---|
| `owner.c` | the owner's program (copied from the 2026-09-22 record so this directory stands alone). DECLINES at PredMux **E2 → E6 → E4**, all three. |
| `loop2phi_const.c` | ⚠ **the control that makes the whole map legible**: the same in-loop 2-carried-value shape with an ALL-CONSTANT arm **ACCEPTS on the oracle**, because `-O1` if-converts it and the select path already lowers it. |
| `loop2phi_cmp.c` | the same with `g_z[i]`/`g_p[i]` in the arm — E2, then **E4-gep** |
| `loop2phi_p2.c` | the same with **power-of-two** tables — still E4-gep, so the refusal is the QROM **index-taint** gate and not the table size |
| `loop4var_bool.c` | ⚠ reaches **E6-condtree** with **no array, no load, no memory in the arm** — the probe that proves E6 and E4 are independent axes |
| `flat2phi_b.c` | **LOOP-FREE** 2-φ value diamond, bare rail condition — declines identically to the in-loop form, which is what falsifies "P9 is the wall" |
| `flat2phi_cmp.c` | loop-free, compare condition, array arm — **E4-gep** |
| `flat2phi.c` | the first draft of the above; its merge has THREE predecessors (a classical guard survives), so it is NOT a clean diamond — kept as the reminder to check a probe at STAGE 1 for the shape it claims (bd `46oo`) |
| `owner_pre.c` | the owner's program with both loads hand-hoisted in the SOURCE — a DIFFERENT wall (`iteration-local value read after the loop`), because `-O1` if-converts it into `add(select(c, p_i, 0), P)` whose latch value is an `add`, not a bd `zujr` carried handle. **Not a usable twin.** |
| `owner_pre_ck.c` | the same with a constant threshold — still the (c3) wall, so (c3) here is not about the condition reading the array |
| `owner_int.c` | the owner's program with `int b0[3]` — declines at the RAIL BANK (`array mixes a rail cell access with an unrecognized one`). ⚠ The `bool` spelling is the supported one; do not "simplify" to `int` to make a probe easier. |
