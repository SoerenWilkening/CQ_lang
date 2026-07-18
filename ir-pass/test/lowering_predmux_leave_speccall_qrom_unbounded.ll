; lowering_predmux_leave_speccall_qrom_unbounded.ll — DECLINE probe (bd 20xt.4
; Inc 2, blocker c Rule-13 fix): a pending-spec pure callee whose const-global
; QROM read has an UNBOUNDED index (`return T[a]` — NO internal `& (N-1)` mask),
; hoisted under quantum control. The pure-callee proof admits the read STRUCTURALLY
; (qromReadShapeInScope is bounds-blind — Rule 14), so the flatten hoists the call
; and the Phase-6 clone tries to lower the STRAIGHT-LINE read. Because the clone
; body has NO internal control, lowerCloneControl masks nothing and
; classifyQromReadUnderControl (the pow2-mask / non-pow2-decline discipline) never
; runs — the straight-line clone emitter would otherwise emit
; `cqrt_qram_load(arr_N, %a)` UNMASKED over the RAW speculated argument, reading
; OUT OF BOUNDS on every basis state the caller's guard excluded (out-of-contract
; for the frozen QROM ABI: idx ∈ [0,N), OOB undefined). The clone-read fence
; `qromIndexKnownInBounds` DECLINES it (over-declining is safe). CONTRAST: the ACCEPT
; twin lowering_predmux_speccall_flatten_qrom.ll masks the index internally
; (`and %a, 3` → provably in-bounds) and lowers; the DIRECT under-control read of
; this same table masks (pow2) or declines (non-pow2) via classifyQromReadUnderControl.
; A non-pow2 [3] table is used so the read is unambiguously OOB (no pow2 mask exists).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq QRAM load: speculated const-global table read in a specialized clone: index not provably in-bounds
; CHECK-NOT: cqrt_qram_load
@T = internal unnamed_addr constant [3 x i32] [i32 11, i32 22, i32 33], align 16
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; The QROM read index is the RAW argument — NOT intrinsically bounded.
define i32 @purefn(i32 %a) {
  %idx = zext i32 %a to i64
  %p = getelementptr inbounds [3 x i32], ptr @T, i64 0, i64 %idx
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, %a
  ret i32 %r
}

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @purefn(i32 %q)
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
