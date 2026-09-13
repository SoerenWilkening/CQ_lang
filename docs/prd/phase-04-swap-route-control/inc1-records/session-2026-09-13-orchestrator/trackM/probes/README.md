# Track M probes — the region-merge-φ rail leaf at the 4.4 DATA SELECT (bd `boi6` D-B, probe `p20`)

Measured 2026-09-13 against the **frozen ORACLE** (`build/ir-pass/cq-opt` sha256
`fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661`, `libCQPass.so`
`40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93`, built 2026-09-11 22:23 from
`e96f89c`). Repo at `main` `01c89b5` (docs-only over the pass). Hash verified before every sweep —
`run.sh` aborts on a mismatch.

## The exact command

`run.sh` is the runner; it refuses to start unless the ORACLE hash matches. From the repo root:

```
./docs/.../trackM/probes/run.sh <dir-with-the-probes>              # the whole dir
./docs/.../trackM/probes/run.sh <dir> <dir>/m18.ll                 # one probe
```

Per probe it runs exactly the `PROTOCOL.md` pipeline (`LLVM=/usr/local/opt/llvm@19/bin`):

```
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S <p>.c -o <p>.s1.ll      # .ll probes: copied
build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S <p>.s1.ll -o <p>.s2.ll
python3 tools/free_pairing_check.py <p>.s2.ll                                       # accepts only, STRICT
"$LLVM/clang" <p>.s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o <p>.bin && <p>.bin
```

Anchors were taken separately with
`CQ_CTRL_DBG=1 build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S <p>.s1.ll -o /dev/null 2>&1 | grep -E 'decline|error:'`.

Diagnostics below are quoted without the `cq controlled lowering: ` prefix and the
` under quantum control` suffix. `2b` is `free_pairing_check.py`'s summary line (STRICT).

## Verdict table

| probe | shape (all on the owner's 2-bool cascade unless said otherwise) | exit | verdict / diagnostic | anchor |
|---|---|---|---|---|
| `m01` | `if (b1) a -= 3;` — the owner's file, line 99 | 1 | `control flow` | `%7 = select i1 %5, i32 %6, i32 %cq.peel.mux` |
| `m02` | `if (!b1) a -= 3;` | 1 | `control flow` | the select (arms swapped) |
| `m03` | `if (b1) a += 1;` | **0** | **ACCEPT**, trace **23**, 2b `6 mints / 5 left allocated, 2 free: 2 verified, 0 violations, 0 unproven` | — |
| `m04` | `if (b1) a = 7;` | 1 | `control flow` | `%6 = select i1 %5, i32 7, i32 %cq.peel.mux` |
| `m05` | `cq_measure(b1)` BEFORE the select | 1 | `control flow` | the select |
| `m06` | `a += (int)b1;` then the select (`b1` read as DATA too) | 1 | `control flow` | the select |
| `m07` | TWO selects on one prep output (`a -= 3; a += 2;`) | **0** | **ACCEPT**, trace **23** (the pair folds to `add(a, sext b1)`) | — |
| `m08` | the PHASE consumer `if (b1) cq_phi(0.3);` | 1 | `branch phase on a bare i1 condition` | `br i1 %5` |
| `m09` | `if (b1) a -= 1;` | **0** | **ACCEPT**, trace **23** (folds to `add(a, sext b1)`) | — |
| `m10` | the prep on the TRUE edge (`if (a < 3) b1 = cq_theta(…)`) | 1 | `control flow` | the select |
| `m11` | **`int b1`** with `bool b0`, + the select | **0** | **ACCEPT**, trace **28**, 2b clean | — |
| `m12` | `int b0` / `int b1`, + the select | **0** | **ACCEPT**, trace **31**, 2b clean | — |
| `m13` | `cq_invert_begin/_end` around the select | 1 | `control flow` (the select fires first; Phase 8 never reached) | the select |
| `m14` | the S† `b0 = cq_theta(b0,-0.5)` AFTER the select | 1 | `control flow` | the select |
| `m15` | `b1` prepped TWICE (`b1 = cq_theta(b1,0.25)` after) | 1 | `control flow` | the select |
| `m16` | run-time `a` (`volatile int av = 5; int a = av;`) | 1 | `control flow` | `%11 = select i1 %9, i32 %10, i32 %4` |
| `m17` | **T1 in plain C** — the `b1` prep made UNCONDITIONAL, so the select's condition is a bare `cq_theta_i1` CALL | **0** | **ACCEPT**, trace **28**, 2b `8 mints / 6 left allocated, 2 free: 2 verified, 0 violations, 0 unproven` | — |
| `m18` | **T1, hand IR** — `owner.main.O1.ll` AFTER `emitInPlaceRotationRegion` (M-β) and after the peel: the select's condition is the hoisted theta chain's last gate | **0** | **ACCEPT**, trace **29** — THE TARGET STREAM | — |
| `m19` | T1 without the cancelling clone (un-negated prep; M-β target = the single hoisted theta) | **0** | **ACCEPT**, trace **28** | — |
| `m20` | **T2, hand IR** — the select's condition is a φ whose TWO incomings are on ONE wire (boi6 `p5`'s shape, CHAINED arm theta) | 1 | `control flow` | `%sel = select i1 %p` — the **leaf grammar**, NOT the wire fence |
| `m21` | hand IR — a tainted `xor i1` as a select condition, no region at all (the shape a DEFERRED select would present) | 1 | `control flow` | `%sel = select i1 %nt` |
| `m26` | `int b1` twin of `m08` — the PHASE consumer on a φ-derived COMPARE | **0** | **ACCEPT**, trace **25** (`icmp_eq_i32_hl(h1,0)` → `x/rz_i1/x` → `_unc` → free) | — |
| `m27` | the VALUE-DIAMOND consumer — the arm WRITES MEMORY (`if (b1) { g = 1; }`), so no if-conversion | 1 | `control flow` | `br i1 %5` — `classifyArms` DOES see a φ condition from plain C |
| `m28` | compound `if (b1 && b0) a -= 3;` | 1 | `state prep seed is proven equal to the condition register` | the `b0` theta |
| `m29` | hand IR — a φ over TWO DISTINCT rails as the select's condition | 1 | `control flow` | the select |
| `m30` | the merge-φ select INSIDE a bounded loop | 1 | `cq loop lowering: loop-carried tainted value crosses iterations` | the loop layer, before detection |
| `m31` | hand IR — the φ as a LEAF of a COMPOUND tree at the select (`and i1 %p, %cmp`) | 1 | `control flow` | the select |

Cited, not re-measured (`../../probes/README.md`, same ORACLE): `owner_file_2026-09-13.c` = `m01`;
`va` ACCEPT 19 lines; `vb`/`vc` = `m01`'s IR byte-identically; `vd` `state prep seed is proven equal
to the condition register`; `ve` `cq taint escape: tainted value stored to memory`.

## The three readings

1. **The accept/decline line today is whether `-O1` keeps a `select`.** `m03`/`m07`/`m09` are the
   owner's shape with a **±1** delta, which InstCombine folds to `add(a, {z,s}ext b1)` — pure tainted
   ARITHMETIC on the merge φ, no control region. Those ACCEPT, 23-line traces, STRICT 2b clean. So
   the prep merge φ is **already** consumed as a quantum register today; only the `select` consumer is
   refused. `if (b1) a -= 3;` declines and `if (b1) a -= 1;` accepts, on the same binary.
2. **The wire fence is NOT the second blocker for this shape.** `m11`/`m12`/`m26` accept, and their
   condition is a COMPARE over the prep merge φ — i.e. gate 2c / `railCondWireDisposition`'s question
   is asked over `condProvenance(φ) = {φ, source theta}` and answers CLEAN, because a SOURCE theta's
   arg-0 is classical so the backward closure stops there and the theta is ON-ANCESTRY exempt. That
   is the difference from boi6 `p5`/`m20`, whose arm theta is CHAINED. `SCOPE_boi6.md` §0.3's
   "admitting the φ buys `p5` nothing" is TRUE OF `p5` and FALSE of the owner's file.
3. **T1 is measurable and it accepts.** `m18`'s 29 lines are the stream the widening must produce;
   its select half (lines 17–26) is byte-for-byte the r9e5 rail-root CNOT-copy merge, with the
   prep rail read ONLY as a control and the two `cqrt_x` on the ancilla.
