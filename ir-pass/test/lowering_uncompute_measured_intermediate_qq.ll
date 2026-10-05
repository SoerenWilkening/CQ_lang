; lowering_uncompute_measured_intermediate_qq.ll — ACCEPT since bd
; test_C_libtooling-ptue (was the Phase 5 WI-5 DECLINE / WI-4 both-parent-scan
; lock, PRD §2.5 / §2.11 / §2.12). A DEAD two-quantum-operand product
; `prod = q1 * q2` whose SECOND parent `q2` is later measured.
;
; THE HISTORY. The whole-DAG recovery hops BOTH tainted parents, reaches `q2` and
; finds its measure; reversing THAT DAG would un-rotate and free `q2` before the
; user's measurement read it (Rule 5/6). The pin was that the scan covers the
; SECOND parent (a one-parent scan would miss `q2` and free it).
;
; WHY IT IS NOW AN ACCEPT, AND WHAT STILL PINS THE BOTH-PARENT SCAN. Since ptue
; the driver retries with every rail the scan saw measured BORROWED — read-only,
; never adjointed or freed. The scan still has to SEE `q2`'s measure: a one-parent
; scan would leave `q2` OWNED, and the stream would then un-rotate `q2`
; (`cqrt_ry(%q2, -0.35)`) before its measure — exactly what NOQ2 forbids. So the
; regression this file locked is still locked, by a stronger property than a
; diagnostic. Hand trace, Ry|x> = Σ_v a_v|v> on q1, Ry|y> = Σ_w b_w|w> on q2:
;   mul(q1, q2)             Σ a_v b_w |v>|w>|v*w>
;   mul_unc(prod, q1, q2)   Σ a_v b_w |v>|w>|0>       (neither parent moved)
;   cqrt_free(prod)         |0> in a product state — no information learned
;   ry(q1, -.25)            q1 back to |x>: `q1` is DEAD and owned, so its prep is
;                           reverse-played and the rail kept (seed not |0>, bd 5c5b)
;   measure(q2)             P(w) = |b_w|^2, the program's distribution
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ2 < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %x, i32 %y) {
entry:
  %q1   = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %q2   = call i32 @cq_theta_si32(i32 %y, double 3.500000e-01)
  %prod = mul i32 %q1, %q2                        ; DEAD QQ terminal
  %m    = call i32 @cq_measure_si32(i32 %q2)      ; measures the SECOND parent's register
  ret i32 %m
}

; CHECK-LABEL: define i32 @slice(i32 %x, i32 %y)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 2.500000e-01)
; CHECK-NEXT:  %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[B]], double 3.500000e-01)
; CHECK-NEXT:  %[[P:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[A]], i32 %[[B]])
; CHECK-NEXT:  call void @cq_template_mul_i32_unc(i32 %[[P]], i32 %[[A]], i32 %[[B]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[P]])
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double -2.500000e-01)
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[B]])
; CHECK-NEXT:  ret i32 %[[M]]

; The measured SECOND parent is never un-rotated and never freed (window =
; its alloc -> EOF):
; NOQ2:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y)
; NOQ2-NOT: call void @cqrt_ry_i32(i32 %[[R]], double -3.500000e-01)
; NOQ2-NOT: call void @cqrt_free(i32 %[[R]])
