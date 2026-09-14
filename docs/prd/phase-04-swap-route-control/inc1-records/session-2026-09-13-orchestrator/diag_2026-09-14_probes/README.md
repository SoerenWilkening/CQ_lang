# `DIAG_2026-09-14` probes — verdict table

**READ-ONLY diagnosis.** Nothing was built, no suite was run, nothing under
`ir-pass/ include/ runtime/ tests/ tools/ example/` was edited. Binary measured
(the 2026-09-13 closing primary, `shasum -a 256`, printed by `run.sh` on every
invocation):

```
build/ir-pass/cq-opt        f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc
build/ir-pass/libCQPass.so  f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d
```

`./run.sh` runs every probe; `./run.sh v6 u2` runs named ones; `./surgeries.sh`
runs the three IR surgeries that NAME the collider. Per-probe pipeline is
`../PROTOCOL.md`'s verbatim (LLVM at `/usr/local/opt/llvm@19/bin`, not on PATH).

## Q1 — the owner's file and the minimal-edit matrix

`LINES` = trace lines when accepting. Every accepting row is STRICT stage 2b
`0 violation(s), 0 unproven`.

| probe | what it is | exit | LINES | verdict |
|---|---|---|---|---|
| `q1_owner_0930.c` | the owner's file at mtime **09:30** (third region COMMENTED OUT) | 0 | **29** | ACCEPT — byte-identical to `tests/e2e/slice_control_cascade_two_bools.expected.log` |
| `q1_owner_now.c` | the owner's file at mtime **09:37** (third region LIVE) | 1 | — | DECLINE `state prep seed is proven equal to the condition register` @ **93:14** |
| `v0.c` | the 09:30 body, comment banner stripped | 0 | 29 | ACCEPT (the baseline every `v*` edit is applied to) |
| `v1.c` | v0 − `cq_measure(b2)` | 0 | 29 | ACCEPT |
| `v2.c` | v0 − `bool b2 = 0;` entirely | 0 | 29 | ACCEPT |
| `v3.c` | v0 with `if (b0 == 1)` restored | 0 | 29 | ACCEPT |
| `v4.c` | v0 with `bool b2 = 1;` | 0 | 29 | ACCEPT |
| `v5.c` | v0 with the `b2` declaration moved AFTER the regions | 0 | 29 | ACCEPT |
| `v6.c` | v0 **+ the third region restored** (`if (a >= 3) b2 = cq_theta(b2, .5);`) | 1 | — | **DECLINE, F2** @ 9:23 — this is the owner's complaint, minimally reproduced |
| `e1.c` | v6 − `cq_measure(b2)` | 1 | — | DECLINE, F2 @ 6:23 (the measure is irrelevant) |
| `e4.c` | v6 with `bool b2 = 1;` | 1 | — | DECLINE, F2 @ 9:23 (the THIRD region's seed is irrelevant) |
| `v6a.c` | v6 with **`bool b1 = 1;`** (the DECLINING region's seed) | 0 | 35 | ACCEPT — different circuit (prep from \|1⟩) |
| `v6b.c` | v6 with the third guard **`if (a >= 1)`** | 0 | 35 | ACCEPT — different circuit |
| `v6c.c` | v6 with the third guard `if (a >= 6)` | 0 | 29 | ACCEPT **but NOT a control**: `-O1` deleted the third region (2 thetas in stage 1, 29 lines == `v0`) |
| `v6d.c` | v6 with the third guard **`if (b0)`** | 0 | 32 | ACCEPT — the guard is now on the condition's own wire (`CondWire`-excluded); different circuit |
| `w1.c` | v6 with the `b2` region moved **before** the `b1` region | 0 | 33 | ACCEPT — different circuit |
| `w2.c` | the three-region cascade with a **runtime** `a` (`argc + 4`) | 1 | — | DECLINE, F2 @ 9:11, anchor `%10 = icmp sgt i32 %9, 2` — a SECOND instance; the decline is **not** an artefact of `int a = 5` |
| `../probes/vd.c` | the session's N=3 probe (bd `om35`) | 1 | — | DECLINE, F2 @ 10:14, same anchor `%1` |

### The surgeries (`./surgeries.sh`) — what NAMES the collider

| # | edit to the stage-1 IR | result |
|---|---|---|
| S1 | `v6`: `%9 = icmp sgt i32 %8, 2` → `…, 1` (one constant) | **exit 0** — the pin disappears, the module accepts |
| S2 | `v6`: the third region's **theta deleted**, `%9` and its `br` KEPT | **exit 1, same string, same anchor** — the collider is `%9`, not the theta |
| S3 | `w2`: `%17 = icmp sgt i32 %16, 2` → `…, 0` | exit 1 `control flow` — the F2 string MOVES OFF `%17`, but this is **not** a clean accept control (a different fence takes it) |

## Q2 — the uninitialized-variable family

| probe | source | exit | LINES | diagnostic @ line:col | grade |
|---|---|---|---|---|---|
| `u1.c` | `bool b2;` never prepared, **measured** | 1 | — | `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value` @ 9:29 | **(A)** the 21mg fence |
| `u2.c` | `bool b1;` (undef SEED) prepared **in a region**, measured | 1 | — | `cq controlled lowering: state prep seed does not match the merge incoming` @ 9:23 | **(B)** F1 |
| `u3.c` | `bool b0;` prepared **unconditionally** | 0 | 15 | — | **(D)** not a decline — emits `cqrt_alloc_i1(i1 undef)`, trace prints `cqrt_alloc_i1(1) -> h0` |
| `u3b.c` | `u3` + a second (chained) theta on the same rail | 0 | 16 | — | **(D)** — still one undef literal SLOT, under bd `xy9n`'s threshold of 2 |
| `u4.c` | `int a;` uninitialized in the guard `if (a >= 3)`, `a` measured | 1 | — | `cq_measure_<sfx> operand is an undef/poison literal; …` @ 8:29 | **(A)** — the GUARD is not what declines |
| `u4b.c` | `int a;` uninitialized in the guard, `a` **not** measured | 0 | 3 | — | **(D)** — `-O1` deleted the region; CQ never sees one |
| `u5.c` | `bool b1;` (undef seed) prepared in a region, then the 4.4 select condition | 1 | — | `cq controlled lowering: state prep seed does not match the merge incoming` @ 9:23 | **(B)** F1 |

Grades: **(A)** the deliberate 2026-09-13 `21mg` undef fence · **(B)** an F1/F2
state-prep fence · **(C)** a taint/other fence · **(D)** not a decline at all.
