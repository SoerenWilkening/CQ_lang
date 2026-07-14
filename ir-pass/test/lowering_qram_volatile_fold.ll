; lowering_qram_volatile_fold.ll — ACCEPT (3c6m.14 L6 Inc 3): the volatile-
; const global-load fold, BOTH openlibm forms. (a) the direct-global form
; (`static volatile double twom1000` in e_exp.c — clang keeps the global
; non-constant and every load volatile, so GlobalOpt/-O1 can NEVER fold it);
; (b) the volatile-CAST form (`*(volatile double *)&atanlo[3]` in s_atan.c —
; a volatile load through a constexpr byte-offset gep into a `constant`
; array). Both are internal, constant-initialized, and never stored (all
; transitive users are loads), so the loaded value IS the initializer on
; every execution; the volatile qualifier exists only to defeat classical FP
; const-folding (fenv is out of scope project-wide). The curation folds each
; load to its initializer constant BEFORE the PredMux fixpoint — unfolded,
; either load would block the tainted arm (E4 admits no volatile access) and
; the region would decline `control flow under quantum control`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
@twom1000 = internal global double 0x0170000000000000, align 8
@atanlo = internal constant [4 x double] [double 0x3C7A2B7F222F65E2, double 0x3C81A62633145C07, double 0x3C7007887AF0CBBD, double 0x3C91A62633145C07], align 16
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %t = load volatile double, ptr @twom1000, align 8
  %a = load volatile double, ptr getelementptr inbounds (i8, ptr @atanlo, i64 24), align 8
  %u = fmul double %q, %t
  %c2 = fcmp ogt double %q, -1.000000e+00
  br i1 %c2, label %arm2, label %join
arm2:
  %v2 = fadd double %u, %a
  br label %join
join:
  %hi = phi double [ %v2, %arm2 ], [ %u, %arm ]
  br label %merge
merge:
  %r = phi double [ %hi, %join ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; the folded constants ride as classical fp literals in the mixed templates
; (never a qram call, never a load); the nested region then flattens (W1) and
; the kjd1 fp select merges lower it:
; CHECK-DAG: call i32 @cq_template_fmul_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 0x170000000000000)
; CHECK-DAG: call i32 @cq_template_fadd_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 0x3C91A62633145C07)
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call double @cqrt_measure_f64(
; CHECK-NOT: load volatile
; CHECK-NOT: cqrt_qram
; CHECK-NOT: br i1
