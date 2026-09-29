; spec_reject_phantom_arg_read_unread_scalar_outer_nn.ll — DECLINE at MODULE level (bd test_C_libtooling-nlfd's L2 consequence;
; hand-written IR).
;
; `sa1`'s shape with the OUTER slot not null-safe too: `h(a "opaque", k){ return h2(a, k); }`,
; `h2(x "opaque", k)` reading `x` only in an empty diamond. Since bd nlfd the record calls
; `h`'s parameter dead (an ARGUMENT in an unread scalar slot is not a read), so
; `resolvePhantomCloneArgReads` step 1 now SEES `main`'s slot: recorded dead, not null-safe,
; quantum operand — its existing decline. On `main` 9a230646 the record called the parameter
; live and the module ACCEPTED with bd tzfa's phantom read (TRACE-DIFF vs the twin `r = m + 1`,
; `p` dirty across the Ry, warned). ⚠ On `main` ba4fdad4 (bd rhk5) that same accept is
; TRACE-IDENT with the twin (one lyyf-(B) over-warn): this decline is now an IR-only
; OVER-DECLINE of a program `main` compiles correctly, introduced by nlfd in composition with
; rhk5 (bd test_C_libtooling-ur72). Retirement triggers: bd ur72, or `nullSafeSlot` admitting
; string attributes (owner question bd test_C_libtooling-uyhx).
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error: {{.*}}in function main{{.*}}cq specialization: quantum argument to a parameter the lifted callee never reads

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

define i32 @h(i32 noundef "cq.probe.opaque" %a, i32 noundef %k) {
e:
  %r = tail call i32 @h2(i32 noundef %a, i32 noundef %k)
  ret i32 %r
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
