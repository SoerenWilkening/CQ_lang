; control_peel_reject_guarded_store.ll — DECLINE `cq controlled lowering: guarded
; store with a merge value under quantum control` (bd test_C_libtooling-b6ap,
; Rule-13 ROUND-1 finding F-B6-2, P10).
;
; ⚠ THE CONTAINMENT GATE'S BLIND SPOT, FENCED. The peel's `>= 2`-phi containment
; argument is that every site it touches ALREADY declines loudly, and one of its
; bullets was "`classifyGuardedStoreArm` LOUD-declines on any merge φ at all". True,
; and INSUFFICIENT: that decline keys on the very phis the peel DELETES. Peel both
; and the 7.5 guarded Shadow store region flips DECLINE → ACCEPT.
;
; MEASURED at the hand-back tree (probe `g01_guarded_store_2phi.c`, this module's
; source): `opt` exit 0, 35 trace lines, and the ENTIRE 7.5 reversal spine absent —
; no `cqrt_qram_load_i32_unc`, no `cqrt_qram_store_i32_controlled_unc`, no strip and
; no free of the guarded store's path-predicate flag, no `cqrt_ry` inverse. Stage 2b
; reported `10 rail mint(s) of which 10 left allocated, 0 violation(s)`, because a
; leak is Rule-6's SAFE direction and 2b is structurally blind to it. The control
; `g02_guarded_ctrl.c` — the same program with the two extra registers NOT in the
; merge, so no phi and no peel — runs the COMPLETE reversal on the oracle, which is
; what attributes the difference to the new accept rather than to the registers.
;
; A brand-new accept in the 7.5 QRAM neighbourhood behaving materially unlike its
; shipped sibling is a Prime-Directive decline, not something this increment may
; bless. P10 refuses any site whose ARM writes memory (`StoreInst` / atomic), so the
; region keeps the string below. Whether the reversal SHOULD run for a merge-valued
; guarded store is an OPEN QUESTION for its own row, recorded in `FIX_b6ap_R1.md`.
;
; PINS BOTH DIRECTIONS: `control_peel_guarded_store_ctrl_unchanged.ll` is the g02
; control — an ACCEPT, byte-identical on both binaries — so P10 cannot be a blanket
; refusal of the guarded-store shape.
;
; NOT RED-GREEN AGAINST `main`: this fixture asserts a decline the oracle ALSO gives
; (that is the point — the string must not move). It is RED against the hand-back
; tree, where it exited 0; the mutant that reddens it now is deleting `armWritesMemory`
; from the P10 clause in `MergePhiPeel.cpp`.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout — the `not` inversion on the RUN
; line plus the mirrored string is what pins it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

define internal fastcc i32 @guarded_local() unnamed_addr {
  %1 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %1)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %1, i8 0, i64 32, i1 false)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01)
  %4 = icmp slt i32 %2, 3
  br i1 %4, label %5, label %8

5:                                                ; preds = %0
  %6 = sext i32 %3 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %6
  store i32 7, ptr %7, align 4
  br label %8

8:                                                ; preds = %5, %0
  %9 = phi i32 [ 2, %5 ], [ 6, %0 ]
  %10 = phi i32 [ 1, %5 ], [ 5, %0 ]
  %11 = sext i32 %2 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %16 = add nsw i32 %15, %14
  %17 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %18 = add nsw i32 %16, %17
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %1)
  ret i32 %18
}

define noundef i32 @main() local_unnamed_addr {
  %1 = tail call fastcc i32 @guarded_local()
  ret i32 %1
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; CHECK: cq controlled lowering: guarded store with a merge value under quantum control
