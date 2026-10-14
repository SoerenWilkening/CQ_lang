; spec_accept_phantom_arg_read_exact_record_a2_chain.ll — ACCEPT, and the CLONE reads nothing the caller did not pass (bd
; test_C_libtooling-sqjq; bd vsfp Rule-13 r3A F-XA-2, probe `a2_chain`; hand-written IR).
;
; The callee's read of the dead slot is `t = a*3; if (t > 3) {}` — the flatten deletes the compare, not its chain. `buildClone` records the slot dead (no live root
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
; CHECK: call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %{{[a-zA-Z0-9_.]+}})
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
; CLONE: ret 

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %z = tail call i32 @cq_theta_si32(i32 noundef 2, double noundef 3.000000e-01)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01)
  %9 = tail call i32 @h(i32 noundef %7, i32 noundef %5)
  %14 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 0x3FE6666666666666)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14)
  %zm = tail call i32 @cq_measure_si32(i32 noundef %z)
  %16 = add nsw i32 %15, %9
  %17 = add nsw i32 %16, %zm
  %cq.main.m = call i32 @cq_measure_si32(i32 %17)
  ret i32 %cq.main.m
}

declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @h(i32 noundef %0, i32 noundef %1) {
  %d = mul nsw i32 %0, 3
  %3 = icmp sgt i32 %d, 3
  br i1 %3, label %4, label %6

4:
  br label %6

6:
  %7 = add nsw i32 %1, 1
  ret i32 %7
}
