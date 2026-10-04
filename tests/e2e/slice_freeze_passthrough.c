// slice_freeze_passthrough.c — OWNER-ACCEPTED N/A WAIVER (Phase-7.1 Increment B).
//
// THERE IS NO e2e SLICE FOR THE FREEZE PASSTHROUGH, AND THERE IS NO add_test /
// .expected.log FOR THIS FILE. This file exists ONLY to record the waiver
// EXPLICITLY (Rule 16 — an N/A must be documented, never a silent skip). It is
// not compiled, linked, or run by any ctest entry (e2e slices register via an
// explicit `add_test` in CMakeLists.txt; this file is deliberately absent there).
//
// WHY N/A: a tainted `freeze` is a MID-PIPELINE insertion (SimplifyCFG
// speculation, LICM hoist guards, jump-threading poison fences), NOT something
// `clang -O1` — the validated frontend floor (Rule 9) — emits from ordinary
// CQ.h C source. Empirically verified 2026-06-20: the straight-line, ternary,
// logical-&&/||, variable-shift, and div-by-tainted idioms below all lower with
// ZERO `freeze` in the -O1 IR. (Higher -O levels CAN synthesize one, but -O2/-O3
// are out of scope at Stage 1 — they break taint signatures / post-dominators /
// handle identity, CLAUDE.md Rule 9 / Key Prohibitions.)
//
//     int main(void) {
//       int q = 7; cq_theta(&q, 0.5);
//       int s = q + 3;
//       int a = (q > 3) ? (q << 2) : (q + 1);
//       int b = (q && 5) ? q : 0;
//       int t = q / (q | 1);
//       return cq_measure(s + a + b + t);
//     }
//
// Because no tainted `freeze` reaches Stage 2 from a `-O1` .c, there is no new
// symbol to link-resolve: the freeze accept FOLDS the freeze away (RAUW to its
// operand handle + erase) entirely WITHIN the IR pass, emitting NO new `cqrt_*` /
// `cq_template_*` symbol. The authoritative ACCEPT proof is therefore the lit
// fixture `ir-pass/test/lowering_freeze_passthrough_i32.ll` (which injects the
// `freeze` directly into the IR — the only layer that can construct the shape),
// and the R-B decline proofs are
// `ir-pass/test/lowering_reject_freeze_escaped_return.ll` /
// `lowering_reject_freeze_measured_fanout.ll` /
// `control_swap_reject_select_freeze.ll` /
// `control_swap_reject_freeze_phi_angle.ll`. The e2e LINK layer adds nothing here
// because no symbol crosses into Stage 3.
//
// (If a future increment lowers a freeze to a NEW runtime/template symbol, this
// waiver is void — that symbol would need an e2e link-resolution slice, Rule 16.)
