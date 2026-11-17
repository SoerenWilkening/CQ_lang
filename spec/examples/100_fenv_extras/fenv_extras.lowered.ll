; HAND-WRITTEN. Rules: 23, 4, 9, 5, 2.
; Checked: fenv_dfl_env: z + f; fenv_narrow_mask: fetestexcept + (int)z; fenv_op_in_arm: fetestexcept + (int)y;
; fenv_quantum_mode: rc + (int)s (each measured, then combined classically).
; Clean: every intermediate rail (dropped flags states, saved masks, gated exception bits, the quantum mode handle and its
; validity flag, the arm values).
; Kept: the user register of each function (x or m) and the final flags rail of each function (an output, rule 23);
; fenv_op_in_arm's merged value rail y and fenv_quantum_mode's result rails are measured.
; Rotations: Ry(th) on x (fenv_dfl_env, fenv_narrow_mask, fenv_op_in_arm); Ry(th) on m (fenv_quantum_mode).
; Four fenv shapes beyond 80-82, same model (rule 23): the host part goes through the real calls, the quantum part is
; rails; the mode is classical until a quantum value is written into it; the flags rail is sticky and advanced out of
; place; the final flags rail is an output that stays. fenv_dfl_env: fesetenv(FE_DFL_ENV) sets mode 0 and EMPTIES the
; flags rail (the dropped rail is uncomputed in the mirror); feupdateenv(FE_DFL_ENV) restores the default and ORs the
; current flags in, and empty | current is current: no gate. fenv_narrow_mask: fegetexceptflag with mask m saves
; flags & m as the object's quantum part; fesetexceptflag reinstates (current & ~m) | (saved & m) as the new flags rail,
; the previous one dropped. fenv_op_in_arm: a constrained op inside a quantum arm raises only on the arm's branch: its
; exception bits enter the flags through select(pred, exc, 0); the op's value merges by the phi's select (rule 9).
; fenv_quantum_mode: fesetround with an arbitrary quantum argument: valid iff (m & ~0xC00) == 0, mode' = valid ? m : mode
; (a handle from here on), the return value valid ? 0 : 1 is quantum; the classical ops after it take the mode handle
; (_rmq). Mode constants are x86-64's: 0, 1024, 2048, 3072.
source_filename = "fenv_extras.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.fenv_t = type { i16, i16, i32, [8 x i8] }    ; IR: %struct.fenv_t  (the host part keeps its real layout)
@_FE_DFL_ENV = external constant %struct.fenv_t, align 4    ; IR: @_FE_DFL_ENV  (the host's default environment)

define double @fenv_dfl_env(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @fegetround()    ; IR: round.dynamic: the classical entry mode, read once from the host
  %6 = call i32 @cq_template_fmul_f64_hl_rm(i32 %4, double %2, i32 %5)    ; IR: %5 = constrained.fmul(%4, %2, round.dynamic, strict)
  %7 = call i32 @cq_template_fmul_f64_hl_rm_exc(i32 %4, double %2, i32 %5)    ; IR: %5: its exception bits  [the flags rail]
  %8 = call i32 @fesetenv(ptr @_FE_DFL_ENV)    ; IR: %6 = fesetenv(FE_DFL_ENV)  (host call; mode = 0; the flags rail %e0 is DROPPED: the rail is empty again)
  %9 = call i32 @cq_template_fadd_f64_hl_rm(i32 %6, double %2, i32 0)    ; IR: %7 = constrained.fadd(%5, %2, round.dynamic, strict)  [mode = classical 0]
  %10 = call i32 @cq_template_fadd_f64_hl_rm_exc(i32 %6, double %2, i32 0)    ; IR: %7: its exception bits  [the flags rail: first exc after the drop]
  %11 = call i32 @feupdateenv(ptr @_FE_DFL_ENV)    ; IR: %8 = feupdateenv(FE_DFL_ENV)  (host call; mode = 0; flags = empty | %e1 = %e1, no gate)  [final flags rail: an output]
  %12 = call i32 @fetestexcept(i32 63)    ; IR: %9 = fetestexcept(63): the host part
  %13 = call i32 @cq_template_and_i32_hl(i32 %10, i32 63)    ; IR: %9: the quantum part, flags & 63
  %14 = call i32 @cq_template_or_i32_hl(i32 %13, i32 %12)    ; IR: %9 = host | quantum  [result f]
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %10, i32 63)    ; IR: uncompute %9's quantum part
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_rm_exc_unc(i32 %7, i32 %4, double %2, i32 %5)    ; IR: uncompute the dropped flags rail %e0
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_rm_unc(i32 %6, i32 %4, double %2, i32 %5)    ; IR: uncompute %5
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  %15 = call double @cqrt_measure_f64(i32 %9)    ; IR: %10 = cq_measure_f64(%7)
  %16 = call i32 @cqrt_measure_i32(i32 %14)    ; IR: %11 = cq_measure_si32(%9)
  %17 = call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %16, metadata !"round.dynamic", metadata !"fpexcept.strict")    ; IR: %12  (classical, host mode 0)
  %18 = call double @llvm.experimental.constrained.fadd.f64(double %15, double %17, metadata !"round.dynamic", metadata !"fpexcept.strict")    ; IR: %13  (classical, host mode 0)
  ret double %18    ; IR: ret double %13
}

define i32 @fenv_narrow_mask(double noundef %0, double noundef %1, double noundef %2) {
  %4 = alloca i16, align 2    ; IR: %4 = alloca i16  (saved: host part)
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @fegetround()    ; IR: round.dynamic: the classical entry mode, read once from the host
  %7 = call i32 @cq_template_fdiv_f64_hl_rm(i32 %5, double %2, i32 %6)    ; IR: %6 = constrained.fdiv(%5, %2, round.dynamic, strict)
  %8 = call i32 @cq_template_fdiv_f64_hl_rm_exc(i32 %5, double %2, i32 %6)    ; IR: %6: its exception bits  [the flags rail]
  %9 = call i32 @fegetexceptflag(ptr %4, i32 32)    ; IR: %7 = fegetexceptflag(%4, 32)  (host call)
  %10 = call i32 @cq_template_and_i32_hl(i32 %8, i32 32)    ; IR: %7: saved's quantum part = flags & 32
  %11 = call i32 @cq_template_fmul_f64_hl_rm(i32 %7, double %2, i32 %6)    ; IR: %8 = constrained.fmul(%6, %2, round.dynamic, strict)
  %12 = call i32 @cq_template_fmul_f64_hl_rm_exc(i32 %7, double %2, i32 %6)    ; IR: %8: its exception bits
  %13 = call i32 @cq_template_or_i32(i32 %8, i32 %12)    ; IR: %8: flags' = flags | exc
  %14 = call i32 @fesetexceptflag(ptr %4, i32 32)    ; IR: %9 = fesetexceptflag(%4, 32)  (host call)
  %15 = call i32 @cq_template_and_i32_hl(i32 %13, i32 -33)    ; IR: %9: current & ~32
  %16 = call i32 @cq_template_or_i32(i32 %15, i32 %10)    ; IR: %9: flags'' = (current & ~32) | (saved & 32)  [final flags rail: an output; %fl1 is dropped]
  %17 = call i32 @fetestexcept(i32 63)    ; IR: %10 = fetestexcept(63): the host part
  %18 = call i32 @cq_template_and_i32_hl(i32 %16, i32 63)    ; IR: %10: the quantum part
  %19 = call i32 @cq_template_or_i32_hl(i32 %18, i32 %17)    ; IR: %10 = host | quantum  [result]
  call void @cq_template_and_i32_hl_unc(i32 %18, i32 %16, i32 63)    ; IR: uncompute %10's quantum part
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %13, i32 -33)    ; IR: uncompute current & ~32 (%fl2 stays)
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %13, i32 %8, i32 %12)    ; IR: uncompute the dropped flags state after %8
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %8, i32 32)    ; IR: uncompute saved's quantum part
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_rm_exc_unc(i32 %12, i32 %7, double %2, i32 %6)    ; IR: uncompute %8's exception bits
  call void @cqrt_free(i32 %12)    ; IR: release them (|0>)
  call void @cq_template_fdiv_f64_hl_rm_exc_unc(i32 %8, i32 %5, double %2, i32 %6)    ; IR: uncompute %6's exception bits
  call void @cqrt_free(i32 %8)    ; IR: release them (|0>)
  call void @cq_template_fdiv_f64_hl_rm_unc(i32 %7, i32 %5, double %2, i32 %6)    ; IR: uncompute %6
  call void @cqrt_free(i32 %7)    ; IR: release the %6 rail (|0>)
  %20 = call i32 @cqrt_measure_i32(i32 %19)    ; IR: %11 = cq_measure_si32(%10)
  %21 = call double @cqrt_measure_f64(i32 %11)    ; IR: %12 = cq_measure_f64(%8)
  %22 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %21, metadata !"fpexcept.strict")    ; IR: %13  (classical, host flags)
  %23 = add nsw i32 %22, %20    ; IR: %14 = add nsw i32 %13, %11  (classical)
  ret i32 %23    ; IR: ret i32 %14
}

define i32 @fenv_op_in_arm(double noundef %0, double noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @fegetround()    ; IR: round.dynamic: the classical entry mode, read once from the host
  %7 = call i32 @feclearexcept(i32 63)    ; IR: %6 = feclearexcept(63)  (host call; the quantum flags rail is still empty)
  %8 = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %5, double %3)    ; IR: %7 = constrained.fcmps ogt %5, %3  [path predicate of block %8]
  %9 = call i32 @cq_template_fcmps_ogt_f64_hl_exc(i32 %5, double %3)    ; IR: %7: signaling compare, INVALID on a NaN  [the flags rail from here on]
  %10 = call i32 @cq_template_fmul_f64_hl_rm(i32 %5, double %2, i32 %6)    ; IR: block %8: %9 = constrained.fmul(%5, %2, round.dynamic, strict)  (the arm's value, unguarded)
  %11 = call i32 @cq_template_fmul_f64_hl_rm_exc(i32 %5, double %2, i32 %6)    ; IR: %9: its exception bits
  %12 = call i32 @cq_template_select_i32_hl(i32 %8, i32 %11, i32 0)    ; IR: %9 raises only on the arm's branch: pred ? exc : 0
  %13 = call i32 @cq_template_or_i32(i32 %9, i32 %12)    ; IR: %9: flags' = flags | (pred ? exc : 0)  [final flags rail: an output]
  %14 = call i32 @cq_template_select_f64(i32 %8, i32 %10, i32 %5)    ; IR: %11 = phi [ %9, %8 ], [ %5, %4 ]  [result rail y]
  %15 = call i32 @fetestexcept(i32 63)    ; IR: %12 = fetestexcept(63): the host part
  %16 = call i32 @cq_template_and_i32_hl(i32 %13, i32 63)    ; IR: %12: the quantum part
  %17 = call i32 @cq_template_or_i32_hl(i32 %16, i32 %15)    ; IR: %12 = host | quantum  [result]
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %13, i32 63)    ; IR: uncompute %12's quantum part
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cq_template_select_i32_hl_unc(i32 %12, i32 %8, i32 %11, i32 0)    ; IR: uncompute the gated exception bits (%fl stays)
  call void @cqrt_free(i32 %12)    ; IR: release them (|0>)
  call void @cq_template_fmul_f64_hl_rm_exc_unc(i32 %11, i32 %5, double %2, i32 %6)    ; IR: uncompute %9's exception bits
  call void @cqrt_free(i32 %11)    ; IR: release them (|0>)
  call void @cq_template_fmul_f64_hl_rm_unc(i32 %10, i32 %5, double %2, i32 %6)    ; IR: uncompute %9 (%11 stays)
  call void @cqrt_free(i32 %10)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fcmps_ogt_f64_hl_exc_unc(i32 %9, i32 %5, double %3)    ; IR: uncompute %7's exception bits (%fl stays)
  call void @cqrt_free(i32 %9)    ; IR: release them (|0>)
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %8, i32 %5, double %3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %8)    ; IR: release the %7 rail (|0>)
  %18 = call i32 @cqrt_measure_i32(i32 %17)    ; IR: %13 = cq_measure_si32(%12)
  %19 = call double @cqrt_measure_f64(i32 %14)    ; IR: %14 = cq_measure_f64(%11)
  %20 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %19, metadata !"fpexcept.strict")    ; IR: %15  (classical, host flags)
  %21 = add nsw i32 %20, %18    ; IR: %16 = add nsw i32 %15, %13  (classical)
  ret i32 %21    ; IR: ret i32 %16
}

define i32 @fenv_quantum_mode(i32 noundef %0, double noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register m]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call i32 @fegetround()    ; IR: the classical entry mode, read once from the host
  %7 = call i32 @cq_template_and_i32_hl(i32 %5, i32 -3073)    ; IR: %6 = fesetround(%5): bits outside {0, 1024, 2048, 3072}
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)    ; IR: %6: the argument is a valid mode
  %9 = call i32 @cq_template_select_i32_hl(i32 %8, i32 %5, i32 %6)    ; IR: %6: mode' = valid ? %5 : mode  [the quantum mode; no host call]
  %10 = call i32 @cq_template_select_i32_ll(i32 %8, i32 0, i32 1)    ; IR: %6 = valid ? 0 : 1  [fesetround's return value, quantum]
  %11 = call i32 @cq_template_fadd_f64_ll_rmq(double %2, double %3, i32 %9)    ; IR: %7 = constrained.fadd(%2, %3, round.dynamic, strict)  [both operands classical, the mode a handle: s is QUANTUM]
  %12 = call i32 @cq_template_fadd_f64_ll_rmq_exc(double %2, double %3, i32 %9)    ; IR: %7: its exception bits  [the flags rail: final, an output]
  %13 = call i32 @fesetround(i32 0)    ; IR: %8 = fesetround(0)  (host call; the mode is classical 0 again, the handle %mq is no longer state)
  call void @cq_template_select_i32_hl_unc(i32 %9, i32 %8, i32 %5, i32 %6)    ; IR: uncompute the old mode handle
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %7, i32 0)    ; IR: uncompute the validity flag
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %5, i32 -3073)    ; IR: uncompute the stray bits
  call void @cqrt_free(i32 %7)    ; IR: release them (|0>)
  %14 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %9 = cq_measure_si32(%6)
  %15 = call double @cqrt_measure_f64(i32 %11)    ; IR: %10 = cq_measure_f64(%7)
  %16 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %15, metadata !"fpexcept.strict")    ; IR: %11  (classical, host flags)
  %17 = add nsw i32 %16, %14    ; IR: %12 = add nsw i32 %11, %9  (classical)
  ret i32 %17    ; IR: ret i32 %12
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare double @cqrt_measure_f64(i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @fegetround()
declare i32 @fesetround(i32)
declare i32 @fesetenv(ptr)
declare i32 @feupdateenv(ptr)
declare i32 @fetestexcept(i32)
declare i32 @feclearexcept(i32)
declare i32 @fegetexceptflag(ptr, i32)
declare i32 @fesetexceptflag(ptr, i32)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata)
declare i32 @cq_template_fmul_f64_hl_rm(i32, double, i32)
declare void @cq_template_fmul_f64_hl_rm_unc(i32, i32, double, i32)
declare i32 @cq_template_fmul_f64_hl_rm_exc(i32, double, i32)
declare void @cq_template_fmul_f64_hl_rm_exc_unc(i32, i32, double, i32)
declare i32 @cq_template_fadd_f64_hl_rm(i32, double, i32)
declare i32 @cq_template_fadd_f64_hl_rm_exc(i32, double, i32)
declare i32 @cq_template_fdiv_f64_hl_rm(i32, double, i32)
declare void @cq_template_fdiv_f64_hl_rm_unc(i32, i32, double, i32)
declare i32 @cq_template_fdiv_f64_hl_rm_exc(i32, double, i32)
declare void @cq_template_fdiv_f64_hl_rm_exc_unc(i32, i32, double, i32)
declare i32 @cq_template_fadd_f64_ll_rmq(double, double, i32)
declare i32 @cq_template_fadd_f64_ll_rmq_exc(double, double, i32)
declare i32 @cq_template_fcmp_ogt_f64_hl(i32, double)
declare void @cq_template_fcmp_ogt_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fcmps_ogt_f64_hl_exc(i32, double)
declare void @cq_template_fcmps_ogt_f64_hl_exc_unc(i32, i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_or_i32_hl(i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_hl(i32, i32, i32)
declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare i32 @cq_template_select_f64(i32, i32, i32)

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}
!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
