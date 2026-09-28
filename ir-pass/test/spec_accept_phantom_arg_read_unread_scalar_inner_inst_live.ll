; spec_accept_phantom_arg_read_unread_scalar_inner_inst_live.ll — ACCEPT — the PRECISION control of bd test_C_libtooling-nlfd's fence
; (hand-written IR).
;
; As `spec_reject_phantom_arg_read_unread_scalar_inner_inst.ll`, except that `h` ALSO returns
; `t` (`return h2(t, k) + t;`): the instruction in the not-null-safe dead slot is read by a
; live root, so its VALUE is observed, `h`'s parameter is live under `SlotReads::Value` too,
; and the fence must NOT fire. The CLONE stream is pinned (the ORACLE's, byte-for-byte,
; measured); `main`'s is DELIBERATELY NOT: it is not the hand-inlined twin's — the clone call
; sits between `p = q * 3` and its phase consumer, which is bd rhk5 (P1, warned, PRE-EXISTING:
; one lyyf-(B) warning, `p`'s rail left dirty across the Ry, on the ORACLE and here alike) — and
; a golden of a known-wrong stream would bless it (bd jlf8's lesson). `main` is pinned only to
; keep the clone call's operand (the slot is live). Fence without its value-liveness test →
; this file declines (mutant N4).
;
; Twin (trace-compared, tools/pairs.py): `r = m + 1 + 5p` (cells/x_inst_liveT.ll) — TRACE-DIFF on the ORACLE too (bd rhk5's shape: the clone call sits between `p` and its phase consumer).
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of each function (derived from the lowered module; SSA
; names wildcarded, constants — every dropped `0` and every angle — kept). Between
; consecutive matches NO other runtime/clone call may appear, so the stream is pinned
; EXACTLY, not as a subsequence.
; CLONE-LABEL: define {{.*}}@__cq_q_h_01(
; CLONE-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CLONE: call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CLONE-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CLONE: call i32 @__cq_q_h2_01(i32 noundef %{{[a-zA-Z0-9_.]+}}, i32 noundef %{{[a-zA-Z0-9_.]+}})
; CLONE-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CLONE: call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CLONE-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CLONE: call i32 @cqrt_alloc_i32(i32 0)
; CLONE-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CLONE: call void @cqrt_copy_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CLONE-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CLONE: call void @cq_template_add_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CLONE-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CLONE: call void @cq_template_mul_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CLONE-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CLONE: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CLONE-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CLONE: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CLONE-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CLONE: ret 
; CHECK-LABEL: define {{.*}}@main(
; CHECK: call i32 @__cq_q_h_01(i32 noundef %{{[a-zA-Z0-9_.]+}}, i32 noundef %{{[a-zA-Z0-9_.]+}})
; NODROP-NOT: CQ_DEADARG_DBG
; (stderr also carries 1 warning line(s) — the ORACLE's, see the header.)

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
  %r = tail call i32 @h2(i32 noundef %t, i32 noundef %k)
  %s = add nsw i32 %r, %t
  ret i32 %s
}

define i32 @h2(i32 noundef "cq.probe.opaque" %x, i32 noundef %k) noinline {
e:
  %c = icmp sgt i32 %x, 3
  br i1 %c, label %t, label %f
t:
  br label %f
f:
  %r = add nsw i32 %k, 1
  ret i32 %r
}
