; control_select_reject_round2_copy_source.ll — DECLINE (bd
; test_C_libtooling-r2j3.14, a PRE-EXISTING silent miscompile on main 7b4e6359,
; found by the Rule-11 review of 8h7d.17, round 1; hand-written, the reviewer's
; probe rv-C1/p5). A 6.5 classical-call diamond feeds a 4.4 select arm:
;
;     int y = 5; if (q > 5) y = ext_f(7);   // 6.5: y becomes the merge %out
;     int x = (p > 3) ? y + 1 : 7;          // 4.4 select, tainted condition
;     return cq_measure(x);
;
; THE MISCOMPILE THIS DECLINE REPLACES (measured on main: `cq-opt` exit 0, stage
; 2b 0 violations). The select is emitted in ROUND 1, when `y + 1` is still
; classical, so `materializeCopySource` loads it as a classical copy source,
; `%selop = cqrt_alloc_i32(%yp1)`. Round-1 emission of the 6.5 region then
; replaces y by its merge register, round 2 taints `y + 1` (lowerOps makes it an
; in-place `cqrt_addc_i32(%out, 1)`), and the alloc's operand becomes the
; register's HANDLE ID: the emitted `cqrt_alloc_i32(i32 %out)` loads the number
; 3 (in the trace) where the source selects y + 1 in {6, 108}.
;
; THE FENCE (L1). `materializeCopySource` RECORDS every classical copy source it
; loads; `declineQuantumCopySources` RE-ASKS at FINAL taint, in the slot after
; the round-2 fixpoint where `declineQuantumCondLiterals` re-asks a condition
; literal (both entry points), whether the loaded value is now quantum, and
; declines loudly. Lowering it is a gap (R1): the correct stream reads the arm's
; register directly, as the emitter does for an arm already quantum at emission.
; The 8h7d.17 escape register reaches the same fence
; (control_select_reject_round2_copy_source_break_escape.ll).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: classical copy source became quantum-derived under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @g(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %p = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #2
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %t, label %m

t:
  %e = tail call i32 @ext_f(i32 noundef 7) #4
  br label %m

m:
  %y = phi i32 [ %e, %t ], [ 5, %entry ]
  %yp1 = add i32 %y, 1
  %sc = icmp sgt i32 %p, 3
  %x = select i1 %sc, i32 %yp1, i32 7
  %a = tail call i32 @cq_measure_si32(i32 noundef %x) #3
  ret i32 %a
}

define i32 @ext_f(i32 noundef %a) local_unnamed_addr #5 {
  %r = add nsw i32 %a, 100
  ret i32 %r
}

define i32 @main() #0 {
  %a = call i32 @g(i32 3, i32 5)
  ret i32 0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
attributes #4 = { nounwind willreturn memory(none) }
attributes #5 = { noinline nounwind willreturn memory(none) mustprogress }
