; spec_accept_phantom_arg_read_unc_twin_nofpclass_stripped.ll — ACCEPT, and a CLASSICAL fp dead slot's `nofpclass(zero)` STRIPPED
; FROM THE `_unc` TWIN (bd test_C_libtooling-vaep; r1A F-r1A-1, probe `p7_fp_classical_slot_nn.ll`,
; verbatim; IR-only).
;
; A classical `double noundef nofpclass(zero)` slot beside a quantum one; `h2` never reads it
; and its parameter carries a string attribute. The record calls `h`'s fp parameter dead, so
; `main` passes `double 0.0` — which reaches `h2`'s twin through the reverse call. On round 1 the
; twin kept `nofpclass(zero)` (the ORACLE passed the real `%md` there, so round 1 INTRODUCED
; this customer of the vaep class). The TWIN lines pin the forward clone's and the twin's
; signatures without `nofpclass`. RED on round 1 (measured).
;
; Twin (trace-compared, tools/pairs.py): r1A `p7T` (TRACE-EQUIV, tools/trace_twin_equiv.py).
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=TWIN < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of each function (derived from the lowered module; SSA
; names wildcarded, constants — every dropped `0` and every angle — kept). Between
; consecutive matches NO other runtime/clone call may appear, so the stream is pinned
; EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @atoi(ptr noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @__cq_q_h_001(i32 noundef %{{[a-zA-Z0-9_.]+}}, double noundef 0.000000e+00, i32 noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 0x3FE6666666666666)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret 
; TWIN-LABEL: define internal i32 @__cq_q_h_001(
; TWIN: call void @__cq_q_h2_001_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %a, double %c, i32 %k)
; TWIN-LABEL: define internal i32 @__cq_q_h2_001(i32 noundef %x, double noundef "cq.probe.opaque" %y, i32 noundef %k)
; TWIN-LABEL: define internal void @__cq_q_h2_001_unc(i32 %out, i32 noundef %x, double noundef "cq.probe.opaque" %y, i32 noundef %k)
; NODROP-NOT: CQ_DEADARG_DBG

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define i32 @main(i32 noundef %argc, ptr noundef %argv) {
e:
  %a1p = getelementptr inbounds ptr, ptr %argv, i64 1
  %a1 = load ptr, ptr %a1p
  %m = call i32 @atoi(ptr noundef %a1)
  %m7 = and i32 %m, 7
  %md = sitofp i32 %m to double
  %q = call i32 @cq_theta_si32(i32 noundef %m7, double noundef 5.000000e-01)
  %r = call i32 @h(i32 noundef %q, double noundef nofpclass(zero) %md, i32 noundef %m)
  %q2 = call i32 @cq_theta_si32(i32 noundef %q, double noundef 0x3FE6666666666666)
  %z = call i32 @cq_measure_si32(i32 noundef %q2)
  %zr = call i32 @cq_measure_si32(i32 noundef %r)
  %s = add nsw i32 %z, %zr
  ret i32 %s
}
define i32 @h(i32 noundef %a, double noundef nofpclass(zero) %c, i32 noundef %k) {
e:
  %r = tail call i32 @h2(i32 noundef %a, double noundef nofpclass(zero) %c, i32 noundef %k)
  ret i32 %r
}
define i32 @h2(i32 noundef %x, double noundef nofpclass(zero) "cq.probe.opaque" %y, i32 noundef %k) noinline {
e:
  %r = add nsw i32 %x, %k
  ret i32 %r
}
