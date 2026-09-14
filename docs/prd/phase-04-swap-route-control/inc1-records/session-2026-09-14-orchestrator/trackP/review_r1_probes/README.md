# Track P — ADVERSARIAL REVIEW round 1 probes

Runner: `run.sh` (compiles `-O1 -g`, refuses a zero-byte stage-1 before measuring,
runs stage 2b `free_pairing_check.py`, links and runs on accept).
`BUILD=<dir>` selects the binary; default is the SUBJECT worktree
`/Users/sorenwilkening/Desktop/CQ_phiphase/build` (cq-opt 283e3b3322a9a94c).
ORACLE runs used `/Users/sorenwilkening/Desktop/CQ_lang/build` (cq-opt f7b65d8ccd7bc472).

| probe | what it attacks | ORACLE | SUBJECT |
|---|---|---|---|
| r01/r02 | intended unclaimed-phi; `-O1` folded them — VACUOUS as designed, kept for the record | ACCEPT | ACCEPT |
| r03 | rung (ii) at a phi ROOT, `-g` anchor | `branch phase on a bare i1 condition` @9:9 | `condition measured before the control route` @9:9 |
| r04 | rung (ii) at an INTERIOR phi leaf | `control flow` @9:12 | `condition measured…` @9:12 |
| r05 | step-6 wire, phi ROOT | `branch phase…` @8:9 | `condition predates a non-diagonal gate` @8:9 |
| **r06** | **ROW 9 WITNESS** — tree phi leaf whose wire only `Prov` can see | `control flow` @8:11 | `condition predates a non-diagonal gate` @8:11 |
| **r07** | **F-P1-1** — `-O1`-FUSED two-phi merge: TWO phi leaves in ONE `Pred` | `nested control flow` @10:9 | identical |
| **r08** | **F-P1-3(c)** — phi leaf with a DATA use outside the branch | `control flow` @11:12 | **ACCEPT** 21 lines |
| r09 | row 12: `ProvenPostRegion` must accept a post-region rotation | `branch phase…` @9:9 | ACCEPT 8 lines |
| r10 | `xor` NODE + phi leaf | `control flow` @8:9 | ACCEPT 13 lines |
| r11 | `or` NODE + phi leaf | `control flow` @8:12 | ACCEPT 21 lines |
| r12 | row 14: folded angle select on a prep phi | `rotation angle` **`<unknown>:0:0`** | identical |
| r13 | BRIEF item 2: flag orthogonality | `control flow` @11:9 | identical |
| r14 | intended nest; `-O1` flattened it to the 4aiu tree | `control flow` @9:9 | ACCEPT 17 lines |
| r15 | bd `boi6` loop-carried `_Bool` header phi — F-P2 closure | `branch phase…` @8:13 | identical |
| r16 | Track M F-M3, in-place-ARM phi | `control flow` **`…c:0:0`** | identical |
| r17 | select on a loop header phi; `-O1` made it lower | ACCEPT | ACCEPT |
| r18 | IMPL §9.1 over-decline, re-measured | `control flow` @10:12 | `condition predates…` @10:12 |
| r19 | phi leaf conjoined with the prep's own control | `state prep seed is proven equal…` @7:15 | identical |
| r20 | `cq_measure` of the PREP'S condition before | `condition measured…` @5:15 | identical |
| **r21** | **F-P1-6** — in-loop phi kickback (the select twin is a shipped accept) | `branch phase…` @10:13 | `condition predates…` @10:13 |
| r22 | kickback + data select fused on one prep phi | `control flow` **`…c:0:0`** | identical |
| r23 | prep on the FALSE edge (`ClassArmFalse` half of rung 0) | `branch phase…` @8:9 | ACCEPT 8 lines |
| r24 | phi leaf at tree DEPTH 2 | `control flow` @10:15 | ACCEPT 27 lines |
| **r25** | **F-P1-3(c) control** — COMPARE leaf with a use outside the branch | — | `condition used outside the branch` @9:15 |

Every accept above was read as a STREAM (`.trace`) and carries **zero `cqrt_x`**, no freed user
register, and STRICT stage-2b `0 violation(s), 0 unproven`.
