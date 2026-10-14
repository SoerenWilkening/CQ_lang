; spec_accept_phantom_arg_read_exact_record_n5_nested.ll — ACCEPT, and the CLONE reads nothing the caller did not pass (bd
; test_C_libtooling-sqjq; bd vsfp Rule-13 r3A F-XA-2, probe `n5_nested`; hand-written IR).
;
; The callee's read of the dead slot is the slot forwarded as `a + 1` into an INNER clone's dead slot. `buildClone` records the slot dead (no live root
; reads it) but round 3 left the dead instruction standing, so the clone's `lowerOps` lowered
; it: once the caller's slot was neutralised to `0`, the clone operated on runtime handle h0 —
; a register the caller never passed. Round 4 deletes the dead cone of every recorded-dead
; parameter right after taking the record (an inner clone call inherits the dead slot as a
; constant — `rewriteRecordedDeadSlotUse`, the one spelling of that rewrite). The CLONE prefix
; pins that `@__cq_q_h_*` contains no template call at all (and, for the nested probes, that the
; inner clone call passes `0` in the inherited dead slot); the main CHECKs pin the caller's
; stream (TRACE-IDENT with the hand-inlined twin, measured).
;
;
; bd p3kd.21 R11 r2 F1 (bd r2j3.35, 2026-10-15): `main` now MEASURES the value it
; returns. A register returned from `main` reaches the process exit status without
; `cq_measure`, which NORTHSTAR goal 1 forbids and the pass now refuses
; (spec_reject_gate_sub_main_return.ll); the measurement is outside this fixture's
; subject, which is unchanged.
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of @main (derived from the lowered module; SSA names
; wildcarded, constants — every dropped `0` and every angle — kept):
; Between consecutive matches NO other runtime/clone call may appear, so the
; runtime stream is pinned EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @atoi(ptr nocapture noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 3.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_xor_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 10)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_rz_i1(i32 %{{[a-zA-Z0-9_.]+}}, double 3.141590e+00), !cq.branchphase !0
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 10)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cq_template_xor_i32_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cq_template_mul_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 0x3FE6666666666666)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
; NODROP-NOT: CQ_DEADARG_DBG
;
; The clone body reads nothing the caller did not pass: no template call (bd sqjq):
; CLONE-LABEL: define {{.*}}@__cq_q_h_
; CLONE-NOT: cq_template_
; CLONE: call i32 @__cq_q_g_{{[0-9]+}}(i32 noundef 0,
; CLONE-NOT: cq_template_
; CLONE: ret 

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %z = tail call i32 @cq_theta_si32(i32 noundef 2, double noundef 3.000000e-01)
  %q = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %r = tail call i32 @h(i32 noundef %p, i32 noundef %5)
  %u = xor i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %arm, label %join
arm:
  tail call void @cq_phi(double noundef 3.141590e+00)
  br label %join
join:
  %q2 = tail call i32 @cq_theta_si32(i32 noundef %q, double noundef 0x3FE6666666666666)
  %mq = tail call i32 @cq_measure_si32(i32 noundef %q2)
  %mz = tail call i32 @cq_measure_si32(i32 noundef %z)
  %s1 = add nsw i32 %mq, %r
  %s2 = add nsw i32 %s1, %mz
  %cq.main.m = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %cq.main.m
}

declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare void @cq_phi(double noundef)

define i32 @h(i32 noundef %a, i32 noundef %k) {
  %t = add nsw i32 %a, 1
  %r = tail call i32 @g(i32 noundef %t, i32 noundef %k)
  ret i32 %r
}

define i32 @g(i32 noundef %a, i32 noundef %k) {
  %c = icmp sgt i32 %a, 3
  br i1 %c, label %e, label %m
e:
  br label %m
m:
  %r = add nsw i32 %k, 1
  ret i32 %r
}
