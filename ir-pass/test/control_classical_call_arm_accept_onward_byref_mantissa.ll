; control_classical_call_arm_accept_onward_byref_mantissa.ll — ACCEPT (bd 0vvq
; Increment 1): a 6.5 classical-call arm whose UNTAINTED merge `%out` feeds an onward
; `frexp`, with BOTH results consumed as quantum — the mantissa (fp) measured via
; `cq_measure_f64` and the exponent (i32) measured via `cq_measure_si32`.
;
; Companion to control_classical_call_arm_accept_onward_byref_math.ll (exponent-only,
; dead mantissa). Here NO marker is dead: the re-run g387 lowers `frexp` to the
; `@cq_byref_frexp` (mantissa) + `@cq_byref_frexpexp` (exponent) producers, both
; reversible functions of `%out` (`x = m·2^e`), each measured. Pins the fp-mantissa
; onward-quantum path (`cqrt_measure_f64` re-types the i32 producer handle).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_measure_f64(double)
declare i32 @f(i32) #0
declare double @frexp(double, ptr)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)
define i32 @example(i32 %u0, i32 %a) {
entry:
  %e = alloca i32, align 4
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %d = sitofp i32 %y to double
  call void @llvm.lifetime.start.p0(i64 4, ptr %e)
  %m = call double @frexp(double %d, ptr %e)         ; mantissa
  %mm = call double @cq_measure_f64(double %m)        ; measured (fp)
  %ev = load i32, ptr %e, align 4                     ; exponent
  %r2 = call i32 @cq_measure_si32(i32 %ev)            ; measured (i32)
  call void @llvm.lifetime.end.p0(i64 4, ptr %e)
  ret i32 %r2
}
attributes #0 = { nounwind willreturn memory(none) }

; %out build, sitofp cast, BOTH re-run markers, BOTH measures:
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[OUT]])
; CHECK:     %[[MAN:[a-zA-Z0-9_.]+]] = call i32 @cq_template_frexp_f64(i32 %[[CAST]])
; CHECK:     %[[EXP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_frexpexp_f64_to_i32(i32 %[[CAST]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[MAN]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[EXP]])
; CHECK-NOT: call double @frexp
; ACC-NOT:   under quantum control
