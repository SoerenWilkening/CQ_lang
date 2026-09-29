; spec_reject_phantom_arg_read_unread_scalar_inner_inst_musttail.ll — DECLINE (bd test_C_libtooling-nlfd; hand-written IR) — the
; `musttail` × never-read cell of the nlfd/ev3m table.
;
; k19 main; `h(a,k){ t = a * 5; musttail return h2(t, k); }`; `h2` never reads parameter 0,
; which carries a string attribute (NOT null-safe), so the pre-specialize drop leaves the slot
; alone and `h2`'s clone records it dead. The inner slot's operand is a surviving quantum
; INSTRUCTION that keeps `h`'s handle parameter alive for nothing — the same fence as
; `…_inner_inst.ll`. On the ORACLE this module ABORTED (exit 134: the `musttail` call inside
; `h`'s clone was no longer followed by `ret` once `t`'s template was Bennett-reversed after
; it). The fence speaks inside `buildClone` right after the record — before the Bennett wrap
; emits anything — so this file declines with or without the same track's clone-`musttail`
; demotion (commit C). ⚠ Like `…_inner_inst.ll`, an IR-only over-decline since bd rhk5 (bd
; test_C_libtooling-ur72).
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error: {{.*}}in function __cq_q_h_01{{.*}}cq specialization: quantum argument to a parameter the lifted callee never reads

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
  %q = call i32 @cq_theta_si32(i32 noundef %m7, double noundef 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %r = call i32 @h(i32 noundef %p, i32 noundef %m)
  %u = xor i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %ph, label %j
ph:
  call void @cq_phi(double noundef 3.141590e+00)
  br label %j
j:
  %q2 = call i32 @cq_theta_si32(i32 noundef %q, double noundef 0x3FE6666666666666)
  %z = call i32 @cq_measure_si32(i32 noundef %q2)
  %zr = call i32 @cq_measure_si32(i32 noundef %r)
  %s = add nsw i32 %z, %zr
  ret i32 %s
}

define i32 @h(i32 noundef %a, i32 noundef %k) {
e:
  %t = mul nsw i32 %a, 5
  %r = musttail call i32 @h2(i32 noundef %t, i32 noundef %k)
  ret i32 %r
}

define i32 @h2(i32 noundef "cq.probe.opaque" %x, i32 noundef %k) noinline {
e:
  %r = add nsw i32 %k, 1
  ret i32 %r
}
