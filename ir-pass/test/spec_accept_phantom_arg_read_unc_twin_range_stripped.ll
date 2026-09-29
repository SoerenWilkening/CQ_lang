; spec_accept_phantom_arg_read_unc_twin_range_stripped.ll — ACCEPT, and the dead slot's `range` STRIPPED FROM THE `_unc` TWIN
; (bd test_C_libtooling-vaep; Rule-13 r1A F-r1A-1, probe `p1_twin_range_nn.ll`, verbatim; IR-only).
;
; `h(a,k){ return h2(a,k); }`; `h2(x noundef range(i32 1,100) "cq.probe.opaque", k)` never reads
; `x` and returns the QUANTUM `k + 1`, so `h2`'s clone has an `_unc` twin. The record calls `h`'s
; parameter dead (bd nlfd) and `main`'s slot is `0`, which reaches `h2`'s slot through the
; parameter — on the FORWARD call and on the Bennett wrap's REVERSE call to `h2`'s twin. Round 1
; stripped `range` from the forward clone's parameter and the forward call site only: the twin is
; built (`ensureTwin`, the enclosing clone's inner-call loop) BEFORE the enclosing clone's
; strip, and inherited `noundef range(i32 1, 100)` — so the neutralised `0` landed in a
; parameter that excludes it (LLVM-level UB; latent, measured by r1A: traces correct, `opt -O2`
; does not exploit it). Since round 2 `buildClone` strips `range`/`nofpclass` from every
; recorded-dead parameter AT ITS OWN RECORD, before any twin of it exists; the TWIN lines pin
; the forward clone's and the twin's signatures character-for-character (no `range`). RED on
; `main` 9a230646 and on round 1 (measured). Remove the record-time strip and it goes red
; (mutant V1).
;
; Twin (trace-compared, tools/pairs.py): the null-safe spelling r1A `p1_twin_range_ns` on `main` 9a230646 (byte-identical trace, r1A); vs the hand-inlined r1A `p1T` the only difference is the out-of-place `add_hl` + copy-out where the twin adds in place (`cqrt_addc_i32`), which tools/trace_twin_equiv.py does not contract.
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
; CHECK: call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 3.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @__cq_q_h_11(i32 noundef 0, i32 noundef %{{[a-zA-Z0-9_.]+}})
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
; CHECK: ret 
; TWIN-LABEL: define internal i32 @__cq_q_h_11(
; TWIN: call void @__cq_q_h2_11_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %a, i32 %k)
; TWIN-LABEL: define internal i32 @__cq_q_h2_11(i32 noundef "cq.probe.opaque" %x, i32 noundef %k)
; TWIN-LABEL: define internal void @__cq_q_h2_11_unc(i32 %out, i32 noundef "cq.probe.opaque" %x, i32 noundef %k)
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
  %m3 = and i32 %m, 3
  %q = call i32 @cq_theta_si32(i32 noundef %m7, double noundef 5.000000e-01)
  %kq = call i32 @cq_theta_si32(i32 noundef %m3, double noundef 3.000000e-01)
  %p = mul nsw i32 %q, 3
  %r = call i32 @h(i32 noundef %p, i32 noundef %kq)
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
  %r = tail call i32 @h2(i32 noundef %a, i32 noundef %k)
  ret i32 %r
}
define i32 @h2(i32 noundef range(i32 1, 100) "cq.probe.opaque" %x, i32 noundef %k) noinline {
e:
  %c = icmp sgt i32 %x, 3
  br i1 %c, label %t, label %f
t:
  br label %f
f:
  %r = add nsw i32 %k, 1
  ret i32 %r
}
