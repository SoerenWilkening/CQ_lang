; lowering_loop_iter_local_temp.ll — ACCEPT (Phase 7.3 Inc 2, 799w.2): the Case B
; iteration-local born-and-dies temporary, `clang -O1` output (attribute groups
; and metadata trimmed) for
;
;     void slice(int x, int n) {
;       for (int i = 0; i < n; i++) {
;         int q = x; cq_theta(&q, 0.25);   /* fresh rail, born in body   */
;         int t = q ^ 9;                    /* template producer (born)   */
;         cq_theta(&t, 0.5);                /* in-place Ry keep-alive; t then dies */
;       }
;     }
;
; It lowers with a PER-ITERATION IN-BODY uncompute: a single-block loop body
; whose ONLY loop phi is the classical induction (no tainted header phi, no
; loop-carried rail), every tainted value (the fresh alloc `%7`, the `xor` temp
; `%8`, the dead keep-alive `%9`) BORN AND DEAD within one iteration. Without
; the keep-alive `clang -O1` deletes the dead `xor`, so the gate on `t` is what
; makes the temp reach the pass at all.
;
; THE SPINE SURGERY (PRD §2.5): `lowerLoops` recognizes the iteration-local loop
; and marks its body block; the Phase-5 spine then LIFTS its two backedge guards
; (FreePoint kMsgLoopBackedge + Uncomputation §2.9 InLoop) for the proven
; iteration-local DAG and places the whole-DAG recovery + `cqrt_free` IN-BODY,
; after the temp's last in-iteration use (the keep-alive Ry), before the
; backedge, proven to execute exactly ONCE PER ITERATION (never the
; function-scope post-dominator, which would free the rail K times: use-after-
; free + double-free, the central Rule-13 hazard). The reversal is the standard
; whole-DAG LIFO: ry(t, -0.5) (undo keep-alive) -> xor `_unc` (reads the live
; `q`) -> free t-rail -> ry(q, -0.25) (undo mint). The q-rail is then KEPT, not
; freed (bd 5c5b, libcqops vmz9): its Ry-dagger restores the runtime seed |x>,
; not |0>, so each trip leaves one rail allocated. The t-rail free is the in-body
; placement witness, and it is sound: after its Ry is undone `t` is again the
; basis copy `q ^ 9`, which the `_unc` returns to |0>.
;
; This module also prints `warning: ... non-diagonal gate over a live derived
; record` (the M-A guard), and the warning is RIGHT; it is pinned below (WARN).
; The gate is the keep-alive Ry on `t`'s rail, but the record is NOT `t`'s own
; rail: it is `q`'s rail (the `cqrt_alloc_i32` that `%7` lowers to, %[[Q]]
; below), the xor's parent (measured with a record-dump build, bd aako
; 2026-10-05). At the gate the state is
; sum_a c_a |a>_q |a^9>_t: `q`'s rail is a basis record of `t`, never observed,
; so the Ry acts on a mixture, which is the ruled canonical case of
; lowering_reject_live_record_io_tape_chained_theta.ll. Straight-line, the same C
; is silent because M-C lowers `t = q ^ 9` in place on `q`'s rail; inside this
; loop it does not. Both sides are in lowering_live_record_own_rail_accept.ll.
;
; History: pre-3qlq the keep-alive was the register form `(void) cq_phi(t, 0.5)`
; (an in-place Rz), so the LIFO began with `rz(t, -0.5)`. The 3qlq migration
; deleted it as an uncontrolled phase and left a dead `xor` that `clang -O1`
; would never emit; bd jttf (2026-10-05) re-spelled the keep-alive as the
; in-place Ry above.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WARN < %t.err
;
; One warning, on the keep-alive gate (`q`'s rail stands as a record of `t`):
; WARN:     warning: {{.*}}in function slice void (i32, i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: warning
;
; The whole compute+uncompute pair lives INSIDE the loop body, before the backedge:
; CHECK-LABEL: define void @slice(
; CHECK:      br i1 %{{[0-9]+}}, label %[[LOOP:[0-9]+]], label %[[EXIT:[0-9]+]]
; CHECK:      {{^}}[[LOOP]]:
; CHECK-NEXT: phi i32
; Forward compute (fresh rail mint, the xor temp, the keep-alive Ry):
; CHECK-NEXT: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 2.500000e-01)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[Q]], i32 9)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double 5.000000e-01)
; In-body LIFO uncompute (negated keep-alive -> xor `_unc` reading live %[[Q]] ->
; free t-rail -> negated mint; the q-rail is kept), all before the backedge:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double -5.000000e-01)
; CHECK-NEXT: call void @cq_template_xor_i32_hl_unc(i32 %[[T]], i32 %[[Q]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double -2.500000e-01)
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32
; CHECK-NEXT: br i1 %{{[0-9]+}}, label %[[EXIT]], label %[[LOOP]]
;
; Exactly one free in the module, the t-rail's (count + negative of the same
; pattern, alone in its prefix):
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; Whole-module negatives: no fresh-minting `_inv`, no added measurement, no
; surviving front-end intrinsic:
; NEG-NOT: cq_template_xor_i32_hl_inv
; NEG-NOT: cqrt_measure
; NEG-NOT: cq_theta_si32
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define void @slice(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %5, label %4

4:                                                ; preds = %5, %2
  ret void

5:                                                ; preds = %2, %5
  %6 = phi i32 [ %10, %5 ], [ 0, %2 ]
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %8 = xor i32 %7, 9
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-01) #2
  %10 = add nuw nsw i32 %6, 1
  %11 = icmp eq i32 %10, %1
  br i1 %11, label %4, label %5
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
