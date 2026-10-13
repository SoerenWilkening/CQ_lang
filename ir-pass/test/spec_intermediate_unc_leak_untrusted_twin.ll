; spec_intermediate_unc_leak_untrusted_twin.ll — ACCEPT, LEFT ALLOCATED (bd
; test_C_libtooling-p3kd.13): the two refusals of `isCloneProducer` that are not
; the duplication fence (CloneProducer.h (P3) second half, (P4)).
;
; @presupplied — the module already DEFINES `@__cq_q_inner_1_unc`, with an EMPTY
;   body (the bd 9oob shape: a reserved-name symbol from a library TU). Nothing in
;   the specializer synthesized or adopted it — no inner call needed a twin — so it
;   is not in `taint.SpecHandleArgMask` and the spine must not call it: an empty
;   "adjoint" followed by `cqrt_free(%r)` would reset a rail still holding 3q + 1
;   (a hidden measurement). The rail is left allocated instead, and no second
;   twin is synthesized under another name. (A pre-supplied twin that an INNER call
;   adopted is trusted at the top level too: that program already calls it as the
;   inner adjoint — bd 9oob, P1, open — so no program newly enters 9oob.)
; @undef_arg — the call passes a literal `undef` in its classical slot. The forward
;   reads that undef once; a twin call would read it again, independently, and
;   could compute a different f (the bd xy9n hazard at the CALL SITE, and the second
;   slot `declineUnpairedUndefLiterals` would refuse). Left allocated: main db4cf60a's
;   stream, unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOCALL < %t.ll

; SILENT-NOT: {{.}}

; CHECK-LABEL: define i32 @presupplied(
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call fastcc i32 @__cq_q_inner_1(
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R]], i32 5)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S]])
; CHECK-NEXT: ret i32

; CHECK-LABEL: define i32 @undef_arg(
; CHECK:      %[[R2:[a-zA-Z0-9_.]+]] = call fastcc i32 @__cq_q_inner2_01(i32 %{{[a-zA-Z0-9_.]+}}, i32 undef)
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R2]], i32 5)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S2]])
; CHECK-NEXT: ret i32

; The user's symbol is never called, no `.1`-renamed twin is minted beside it,
; the undef-argument clone gets no twin, and neither clone rail is freed.
; NOCALL-NOT: call {{.*}}@__cq_q_inner_1_unc
; NOCALL-NOT: @__cq_q_inner_1_unc.
; NOCALL-NOT: @__cq_q_inner2_01_unc
; NOCALL-NOT: call void @cqrt_free(i32 %r)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal fastcc i32 @inner(i32 %x) #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}

define internal fastcc i32 @inner2(i32 %x, i32 %k) #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, %k
  ret i32 %b
}

; A reserved-name definition the specializer never built.
define void @__cq_q_inner_1_unc(i32 %out, i32 %x) {
  ret void
}

define i32 @presupplied(i32 %u) {
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call fastcc i32 @inner(i32 %q)
  %s = mul nsw i32 %r, 5
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

define i32 @undef_arg(i32 %u) {
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call fastcc i32 @inner2(i32 %q, i32 undef)
  %s = mul nsw i32 %r, 5
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
