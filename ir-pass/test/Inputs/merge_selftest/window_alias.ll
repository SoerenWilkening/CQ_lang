; window_alias.ll — cq-merge-selftest input (NOT a lit test: `Inputs/` is
; excluded; ctest `ir-pass-merge-discharge-selftest` runs it). bd
; test_C_libtooling-r2j3.32 R11 round 1 item 5: the window check FAILS CLOSED
; through every alias of a stream register. Hand-written LOWERED IR, because
; the pass declines every source program that writes an alias of a stream
; register inside the window before discharge ever runs (`condition predates a
; non-diagonal gate`, `routed base predates …`, the classical-mux and
; taint-escape guards — measured 2026-10-15), so only this driver can pin an
; unsound LOOSENING of the check.
;
; The stream is the shipped 4.4 select merge, verbatim from the lowering of
; `q = θ(u); p = θ(v); out = q > 5 ? 5p : p`: out ^= f·5p, out ^= ¬f·p, the
; flag strip, its free. Its readers: the compare `out == 7`. In every `_kept`
; case a register the stream READ (the condition q or the copied source p) is
; rotated by `cqrt_ry_i32` through an ALIAS — a select, a φ, a memory
; park/reload — between the stream and that reader. Replaying the stream there
; would re-run the copies and the deferred strip on a rotated register: the
; copies would no longer cancel and the strip would not return the flag to
; |0> (a dirty free). So %out must stay ALLOCATED.
;   * sel_alias_kept    kills the "narrow isRegister" mutant (a select is a
;                       register; dropping it hides the rotation);
;   * phi_alias_kept    the same through a φ (the window spans a diamond);
;   * mem_park_kept     kills the "ignore memory hops" mutant (a store to
;                       memory that is not a proven rail bank refuses).
;   * window_ctl_discharged is the non-vacuity control: the same stream with
;                       the rotation removed IS discharged.

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cqrt_copy_i32_controlled(i32, i32, i32)
declare void @cqrt_x(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)

define i32 @window_ctl_discharged(i32 %u0, i32 %v0, i1 %k) #0 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i32(i32 %v0)
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h1, i32 5)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp)
  %e = call i32 @cq_template_icmp_eq_i32_hl(i32 %out, i32 7)
  %m = call i32 @cqrt_measure_i32(i32 %e)
  ret i32 %m
}

define i32 @sel_alias_kept(i32 %u0, i32 %v0, i1 %k) #1 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i32(i32 %v0)
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h1, i32 5)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp)
  %hs = select i1 %k, i32 %h, i32 %h
  call void @cqrt_ry_i32(i32 %hs, double 3.000000e-01)
  %e = call i32 @cq_template_icmp_eq_i32_hl(i32 %out, i32 7)
  %m = call i32 @cqrt_measure_i32(i32 %e)
  ret i32 %m
}

define i32 @phi_alias_kept(i32 %u0, i32 %v0, i1 %k) #1 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i32(i32 %v0)
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h1, i32 5)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp)
  br i1 %k, label %l1, label %l2
l1:
  br label %join
l2:
  br label %join
join:
  %pa = phi i32 [ %h1, %l1 ], [ %h1, %l2 ]
  call void @cqrt_ry_i32(i32 %pa, double 3.000000e-01)
  %e = call i32 @cq_template_icmp_eq_i32_hl(i32 %out, i32 7)
  %m = call i32 @cqrt_measure_i32(i32 %e)
  ret i32 %m
}

define i32 @mem_park_kept(i32 %u0, i32 %v0, i1 %k) #1 {
entry:
  %slot = alloca i32
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i32(i32 %v0)
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h1, i32 5)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp)
  store i32 %h, ptr %slot
  %hl = load i32, ptr %slot
  call void @cqrt_ry_i32(i32 %hl, double 3.000000e-01)
  %e = call i32 @cq_template_icmp_eq_i32_hl(i32 %out, i32 7)
  %m = call i32 @cqrt_measure_i32(i32 %e)
  ret i32 %m
}

attributes #0 = { "cq-selftest-expect"="discharged" }
attributes #1 = { "cq-selftest-expect"="kept" }

!0 = !{}
