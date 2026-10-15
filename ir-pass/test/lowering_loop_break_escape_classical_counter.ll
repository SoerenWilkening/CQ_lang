; lowering_loop_break_escape_classical_counter.ll — POSITIVE emission (bd
; test_C_libtooling-8h7d.17; a DECLINE until then, named
; lowering_reject_break_escape_classical_counter.ll, bd 923w). A 7.4 value-arm
; break whose loop COUNTER escapes through an exit φ and keys a branch phase
; after the loop. The module is lowering_loop_break_qq_phase.ll's `clang -O1`
; output plus, in the exit merge, the LCSSA φ of `i.next` and a phase under it
; (hand-added; `-O1` C does not reach it today: an escaping counter makes `-O1`
; keep the break and the bound as two exits, which decline at L1 `loop under
; quantum control`, and the AND / `slt` continue-polarity form declines at
; E2/E4):
;
;     %iex = phi i32 [ 0, %7 ], [ %15, %10 ]     ; %15 = i.next
;     %c2  = icmp eq i32 %iex, 2
;     br i1 %c2, label %ph, label %end
;     ph:  call void @cq_phi(double 7.0e-01)
;
; THE HAZARD (bd 923w, measured on the 3by9 head dc192929). The 7.4 lowering
; realizes the break VIRTUALLY: `emitBreakForward` strips the tainted break flag
; from the loop terminator, so the rolled loop runs its full classical trip on
; every branch. `%iex` then leaves the loop as its full-trip value n, not the
; source's value (the break iteration + 1, a function of q0 and p), and with no
; tainted control left above `ph`, `deleteGlobalPhases` deleted the phase as
; global. 923w made that a loud decline (E16).
;
; THE LOWERING (8h7d.17). `%iex` is a CONTROL-MERGE value: which iteration
; fed it depends on when the quantum break fired. E16 now admits an UNTAINTED
; exit φ whose loop-edge value V (here `i.next`) is a pure function of the
; counter and loop invariants, and lowers it like the answer: a capture
; register `cq.brk.esc.R` and an output register `cq.brk.esc.out`, both minted
; |0> in the guard; the φ's users are rewired to `cq.brk.esc.out`, which is
; registered as a control-merge rail, so round 2 taints `%c2` and lowers `ph` by
; kickback. `%iex` itself stays, classical: on the virtual loop it holds the
; NEVER-FIRED value (n after a full trip, 0 on the zero-trip edge).
;
; THE TRACE ARGUMENT for the stream pinned below (R2; no simulator). Fix a basis
; input |q0>|p>. Let k* be the first iteration whose break flag is 1, if any; the
; construct's `fire` is 1 in iteration k* and 0 in every other (its documented
; invariant, lowering_loop_break_qq.ll), and `idx` ends k* + 1 if k* exists, else 0.
;  (1) Forward body: right after the rail capture, `t = alloc(V)` (the classical
;      i.next of this iteration), `esc.R ^= fire ? t : 0`, `t -= V`, `free(t)`. t
;      holds a classical value, is read only as a copy source, and is returned to
;      |0> on every branch, so its free measures nothing (R5). After the loop
;      esc.R = V(k*) if k* exists, else 0.
;  (2) Exit consolidation, with e0 = [idx == 0] (never fired, or zero trip):
;      `esc.R ^= e0 ? %iex : 0` (materialized the same way), so esc.R = V(k*) if
;      k* exists, else %iex: n after the full trip that never fired, 0 on the
;      zero-trip edge. That is the source's `%iex` on every branch. The copy-out
;      `esc.out ^= esc.R` records it, and the consolidation reverse undoes the e0
;      term (idx is unchanged by these copies, so e0 is the same flag).
;  (3) Reverse-play, iteration i': `fire' = [idx == i' + 1]` is the forward fire
;      of iteration i' (the construct's existing argument); while it is set, V is
;      recomputed from i' by cloning its classical cone (`i' + 1`) and
;      `esc.R ^= fire' ? V(i') : 0` cancels the forward capture exactly once, at
;      i' = k*. esc.R is then |0> on every branch and is freed after R and idx,
;      under the same `OK` gate (the R argument in BreakReversePlay.cpp applies:
;      written only by controlled copies, copied out, returned by its exact
;      adjoint, no rotation).
;  (4) In `cq.brk.tail`, after the frees, the kickback on `esc.out == 2`: flag
;      mint, `cqrt_rz_i1(f, 0.7)`, `_unc`, free of the |0> flag. Its key holds the
;      source's `%iex`, so it is the source's phase. The pre-loop kickback on
;      `p == 3` and the construct are lowering_loop_break_qq_phase.ll's.
; `esc.out` is not freed: it carries the answer's which-iteration information.
;
; The loop-INVARIANT twin (lowering_loop_break_escape_invariant_classical.ll)
; carries `n` out through the same φ position; it needs no capture and still
; lowers to a deleted global phase. The decline twin
; (lowering_reject_break_escape_counter_classical_sink.ll) hands `%iex` to an
; opaque external, which stays loud.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=PHASE < %t.ll
; RUN: %filecheck %s --check-prefix=OLEAK < %t.ll
;
; CHECK-LABEL: define i32 @break_escape_counter(
; CHECK: [[RAIL:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK: %cq.brk.R = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %cq.brk.idx = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %cq.brk.out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %cq.brk.esc.R = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %cq.brk.esc.out = call i32 @cqrt_alloc_i32(i32 0)
; --- (1) forward: the escape capture right after the rail capture
; CHECK: [[INEXT:%[0-9]+]] = add nuw nsw i32 %{{[0-9]+}}, 1
; CHECK: call void @cqrt_copy_i32_controlled(i32 %cq.brk.fire, i32 [[RAIL]], i32 %cq.brk.R)
; (bd dm7f.81: the classical escape value is the literal operand of a controlled
; xor, no longer loaded into a scratch rail, copied, unloaded and freed.)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %cq.brk.fire, i32 %cq.brk.esc.R, i32 [[INEXT]])
; CHECK: br i1 %{{[0-9]+}}, label %[[EXIT:[0-9]+]], label %{{[0-9]+}}, !llvm.loop
; --- (2) the exit consolidation, the two copy-outs, the consolidation reverse
; CHECK: {{^}}[[EXIT]]:
; CHECK: %iex = phi i32 [ 0, %{{[0-9]+}} ], [ [[INEXT]], %{{[0-9]+}} ]
; CHECK-NEXT: [[E0:%cq.brk.eqz[0-9]*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.brk.idx, i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 [[E0]], i32 [[RAIL]], i32 %cq.brk.R)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 [[E0]], i32 %cq.brk.esc.R, i32 %iex)
; CHECK: call void @cqrt_copy_i32(i32 %cq.brk.R, i32 %cq.brk.out)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %cq.brk.esc.R, i32 %cq.brk.esc.out)
; CHECK-NEXT: [[E1:%cq.brk.eqz[0-9]*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.brk.idx, i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 [[E1]], i32 [[RAIL]], i32 %cq.brk.R)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 [[E1]], i32 %cq.brk.esc.R, i32 %iex)
; --- (3) the reverse-play: V recomputed from i' while fire' is set
; CHECK: cq.brk.rev:
; CHECK: call void @cqrt_copy_i32_controlled(i32 [[F2:%cq.brk.fire[0-9]+]], i32 [[RAIL]], i32 %cq.brk.R)
; CHECK-NEXT: [[VP:%cq.brk.ecl[0-9]*]] = add nuw nsw i32 %cq.brk.ip, 1
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 [[F2]], i32 %cq.brk.esc.R, i32 [[VP]])
; --- (4) the tail: the frees, then the kickback on the escape's output register
; CHECK: cq.brk.tail:
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.R)
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.esc.R)
; CHECK-NEXT: [[F:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.brk.esc.out, i32 2)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 [[F]], double 0x3FE6666666666666), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[F]], i32 %cq.brk.esc.out, i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 [[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
;
; --- exactly two phase gates: the pre-loop kickback and the escape's kickback.
; PHASE-COUNT-2: call void @cqrt_rz_
; PHASE-NOT: call void @cqrt_rz_
;
; --- esc.out is never freed (R5: it is not provably |0>).
; OLEAK: %cq.brk.esc.out = call i32 @cqrt_alloc_i32(i32 0)
; OLEAK-NOT: call void @cqrt_free(i32 %cq.brk.esc.out)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @break_escape_counter(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #2
  %5 = icmp eq i32 %4, 3
  br i1 %5, label %6, label %7

6:                                                ; preds = %3
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  br label %7

7:                                                ; preds = %6, %3
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %9 = icmp sgt i32 %2, 0
  br i1 %9, label %10, label %18

10:                                               ; preds = %7, %10
  %11 = phi i32 [ %15, %10 ], [ 0, %7 ]
  %12 = phi i32 [ %13, %10 ], [ %8, %7 ]
  %13 = xor i32 %12, 9
  %14 = icmp eq i32 %13, %4
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %15, %2
  %17 = select i1 %14, i1 true, i1 %16
  br i1 %17, label %18, label %10, !llvm.loop !6

18:                                               ; preds = %10, %7
  %19 = phi i32 [ %8, %7 ], [ %13, %10 ]
  %iex = phi i32 [ 0, %7 ], [ %15, %10 ]
  %c2 = icmp eq i32 %iex, 2
  br i1 %c2, label %ph, label %end

ph:
  tail call void @cq_phi(double noundef 7.000000e-01) #3
  br label %end

end:
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  ret i32 %20
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
