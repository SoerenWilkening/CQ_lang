; lowering_reject_qram_store_measured_index_load_idx_measured.ll — DECLINE (bd
; test_C_libtooling-01po.4's second refusal twin). The array-frontier retry of
; lowering_qram_store_measured_index_nonmain.ll borrows only QRAM ARRAYS; when
; the LOAD's own index is measured too,
;     arr[b] = 0;  v = arr[p];  cq_theta(&b, -.5);
;     return cq_measure(b) + cq_measure(v) + cq_measure(p);
; the reduced DAG (the load and the `p` wire) is still measured upstream, so the
; retry is refused and the module keeps today's decline, verbatim.
;
; Not a physics wall: borrowing `p` as well (never adjointed, never freed;
; unchanged between the load and the reversal) would lower it. That is the
; general measured-upstream frontier, filed with this repro rather than taken
; here. RETIREMENT TRIGGER (L7): when it lands, this becomes an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @idx_measured(i1 %u0, i1 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %zb = zext i1 %b to i64
  %gb = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zb
  store i32 0, ptr %gb, align 4
  %p = call i1 @cq_theta_i1(i1 %u1, double 5.000000e-01)
  %zp = zext i1 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zp
  %v = load i32, ptr %gp, align 4
  %b2 = call i1 @cq_theta_i1(i1 %b, double -5.000000e-01)
  %mb = call i1 @cq_measure_i1(i1 %b2)
  %mv = call i32 @cq_measure_si32(i32 %v)
  %mp = call i1 @cq_measure_i1(i1 %p)
  %zmb = zext i1 %mb to i32
  %zmp = zext i1 %mp to i32
  %r1 = add i32 %mv, %zmb
  %r = add i32 %r1, %zmp
  ret i32 %r
}

; CHECK: error: {{.*}}in function idx_measured{{.*}}cq uncompute: dead chain would free a measured register
