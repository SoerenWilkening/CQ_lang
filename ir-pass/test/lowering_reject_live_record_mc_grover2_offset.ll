; lowering_reject_live_record_mc_grover2_offset.ll — LOUD DECLINE (M-A, the late-slot
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
;     the 2-iteration derived-oracle Grover written with the offset trick:
;     S; q += off; O(derived); q -= off; S-; R0;  S; q += off; O; q -= off; S-; R0; S; M
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}in function mc_grover2_offset{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @mc_grover2_offset(ptr noundef %0) {
  %2 = load volatile i32, ptr %0, align 4
  %3 = call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %4 = add nsw i32 %3, %2
  %5 = ashr i32 %4, 2
  %6 = add nsw i32 %5, %4
  %7 = icmp eq i32 %6, 5
  br i1 %7, label %8, label %10
8:
  %9 = call i32 @cq_phi_si32(i32 noundef %4, double noundef 0x400921FB54442D18)
  br label %10
10:
  %11 = phi i32 [ %9, %8 ], [ %4, %1 ]
  %12 = sub nsw i32 %11, %2
  %13 = call i32 @cq_theta_si32(i32 noundef %12, double noundef -5.000000e-01)
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %17
15:
  %16 = call i32 @cq_phi_si32(i32 noundef 0, double noundef 0x400921FB54442D18)
  br label %17
17:
  %18 = phi i32 [ %16, %15 ], [ %13, %10 ]
  %19 = call i32 @cq_theta_si32(i32 noundef %18, double noundef 5.000000e-01)
  %20 = add nsw i32 %19, %2
  %21 = ashr i32 %20, 2
  %22 = add nsw i32 %21, %20
  %23 = icmp eq i32 %22, 5
  br i1 %23, label %24, label %26
24:
  %25 = call i32 @cq_phi_si32(i32 noundef %20, double noundef 0x400921FB54442D18)
  br label %26
26:
  %27 = phi i32 [ %25, %24 ], [ %20, %17 ]
  %28 = sub nsw i32 %27, %2
  %29 = call i32 @cq_theta_si32(i32 noundef %28, double noundef -5.000000e-01)
  %30 = icmp eq i32 %29, 0
  br i1 %30, label %31, label %33
31:
  %32 = call i32 @cq_phi_si32(i32 noundef 0, double noundef 0x400921FB54442D18)
  br label %33
33:
  %34 = phi i32 [ %32, %31 ], [ %29, %26 ]
  %35 = call i32 @cq_theta_si32(i32 noundef %34, double noundef 5.000000e-01)
  %36 = call i32 @cq_measure_si32(i32 noundef %35)
  ret i32 %36
}
