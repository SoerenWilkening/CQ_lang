#!/usr/bin/env python3
"""Build the two bd ec7r fixtures from the delta reviewer's probe modules
(review_r2_delta_8e5r/probes/p2_liftskip_verdict/p2_{C,T}.ll): header + RUN
lines + the module verbatim."""
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2"
P = W + "/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/review_r2_delta_8e5r/probes/p2_liftskip_verdict"

COMMON = """;
; THE DEFECT (a COMPOSITION of bd 8e5r x bd d88e; Rule-13 delta round r2, F-R2-1).
; The bd 2qyz post-lift stale-record re-sweep (`declineLiftedStaleRecordOps`) is a
; MODULE-WIDE re-run of `declineStaleRecordOps`, gated on "a one-register merge-phi
; lift occurred". bd d88e moved that re-sweep AFTER `specialize()`. bd 8e5r made the
; table the gate read, `taint.LiftedConsumers`, SELF-CLEANING — `empty()` counts LIVE
; members. `specialize()` -> `retargetSite` REBUILDS an fp-return spec call (fp result
; -> `i32` handle) and ERASES the old call; when that call was the lift's ONLY direct
; consumer the set went empty, the re-sweep was SKIPPED, and this module ACCEPTED on
; the merged tree (`c416f04d`, 3/3, allocator-independent) — while `main` before d88e
; (def1b088), 8e5r alone (818f8afa) and d88e alone (ba80bda1) all DECLINE it. A
; verdict move against `main` that exists only in the composition.
;
; THE FIX: the gate reads `taint.LiftedMergePhis` — d88e's per-lift RECORD, one entry
; pushed per accepted lift and never removed, so `!empty()` means "a lift occurred"
; whatever later happens to its consumers. Every lifted phi has >= 1 Instruction user
; (`declineClassicalMuxes` skips a `use_empty()` phi), so on every pre-merge binary
; "the raw consumer set is non-empty" and "a lift occurred" were the same fact; this
; restores exactly their verdicts. (Whether the re-sweep should be module-wide at all
; is the separate, pre-existing over-decline bd test_C_libtooling-3a43 / F-R2-3: the
; decline below is in `slice()`, the lift is in `main()` — this fixture pins the
; verdict main has, not a judgement that it is right.)
;
; Built from plain C, two TUs, `clang -O1` per TU + `llvm-link` (the reviewer's
; `build_probes.sh`, as `tests/e2e/run_slice_multi.sh` builds a multi-TU module).
; `slice()` is the shipped `e2e-slice-control-grover-loop-range-oracle` loop.
"""

C_HDR = """; bd test_C_libtooling-ec7r (Rule-13 r2 F-R2-1) — the lift re-sweep must run although
; `specialize()` ERASED the lift's only consumer (an fp-return spec call it rebuilt).
""" + COMMON + """;
; Source (main TU; lib TU: `double h(int a, int k) { return (double)(a + k); }`):
;   double h(int a, int k);
;   __attribute__((noinline)) int slice(void) {
;       int a = 0; a = cq_theta(a, 0.5);
;       for (int i = 0; i < 2; ++i) {
;           if (a > 5 && a < 20) { cq_phi(3.14159265358979323846); }
;           a = cq_theta(a, -0.5);
;       }
;       return cq_measure(a);
;   }
;   int main(int c, char **v) {
;       int m = atoi(v[1]);
;       int q = cq_theta(m, .5);
;       if (m > 3) q = cq_theta(q, .2);    // the one-register merge-phi LIFT
;       double d = h(q, m);                 // its ONLY consumer: an fp-return spec site
;       return (int)cq_measure(d) + slice();
;   }
;
; Verdicts (3 runs each, `results` in TRACK_8E5R.md §15): def1b088 DECLINE, 818f8afa
; DECLINE, ba80bda1 DECLINE, c416f04d ACCEPT (the defect), this tree DECLINE.
; The twin with a SURVIVING consumer is `lowering_reject_lift_resweep_surviving_consumer.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function slice i32 (): cq opcode lowering: operand predates a non-diagonal gate
"""

T_HDR = """; bd test_C_libtooling-ec7r companion — the SAME program as
; `lowering_reject_lift_resweep_spec_rebuilt_consumer.ll` with the lifted value ALSO
; read by a pure op (`cq_measure(q ^ 1)`), so a lifted consumer SURVIVES
; `specialize()` and the self-cleaning `LiftedConsumers` stayed non-empty: this module
; DECLINED on every binary, the merged `c416f04d` included (the reviewer's p2_T). It
; pins that the fix did not move the case the old gate already got right.
""" + COMMON + """;
; Verdicts (3 runs each): def1b088, 818f8afa, ba80bda1, c416f04d and this tree — all
; DECLINE with the string below.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function slice i32 (): cq opcode lowering: operand predates a non-diagonal gate
"""

for src, dst, hdr in (("p2_C.ll", "lowering_reject_lift_resweep_spec_rebuilt_consumer.ll", C_HDR),
                      ("p2_T.ll", "lowering_reject_lift_resweep_surviving_consumer.ll", T_HDR)):
    body = open(f"{P}/{src}").read()
    open(f"{W}/ir-pass/test/{dst}", "w").write(hdr + "\n" + body)
    print("wrote", dst)
