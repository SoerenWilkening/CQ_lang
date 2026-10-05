; lowering_loop_break_qq_phase.ll — POSITIVE emission (Phase 7.4, epic y05j;
; coverage test_C_libtooling-mvrb; RE-SPELLED for bd test_C_libtooling-3by9).
; A value-arm `break` whose tainted Q==Q condition compares the rail against a
; loop-invariant comparand `p` that carries a RELATIVE PHASE — a register-free
; kickback on `p` placed before the loop. The module below is `clang -O1`'s
; output for this C, unedited apart from the ModuleID / source_filename lines:
;
;     int break_qq_phase(int x, int pseed, int n) {
;         int p = pseed; cq_theta(&p, 0.5);
;         if (p == 3) cq_phi(0.3);        // |3> of p now carries e^{i 0.3}
;         int q = x; cq_theta(&q, 0.25);
;         for (int i = 0; i < n; i++) { q = q ^ 9; if (q == p) break; }
;         return cq_measure(q);
;     }
;
; HISTORY. The file was written (mvrb) for the pre-3qlq register form
; `p = cq_phi(p0, 0.3)`; 3qlq deleted that uncontrolled call as a global phase,
; and the jttf re-spell to the kickback above was BLOCKED because the C declined
; `cq loop lowering: early break preserves a phase answer`: B3's
; `breakLineageCarriesPhase` asked `functionCarriesBranchPhase` first, so ANY
; tainted-control branch phase anywhere in the function made the escaping answer
; phase-class (bd 3by9, an R1 over-decline). B3 now asks
; `lineageCarriesBranchPhase` (TaintPropagation.h): does some branch phase's
; CONTROL (its transitively controlling tainted conditions, or a tainted angle)
; share a tainted value with the ESCAPING ANSWER's operand lineage? Here the
; phase's only controller is `p == 3`, whose lineage is {p}; the answer's lineage
; is the rail chain {q0, the rail phi, q ^ 9}. Disjoint, so the loop lowers.
;
; THE TRACE ARGUMENT for the stream pinned below (R2; no simulator).
;  (1) The kickback block is `f = [p==3]` XORed into a fresh |0> flag (a basis
;      permutation), `cqrt_rz_i1(f, 0.3)` (diagonal on f: a relative e^{i 0.3} on
;      the f=1 branch, up to a global phase), the `_unc` strip (the same XOR, so f
;      is |0> on EVERY basis branch, hence on the superposition), and ONE
;      `cqrt_free(f)` of that provably-|0> flag (R5: a reset of |0> is not a
;      measurement). Net effect: D = diag(e^{i 0.3 [p==3]}) on p, nothing else.
;  (2) The break construct U (from the `cq.brk.R` mint to the R/idx frees in
;      `cq.brk.tail`) is the identical gate sequence lowering_loop_break_qq.ll
;      pins (cleared by the 7.4 Rule-13 rounds): for every basis input
;      |q0>|p>|0>_R|0>_idx|0>_out it ends in |q0>|p>|0>|0>|f(q0,p)>, f the
;      source's break answer. In U the handle of `p` appears ONLY as the second
;      operand of `cq_template_icmp_eq_i32` and its `_unc` (forward body and the
;      `cq.brk.rev` clone): read as a control, never written, copied, swapped,
;      reverse-played or freed. So U is block-diagonal in p's basis and
;      U·D = D·U exactly.
;  (3) By linearity U maps the phased input Σ c·e^{i 0.3 [p==3]}|q0,p,0,0,0> to
;      Σ c·e^{i 0.3 [p==3]}|q0,p,0,0,f(q0,p)>: the phase rides on the amplitude,
;      untouched. Every `cqrt_free` inside U frees a register that is |0> on
;      every basis branch, so none is a hidden measurement. `p` is left allocated
;      (Ry-prepared and entangled with `out`, never provably |0>), as is the rail
;      (restored to q0 by the reverse-play, still entangled with `out`).
;  (4) The argument covers the REGISTERS, not classical state: the break is
;      virtual (the loop runs its full classical trip), so a value computed
;      INSIDE the loop and read after it would hold its full-trip value, and a
;      phase keyed on it would not be "a later gate" on the source's state. Here
;      nothing but the answer leaves the loop; the emitter's E16 refuses any
;      other escape (bd 923w, lowering_reject_break_escape_classical_counter.ll).
; So the whole stream is D followed by the unchanged construct: the kickback
; `cqrt_rz_i1` before the loop, NO phase gate inside the construct, p never freed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PHASE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PLEAK < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RLEAK < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
;
; --- p minted and rotated, then the kickback on p's flag, all BEFORE q is minted
; CHECK-LABEL: define i32 @break_qq_phase(
; CHECK: [[P:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[P]], double 5.000000e-01)
; CHECK-NEXT: [[F:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 [[P]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 [[F]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[F]], i32 [[P]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 [[F]])
; CHECK-NEXT: [[RAIL:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[RAIL]], double 2.500000e-01)
; --- the 7.4 scratch, minted |0> in the preheader
; CHECK: %cq.brk.R = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %cq.brk.idx = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %cq.brk.out = call i32 @cqrt_alloc_i32(i32 0)
; --- FORWARD body: in-place rail xor, the bare Q==Q compare (rail vs p), the
;     index-gated copy-not-move capture, the compare's `_unc`
; CHECK: call void @cqrt_xorc_i32(i32 [[RAIL]], i32 9)
; CHECK-NEXT: [[FCMP:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32(i32 [[RAIL]], i32 [[P]])
; CHECK: call void @cqrt_toffoli(i32 [[FCMP]],
; CHECK: call void @cqrt_copy_i32_controlled(i32 %cq.brk.fire, i32 [[RAIL]], i32 %cq.brk.R)
; CHECK: call void @cq_template_icmp_eq_i32_unc(i32 [[FCMP]], i32 [[RAIL]], i32 [[P]])
; CHECK-NEXT: call void @cqrt_free(i32 [[FCMP]])
; --- exit consolidation + the copy-out into `out`
; CHECK: call void @cqrt_copy_i32(i32 %cq.brk.R, i32 %cq.brk.out)
; --- BACKWARD reverse-play: the SAME compare (rail vs p), then the inverse rail xor
; CHECK: cq.brk.rev:
; CHECK: [[BCMP:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32(i32 [[RAIL]], i32 [[P]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 [[BCMP]],
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_unc(i32 [[BCMP]], i32 [[RAIL]], i32 [[P]])
; CHECK: call void @cqrt_xorc_i32(i32 [[RAIL]], i32 9)
; CHECK: cq.brk.tail:
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.R)
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
;
; --- EXACTLY ONE phase gate in the module — the kickback above, before the
;     construct — and no `cqrt_x` bracket (the phase is on the true arm), no
;     swap. A phase gate inside the construct would fire on every iteration of
;     the full classical trip, not up to the break.
; PHASE-COUNT-1: call void @cqrt_rz_
; PHASE-NOT: call void @cqrt_rz_
; PHASE-NOT: call void @cqrt_x(
; PHASE-NOT: @cqrt_cswap
;
; --- p is never freed (R5): it is Ry-prepared and entangled with `out`.
; PLEAK: [[P2:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; PLEAK-NOT: call void @cqrt_free(i32 [[P2]])
;
; --- the rail is never freed either: the reverse-play restores it to q0, still
;     entangled with `out`.
; RLEAK: [[R2:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; RLEAK-NOT: call void @cqrt_free(i32 [[R2]])
;
; --- the free census: 14 sites of the break construct (forward body 5, exit
;     consolidation 2, reverse-play body 5, R and idx 2: the count the same
;     construct emits beside a phase-free comparand) + 1 for the kickback flag.
; FCNT-COUNT-15: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @break_qq_phase(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
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
