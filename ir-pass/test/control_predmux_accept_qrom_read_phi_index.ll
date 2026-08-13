; control_predmux_accept_qrom_read_phi_index.ll — ACCEPT (3c6m.14 L6 Inc 3):
; the atan `atanhi[id]` mechanism — a const-table read whose index is a
; region-internal PHI OVER CONSTANTS (control-dependent but data-CLASSICAL:
; taint reaches the phi through no data edge, so the strict tainted-index gate
; would call the read off-shape). The claim's `Region` widening accepts it:
; the flatten's phi→select conversion rewires the index onto the (tainted)
; edge predicates, so post-flatten the read IS a tainted-index QROM read; the
; index value set {2, 2^32−1} is known-bits-unprovable but the pow2 table
; admits the `and idx, 3` mask (identity on-guard; the OOB constant rides an
; excluded path whose garbage row the merge predicate discards). This shape
; was the last atan.f64 census blocker (red pre-Inc-3 via the census probe:
; `nested control flow under quantum control` at s_atan.c:81).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
@tbl = internal unnamed_addr constant [4 x double] [double 1.0, double 2.0, double 3.0, double 4.0]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c1 = fcmp ogt double %q, 1.000000e+00
  br i1 %c1, label %inner, label %merge
inner:
  %c2 = fcmp olt double %q, 4.000000e+00
  br i1 %c2, label %ia, label %ib
ia:
  br label %join
ib:
  br label %join
join:
  %id = phi i64 [ 2, %ia ], [ 4294967295, %ib ]   ; classical constants only
  %g = getelementptr inbounds [4 x double], ptr @tbl, i64 0, i64 %id
  %v = load double, ptr %g, align 8
  %s = fadd double %q, %v
  br label %merge
merge:
  %r = phi double [ %s, %join ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; the id select-chain (tainted via the edge predicate) feeds the mask, then
; the table read, then the kjd1 fp merges:
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 4)
; CHECK:     %[[MSK:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %{{[a-zA-Z0-9_.]+}}, i64 3)
; CHECK:     call i32 @cqrt_qram_load_f64(i32 %[[T]], i32 %[[MSK]])
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call double @cqrt_measure_f64(
; CHECK-NOT: br i1
; CHECK-NOT: phi double
; CHECK-NOT: select i1
