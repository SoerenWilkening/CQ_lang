; lowering_volatile_local_fold.ll — ACCEPT (bd etiq): the volatile-const
; LOCAL fold, the alloca sibling of foldVolatileConstGlobalLoads. The openlibm
; rounding idiom (`volatile double vd2 = 0x1.0p32; volatile double vd1 =
; 0x1.0p-31;` in s_cbrtl.c) keeps a volatile store + volatile load on a
; classical entry-block alloca at -O1 (mem2reg never touches volatile), and
; PredMux E4 admits no volatile access — unfolded, the accesses block the
; tainted region and the cell declines `control flow under quantum control`.
; The proof (single non-atomic store of a Constant with the alloca as pointer
; operand, every other user a non-atomic same-type load the store dominates,
; lifetime markers only, nothing else — so the address never escapes and no
; other writer exists) makes load == stored-constant on every execution; the
; fold RAUWs each load to the constant and erases the loads, the store, the
; lifetime markers, and the alloca. The volatile qualifier exists purely to
; defeat classical FP const-folding (fenv is out of scope project-wide) —
; folding it is the same deliberate semantic choice the global fold
; documents. Two locals mirror cbrtl's vd2/vd1 pair (lifetime.start + store
; volatile + load volatile + lifetime.end inside the tainted region; allocas
; in entry); the region skeleton is the claimable nested-W1 shape of
; lowering_qram_volatile_fold.ll, so the ONLY blocker is the volatile pair.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

define double @probe(double %u0) {
entry:
  %vd2 = alloca double, align 8
  %vd1 = alloca double, align 8
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %vd2)
  store volatile double 0x41F0000000000000, ptr %vd2, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %vd1)
  store volatile double 0x3E00000000000000, ptr %vd1, align 8
  %t2 = load volatile double, ptr %vd2, align 8
  %t1 = load volatile double, ptr %vd1, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %vd1)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %vd2)
  %u = fmul double %q, %t2
  %c2 = fcmp ogt double %q, -1.000000e+00
  br i1 %c2, label %arm2, label %join
arm2:
  %v2 = fadd double %u, %t1
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
; (never a load; the store/alloca/lifetime markers are erased with them); the
; region then flattens and the kjd1 fp select merges lower it:
; CHECK-DAG: call i32 @cq_template_fmul_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 0x41F0000000000000)
; CHECK-DAG: call i32 @cq_template_fadd_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 0x3E00000000000000)
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call double @cqrt_measure_f64(
; CHECK-NOT: load volatile
; CHECK-NOT: store volatile
; CHECK-NOT: alloca
; CHECK-NOT: llvm.lifetime
; CHECK-NOT: br i1
