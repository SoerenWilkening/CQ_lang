# Track R / R-2 probes — the RIVAL AUDIT for "a pinned value that is the condition of a conditional `br` is not an F2 collider"

**Every row below was measured on the session ORACLE on 2026-09-13**, read-only: nothing was
built, no suite was run (`../../PROTOCOL.md`, row "scoping").

```
shasum -a 256 build/ir-pass/cq-opt       -> fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661
shasum -a 256 build/ir-pass/libCQPass.so -> 40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93
git log -1 --format=%h                   -> 81956a2   (docs-only over the pass at e96f89c)
```

Run everything from the REPO ROOT (the script re-checks the ORACLE hash and STOPS if it moved):

```
docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackR/probes/r2/run.sh
CQDBG=1 …/trackR/probes/r2/run.sh x_C5_rival_constfalse_br_nomeasure.ll     # one probe, with its anchor
```

Per probe the script runs exactly the PROTOCOL.md pipeline: `cq-opt -passes=cq-lowering` →
(accepts only) `tools/free_pairing_check.py` → link `libcq_templates.a` before `libcq_runtime.a`
→ run. `CQDBG=1` adds the `CQ_CTRL_DBG=1` anchor for each decline.

⚠ **`LINKFAIL` on the accepting rows is EXPECTED and is not a finding**: these probes define
`@example`, not `@main`, so stage 3 has no entry point. The lowering, the verifier and STRICT
stage 2b all ran; only the link did not. The accepts' streams were read out of the work dir
(`grep -E 'cqrt_|cq_template_' $CQW/<probe>.s2.ll`).

Prefixes: `x_S`/`x_B3`/`x_C1`/`x_C4`/`x_C7`/`x_D1`/`x_E1`/`x_E3`/`x_F1`/`x_G1` = **SUBJECTS**
(the module R-2 would make lower); `x_A`/`x_B1`/`x_B4`/`x_C2`/`x_C3`/`x_C5`/`x_D2`/`x_D3`/`x_E2`/
`x_E4` = **RIVALS** (the unfolded source that same module could be `-O1`'s image of);
`_ctl_` = controls/bisections.

## Verdict table — 24 probes, **5 ACCEPT / 19 DECLINE**

```
ls x_*.ll | wc -l -> 24
```

`F2` = `cq controlled lowering: state prep seed is proven equal to the condition register under
quantum control`. Every decline is `DS_Error`, `opt` exit 1.

| probe | shape | verdict | anchor (`CQ_CTRL_DBG=1`) / reading |
|---|---|---|---|
| `x_S1_subject_offwire_br.ll` | `…_reject_stateprep_second_flag_i1.ll` + a second region branching on the off-wire pinned `%d` | DECLINE **F2** | `%c = icmp sgt i32 %q, 100` — **R-2 would strike this** |
| `x_A1_rival_offwire_br.ll` | its RIVAL: the arm rotates `%d` in place, `%d` still a br condition | DECLINE `control flow` | `%c = …` — **R3, not 2c** (`ArmClassify.cpp:4102-4103`) |
| `x_A2_rival_offwire_nobr.ll` | the same rival with no downstream br (the rival the fixture header itself names) | DECLINE `control flow` | identical anchor ⇒ the br changes nothing; R3 owns both |
| `x_B1_rival_unpinned_cmp_base.ll` | BISECTION: the rival with the rotated flag moved OFF the pinned edge (`sgt %q, 200`) | DECLINE `control flow` | ⇒ the wall is NOT about the pin or the wire |
| `x_B2_ctl_rival_rail_base.ll` | CONTROL: the shipped in-place controlled-Ry arm on an independent i1 RAIL | **ACCEPT**, 2b `2 mints, 1 verified, 0 violation(s), 0 unproven` | in-place i1 Ry arms DO lower on this binary |
| `x_B5_ctl_onedge_rival_base_matches.ll` | BISECTION: `x_B1`'s rival with the merge's pred incoming changed from the literal to `%d` | **ACCEPT**, 2b `1 mint, 1 verified, 0 violation(s), 0 unproven` | **names the fence: R3 "ONE base"**, and shows the one-edge rival is lowerable **but cannot fold into the subject** |
| `x_B3_subject_trunc_br.ll` | a NON-compare i1 collider (`trunc %q to i1`) pinned to `true`, branched on | DECLINE **F2** | `%c = icmp eq i32 %q, 5` — R-2 would strike this |
| `x_B4_rival_trunc_br.ll` | its RIVAL (arm rotates the trunc-minted rail in place) | DECLINE `control flow` | R3 again |
| `x_C1_subject_constfalse_cmp_br.ll` | the BOTH-EDGE pin: `%x = icmp slt %q, INT_MIN` (provably `false`, a distinct rail), branched on | DECLINE **F2** | R-2 would strike this |
| `x_C7_subject_constfalse_br_nomeasure.ll` | `x_C1` with the post-region measure of `%x` removed (matched to `x_C5`) | DECLINE **F2** | the subject/rival pair differs in EXACTLY the two folded slots |
| `x_C5_rival_constfalse_br_nomeasure.ll` | its RIVAL: honest in-place Ry on `%x`, `%x`'s only other use the br | DECLINE `stale rail record read past a controlled Ry` | **`br i1 %x, …`** — **R6**, `ArmClassify.cpp:4420`. The br IS the post-region read |
| `x_C6_ctl_rival_constfalse_nobr_nomeasure.ll` | CONTROL: the same rival with NO br and no read of `%x` | **ACCEPT**, 2b `1 mint, 1 verified, 0 violation(s), 0 unproven` | ⇒ the both-edge rival is a REAL lowerable program; it is the br that kills it |
| `x_C4_ctl_subject_constfalse_nobr.ll` | CONTROL: the both-edge subject with no br | DECLINE **F2** | the boundary R-2 leaves untouched — correctly, since `x_C6` lowers |
| `x_C2_rival_constfalse_cmp_br.ll` | the rival with `%x` ALSO measured after the region | DECLINE `stale rail record …` | `%mx = call i1 @cq_measure_i1(i1 %x)` — the measure is the confound `x_C5` removes |
| `x_C3_ctl_rival_constfalse_nobr.ll` | the same, without the br | DECLINE `stale rail record …` | same anchor ⇒ the measure alone decides it |
| `x_D1_subject_br_before_prep.ll` | the both-edge collider whose br (a `cq_phi` kickback region) runs **BEFORE** the prep region | DECLINE **F2** | R-2 would strike this — and R6 cannot see a pre-region read |
| `x_D2_rival_br_before_prep.ll` | its RIVAL | DECLINE `condition data use neither escaped nor measured` | `%x = icmp slt …` — a THIRD fence (`ArmClassify.cpp:3257`) |
| `x_D3_rival_br_before_prep_measured.ll` | the same rival with `%x` measured before the prep region (an attempt to satisfy that fence) | DECLINE `condition data use neither escaped nor measured` | the attempt fails; the fence holds |
| `x_E1_subject_degenerate_br.ll` | `br i1 %x, label %m2, label %m2` — syntactically a conditional br, semantically no region | **ACCEPT**, 2b clean | ⚠ **F2 never fires**: the pass deletes `%x` (the lowered IR has no `icmp_slt` template). R-2 has no customer here |
| `x_E2_rival_degenerate_br.ll` | its RIVAL | **ACCEPT**, 2b clean | emits `ry_i1_controlled(h_cmp, h_cmp1, .9)` vs `x_E1`'s `alloc_i1(false) + ry_i1_controlled` — different circuits, **both pre-existing, neither an R-2 row** (see SCOPE_R2 §0 row 8) |
| `x_E3_subject_unreachable_br.ll` | the one-edge collider branched on inside a block NOT reachable from entry | DECLINE **F2** | R-2's syntactic predicate fires on a br no region will ever claim |
| `x_E4_rival_unreachable_br.ll` | its RIVAL | DECLINE `control flow` | R3 — the one-edge pin admits only the cross-handle rival |
| `x_F1_subject_switch_scrutinee.ll` | BOUNDARY: the collider is an `i32` **switch scrutinee**, not a br condition | DECLINE **F2** | R-2 does NOT fire; the row keeps declining |
| `x_G1_subject_select_cond.ll` | BOUNDARY: the collider is a **select** condition | DECLINE **F2** | R-2 does NOT fire; the row keeps declining |

## Cited, not re-run (PROTOCOL.md: a gate result is a fact about a BINARY)

Same ORACLE hash, recorded in `../README.md` by the Track-R scoping agent at 12:06 on
2026-09-13: `w_W1` DECLINE **F1**; `w_W2` / `w_W3` / `w_W4` / `w_W5` DECLINE `control flow`
(the C-level rivals — `w_W4`'s stage-1 IR shows `-O1` DELETING the compare and rewriting the
downstream guard to read the rail directly); `v_vd.c`, `r_R6a`, `r_R6b` DECLINE **F2**;
`r_R6c` ACCEPT 20; `b_HP_f_nopeel.ll` ACCEPT 9 (the region's own compare is in `CondWire`).

`# work dir` on the last line of a run names the scratch dir holding every `*.s2.ll`.
