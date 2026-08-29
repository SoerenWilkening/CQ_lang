; lowering_reject_live_record_mc_add_sub_around.ll — LOUD DECLINE (M-A, the late-slot
; live-record guard). One of THREE fixtures added by bd test_C_libtooling-160a's
; Rule-13 round, finding F1f: "M-C cannot see an M-B discharge" was recorded in a
; bd memory (`mc-cannot-see-mb-discharge-2026-08-29`) and pinned NOWHERE — and a
; decline that lives only in a memory is exactly the kind that silently becomes
; an accept. The siblings are
; lowering_reject_live_record_mc_sub_after.ll / _mc_add_sub_around.ll /
; _mc_grover2_offset.ll; one function per file because the pass stops at the
; FIRST loud diagnostic, so a three-function module would pin only one of them.
;
; THE MECHANISM, in one line: `lowerOps` runs BEFORE `uncompute`, so M-C's
; prior-use fence (`ArithLowering`'s settled-prior-use arm (d)) cannot see a
; discharge the M-B interior partition will emit later. It therefore refuses to
; rewrite `a -= off` in place, mints a FRESH rail for the subtraction, and the
; OLD register stands as a dead derived record at the next `cq_theta` — which the
; M-A guard declines, loudly and correctly.
;
; THE CONSEQUENCE WORTH KNOWING (this is why the memory exists): a derived-oracle
; Grover MUST NOT use the `+= off` / `-= off` offset trick. It is not a physics
; wall and not an M-B failure — it is a STAGE ORDERING — but until that changes,
; the offset spelling declines and the plain spelling
; (tests/e2e/slice_control_grover_derived_oracle.c) lowers.
;
; NO RED STATE EXISTS on any earlier plugin: this declines on `439dae3`, on
; `f27c7fd` and here. It is a REGRESSION pin on a decline the increment
; deliberately did not lift, not a discriminator for new behaviour.
; `RotationLowering` owns the string; the CHECK mirrors it
; character-for-character. `%off` is a volatile load so nothing folds it away.
;
; SHAPE (`clang -O1` output of):
;     int a = cq_theta(u, 0.5);
;     a += off;
;     if (((a * 5) >> 2) == 5) a = cq_phi(a, PI);
;     a -= off;
;     a = cq_theta(a, -0.5);  return cq_measure(a);
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}in function mc_add_before_sub_after{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @mc_add_before_sub_after(i32 noundef %0, ptr noundef %1) {
  %3 = load volatile i32, ptr %1, align 4
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = add nsw i32 %4, %3
  %6 = ashr i32 %5, 2
  %7 = add nsw i32 %6, %5
  %8 = icmp eq i32 %7, 5
  br i1 %8, label %9, label %11
9:
  %10 = call i32 @cq_phi_si32(i32 noundef %5, double noundef 0x400921FB54442D18)
  br label %11
11:
  %12 = phi i32 [ %10, %9 ], [ %5, %2 ]
  %13 = sub nsw i32 %12, %3
  %14 = call i32 @cq_theta_si32(i32 noundef %13, double noundef -5.000000e-01)
  %15 = call i32 @cq_measure_si32(i32 noundef %14)
  ret i32 %15
}
