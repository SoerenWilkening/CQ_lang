; control_swap_reject_select_badcond.ll — DECLINE: a non-`CmpInst` tainted-i1
; condition (4.4 WI-1 gate 2). The flag is minted from a SINGLE compare via
; `lowerCompareToFlag`; a compound condition (`and i1`/`or i1` — clang's `&&`/`||`
; fold) or any non-compare tainted i1 has no single-compare flag-mint template.
; Declines GENERIC `control flow` — NOT `control condition has no template` and
; NOT the §3c clobber string: a select has no straight-through edge, so the
; clobber proof obligation can never be met, and branding the shape any narrower
; would be the over-claim §8.3 warns against (IMPLEMENTATION-4.4 §0).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c2  = icmp slt i32 %q, 100
  %c   = and i1 %c1, %c2                  ; compound: a non-CmpInst tainted i1
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
