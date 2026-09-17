# The 10 fixtures pinning the bd `s82e` D4 interim string, and what this increment does to each

`grep -rln 'rolled body leaks a rail entangled' ir-pass/test/` at `cff8f7ac` — measured, not copied.

| fixture | RUN-line verdict today | after the increment | why |
|---|---|---|---|
| `control_phase_kickback_mixed_hoisted_template_leak_control.ll` | DECLINE (`not`) | **ACCEPT** | the hoisted `cq_template_mul_i32_hl` rail — P3+P0. Its L8 trigger names `tu9q` and is CORRECT; target `3/3`, 40 trace lines (`probes/ht_un.trace`) |
| `control_phase_kickback_mixed_short_sext_leak_control.ll` | DECLINE (`not`) | **ACCEPT** | identical shape with a hoisted `cq_template_sext_i16_to_i32` rail (`mintsOutOfPlaceTemplateRail`'s `CastInst` arm) |
| `control_phase_kickback_mixed_preheader_volatile_imm_leak_control.ll` | DECLINE (`not`) | **STAYS DECLINE** | ⚠ its blocker is `commitOutOfLoopInPlaceOps`' `isa<Constant>(Imm)` fence (`LoopLowering.cpp:3162-3165`), NOT the template-rail clause. **Its L8 trigger names the wrong owner and must be corrected in place** (SCOPE §3.4) |
| `loop_leak_dephase_reject_region_derivedbase_live.ll` | DECLINE (`not`) — TWO RUN lines, incl. the `CQ_BBU0_DEFER_DEPHASE_FENCE=1` DEFER prefix at `:109-110` | **ACCEPT** | `= s2_live_derived_region`. **Both** RUN lines move; target 25 lines (SCOPE §3.1) |
| `loop_leak_dephase_reject_nested_marked_inner.ll` (`n2`) | DECLINE | **STAYS** | refused by the SUBLOOP clause, untouched. Owed an L8 trigger naming the nested-loop discharge point (bd `emkg`'s class) |
| `loop_leak_dephase_reject_nested_iterlocal_inner.ll` (`n1`) | DECLINE | **STAYS** | same |
| `loop_leak_dephase_reject_nested_iic_inner.ll` (`n3`) | DECLINE | **STAYS** | same |
| `loop_leak_dephase_reject_nested_depth3_middle_rail.ll` (`r1`) | DECLINE | **STAYS** | same |
| `loop_leak_dephase_reject_cmp_rail_data.ll` | **ACCEPT already** (no `not`; converted at the 2026-09-15 merge, FIX.md §1a) | unchanged | body-minted rail; the string survives only in its historical header. bd `gahu` (name says `reject`, verdict is accept) |
| `loop_leak_dephase_reject_inloop_rotation.ll` | **ACCEPT already** | unchanged | same |

Plus, not in that grep but converted by this increment:

| fixture | today | after |
|---|---|---|
| `loop_pairing_reject_root_hoisted_template_data.ll` | ACCEPT with a whole-file `LEAK` prefix (`CHECK-NOT` on every `_unc`/`cqrt_free`) | **ACCEPT with positive counts** — Track T's own boundary fixture for clause (ii) refusing a template rail; that boundary is exactly what P3 moves. Its header says *"If a `_unc` appears here, (ii-c) over-widened and the multiplicity miscompile is LIVE"* — that sentence must be REWRITTEN, not deleted, and re-aimed at the multiplicity backstop P1 now supplies |
| `loop_pairing_reject_root_invariant_read_after_loop.ll` | ACCEPT + `LEAK` prefix | **verify unmoved** — it pins the "EVERY user is a measure" quantifier of (ii-c), which (ii-d) does not touch. If it moves, (ii-d) over-widened |
