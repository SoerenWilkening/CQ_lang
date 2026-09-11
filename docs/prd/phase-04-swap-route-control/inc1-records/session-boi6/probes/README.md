# Probes — bd `test_C_libtooling-boi6` (3qlq Inc 1b-D) scoping, 2026-09-11

Every verdict below was MEASURED on **`main` `0c7380c`** with the tree's own
`build/ir-pass/cq-opt` (`git status --porcelain` clean at the time; nothing under
`ir-pass/`, `tests/`, `tools/`, `include/` or `runtime/` was touched by this session).

Commands, verbatim:

```
/usr/local/opt/llvm@19/bin/clang -I<repo>/include -include CQ.h -O1 -emit-llvm -S pN.c -o pN.s1.ll
build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S pN.s1.ll -o pN.s2.ll
CQ_CTRL_DBG=1 build/ir-pass/cq-opt … 2>&1 | grep CQ_CTRL_DBG      # the decline ANCHOR
/usr/local/opt/llvm@19/bin/clang pN.s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o pN.exe
python3 tools/free_pairing_check.py pN.s2.ll                       # stage 2b
```

`./run.sh <dir> <name>` does stages 1–2 and prints the `-O1` shape counters.

## Verdict table (main 0c7380c)

| probe | shape | `-O1` IR | verdict |
|---|---|---|---|
| `p1` | **the bd's own shape** — carried `bool`, region BEFORE the body theta | header `phi i1`, 2 `br i1` | DECLINE `branch phase on a bare i1 condition` @ `br i1 %7` |
| `p2` | carried `bool`, body theta BEFORE the region | condition IS the in-body `cq_theta_i1` | **ACCEPT**, rolled |
| `p2u` | `p2` hand-unrolled K=3 | flat | ACCEPT — trace **byte-identical** to `p2` (`p2.trace` == `p2u.trace`) |
| `p2k1000` | `p2` at K=1000 | — | ACCEPT — **50 lowered IR lines at K=3 and at K=1000** |
| `p3` | `p1` + a second carried `int` | header `phi i1` | DECLINE, same string/anchor |
| `p4` | the one-qubit Grover LOOP (2 regions per trip) | region 1 cond = header phi; region 2 cond = in-body theta | DECLINE @ **region 1** only |
| `p4u` | `p4` hand-unrolled K=2 = `slice_control_phase_bool_grover.c` | flat | ACCEPT, 11-line trace (`p4u.trace`) |
| `p5` | a `bool` from a preceding CONTROLLED-Ry region | `%7 = phi i1 [%5,%4],[%2,%0]`, **both incomings one wire** | DECLINE `branch phase on a bare i1 condition` |
| `p6` | 4.4 DATA select on a carried `bool` in a loop | `select` in body + header phi | DECLINE `cq loop lowering: loop-carried tainted value crosses iterations` — the LOOP layer, before detection |
| `p7` | measure `b` in the body AFTER the region | header phi | DECLINE, bare-i1 |
| `p8` | `if (!b)` — NEGATED carried bool | header phi | DECLINE, bare-i1 |
| `p9` | `p2` negated (in-body rail leaf, `if (!b)`) | in-body theta cond | **ACCEPT** |
| `p10` | `if (b && q == 5)` in a loop — phi as a TREE leaf | `select i1` tree | DECLINE `control flow` @ the `br` |
| `p12` | merge phi over **two distinct** rails | `select i1` | DECLINE `control flow` |
| `p14` | merge phi whose arm incoming is a FRESH rail | — | DECLINE `state prep seed is proven equal to the condition register` |
| `p16` | `p1` hand-unrolled K=3 — **the byte-identity target** | flat | ACCEPT, 9-line trace (`p16.trace`) |
| `p17` | ITERATION-LOCAL bool minted in the body | no rail phi | DECLINE `condition measured before the control route` |
| `p18` | NESTED loops, carried bool | 2 header `phi i1` | DECLINE, bare-i1 |
| `p19` | measure `b` BEFORE the region in the body | header phi | DECLINE, bare-i1 |
| `p20` | 4.4 DATA select on a MERGE-phi bool (flat) | `select` | DECLINE `control flow` @ the **select** |
| `p21` | the preceding controlled-Ry region ALONE | merge phi | **ACCEPT** — `cqrt_ry_i1_controlled`, the merge φ RAUW'd away (M-β) |
| `p22` | `p5`'s **`int` COMPARE twin** | `phi i32` | DECLINE `condition predates a non-diagonal gate` @ the `icmp` |
| `p23` | INVARIANT bool in a loop (the shipped 1b accept) | no rail phi | ACCEPT, rolled |
| `p24` | the rail's SEED measured before the loop | header phi | DECLINE, bare-i1 |
| `p25` | TWO independent carried bools, a region on each | 2 header `phi i1` | DECLINE, bare-i1 |
| `p26` | carried bool + carried `int` rotated per trip | header phi | DECLINE, bare-i1 |
| `p28` | DYNAMIC (run-time classical) trip count | 2 phis | DECLINE, bare-i1 |
| `p32` | carried bool + a second region that is an in-place-Ry arm | header phi | DECLINE `control flow` @ **the phi** (`classifyArms`, not the kickback gate) |
| `p33` | SIBLING theta on the carried rail in the body | header phi | DECLINE, bare-i1 |
| `p34` | the region only, no body theta (`p1`'s control) | no phi — `b` is invariant | ACCEPT, rolled |

## The three facts that shaped the scope

1. **`p2`/`p9` already ACCEPT and NOTHING pins them.** A carried `_Bool` whose region
   condition is the *in-body* chained theta lowers ROLLED today — byte-identical to its
   hand-unrolled twin, IR size independent of K, stage 2b clean (`1 rail mint, 1 left
   allocated, 0 free sites, 0 violations`). No `.ll` fixture and no e2e slice covers it
   (`grep -l 'phi i1' ir-pass/test/control_phase_kickback_rail_*.ll` → empty).
2. **The header-phi half's target stream is already on disk**: `p1` rolled must print
   `p16.trace` (9 lines), and `p4` rolled must print `p4u.trace` = the committed
   `slice_control_phase_bool_grover.expected.log` shape.
3. **The merge-phi half is blocked TWICE, and the second block is arm-class-independent**:
   `p22`, the plain `int` COMPARE twin of `p5`, declines `condition predates a non-diagonal
   gate` on `main` — so even with the φ admitted as a rail leaf, `p5` would die at the
   wire question. That is a fence about reading a register a preceding *controlled* rotation
   moved; it has nothing to do with `_Bool`.
