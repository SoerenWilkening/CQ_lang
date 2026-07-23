; spec_accept_qrom_read_arm_two_tables.ll — bd 20xt.5.2, the LITERAL inner-atanl
; production shape: TWO const-global tables (`atanhi[id]` / `atanlo[id]`) read with
; ONE SHARED tainted phi-index in a tainted diamond arm of a Phase-6 spec-clone,
; both loaded values reaching the clone's non-`main` ret with NO measure.
;
; This is the Rule-8 FAN-OUT / shared-prefix hazard the whole-DAG reverse must get
; right: the shared index fans out to two GEP/load pairs, so a naive reverse could
; double-uncompute the shared prefix (use-after-free + double-free). The correct
; lowering (verified here): the flattened phi-index is ONE `cqrt_copy_i64_controlled`
; select-chain rail (`%[[SEL]]`); EACH read masks it into its OWN masked-index rail
; (`and %[[SEL]], 3` twice — the base is read-only to both, never moved); EACH read is
; reverse-played EXACTLY ONCE (two `cqrt_qram_load_f64_unc`) in LIFO order with its own
; mask `_unc`; the shared `%[[SEL]]` is reversed once and freed once; and NEITHER array
; handle is ever `cqrt_free`d. The coherent escape rides the same `inBennettClone`
; bypass as the single-read case.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

@hi = internal unnamed_addr constant [4 x double] [double 1.0, double 2.0, double 3.0, double 4.0], align 16
@lo = internal unnamed_addr constant [4 x double] [double 0.1, double 0.2, double 0.3, double 0.4], align 16
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define internal double @reduce2(double %x) {
entry:
  %c1 = fcmp ogt double %x, 1.000000e+00
  br i1 %c1, label %inner, label %base
inner:
  %c2 = fcmp olt double %x, 4.000000e+00
  br i1 %c2, label %ia, label %ib
ia:
  br label %join
ib:
  br label %join
join:
  %id = phi i64 [ 2, %ia ], [ 4294967295, %ib ]     ; SHARED index (fan-out to 2 reads)
  %ghi = getelementptr inbounds [4 x double], ptr @hi, i64 0, i64 %id
  %vhi = load double, ptr %ghi, align 8
  %glo = getelementptr inbounds [4 x double], ptr @lo, i64 0, i64 %id
  %vlo = load double, ptr %glo, align 8
  %sum = fadd double %vhi, %vlo
  %s = fadd double %x, %sum
  br label %exit
base:
  br label %exit
exit:
  %r = phi double [ %s, %join ], [ %x, %base ]
  ret double %r                                       ; coherent escape — no measure
}

define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @reduce2(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; Clone: two array handles, ONE shared index rail feeding TWO masks + reads, then the
; reverse un-reads BOTH exactly once. (CHECK-NOTs interleaved so they scan the clone
; body, not the dead un-lowered `@reduce2` above it or the trailing declares.)
; CHECK-LABEL: define internal {{.*}}i32 @__cq_q_reduce2_1(i32 %x)
; CHECK:     %[[ARRLO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 4)
; CHECK:     %[[ARRHI:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 4)
; the shared index rail masked into read 0's own index, then read 0:
; CHECK:     %[[M0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[SEL:[a-zA-Z0-9_.]+]], i64 3)
; CHECK:     %[[V0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARRHI]], i32 %[[M0]])
; the SAME shared index rail masked into read 1's own index (fan-out), then read 1:
; CHECK:     %[[M1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[SEL]], i64 3)
; CHECK:     %[[V1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARRLO]], i32 %[[M1]])
; no raw load / control survives between the reads and the fp arm-merge:
; CHECK-NOT: load double
; CHECK-NOT: br i1
; CHECK-NOT: = phi
; CHECK-NOT: = select i1
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; BOTH reads reverse-played exactly once (LIFO), each with its own masked index:
; CHECK:     call void @cqrt_qram_load_f64_unc(i32 %[[V1]], i32 %[[ARRLO]], i32 %[[M1]])
; CHECK:     call void @cqrt_qram_load_f64_unc(i32 %[[V0]], i32 %[[ARRHI]], i32 %[[M0]])
; neither array handle, nor the shared index, nor the result rail is freed (Rule 6/8),
; and the reverse never mints a fresh `_inv`:
; CHECK-NOT: cqrt_qram_load_f64_inv
; CHECK-NOT: cqrt_free(i32 %[[ARRHI]])
; CHECK-NOT: cqrt_free(i32 %[[ARRLO]])
; CHECK-NOT: cqrt_free(i32 %[[OUT]])
; CHECK:     ret i32 %[[OUT]]
