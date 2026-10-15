; control_predmux_accept_int_diamond_constfall_k5.ll — ACCEPT (bd 0rwu, W7):
; a NONZERO `ConstantInt` fall-through.
;
; WHY THIS FIXTURE EXISTS. W7's clause (c) admits ANY `ConstantInt` on the entry
; edge, but the census cells that motivated it (`expl.f80`, `log10l.f80`) both
; fold to `0` — `__isnanl` returns a C `int` 0 on the not-NaN edge. So every
; positive fixture pinned K = 0, where the constant's source rail
; `cqrt_alloc_i32(i32 0)` is indistinguishable from a generic zero-initialized
; rail and the controlled copy of it is a no-op. A K != 0 fall-through therefore
; had NO coverage while being fully in the accept set — flagged by the Rule-13
; round, and exactly the kind of untested-but-admitted corner the Prime Directive
; says not to leave lying around.
;
; The load-bearing assertion is that the constant's rail is allocated with the
; constant's REAL value (`cqrt_alloc_i32(i32 5)`), not a hardcoded 0. Were it
; allocated at 0, this would be a silent miscompile on every basis state that
; selects the fall-through: the merge would read 0 where the source reads 5, and
; nothing else in the stream would look wrong.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi i32'  --implicit-check-not='cqrt_cswap' --implicit-check-not='cqrt_rz' < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %e  = and i32 %q, 32767
  %c  = icmp eq i32 %e, 32767
  br i1 %c, label %arm, label %merge

arm:
  %lo = and i32 %q, 65535
  %n  = icmp ne i32 %lo, 0
  %z  = zext i1 %n to i32
  br label %merge

merge:
  %r = phi i32 [ 5, %entry ], [ %z, %arm ]     ; NONZERO fall-through
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; THE POINT OF THE FIXTURE: the constant rail carries 5, not 0.
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_xorc_i32_controlled(i32 %[[FLAG:[a-zA-Z0-9_.]+]], i32 %[[OUT]], i32 5)
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 32767)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
