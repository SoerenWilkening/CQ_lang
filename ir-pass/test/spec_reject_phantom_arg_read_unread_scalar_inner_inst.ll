; spec_reject_phantom_arg_read_unread_scalar_inner_inst.ll — DECLINE (bd test_C_libtooling-nlfd — the rule of
; `resolvePhantomCloneArgReads` step 1, one clone level down; hand-written IR).
;
; k19 main; `h(a,k){ t = a * 5; return h2(t, k); }`; `h2`'s parameter 0 carries a string
; attribute (NOT null-safe) and is read only in an empty diamond (dead only after the CLONE's
; flatten). The inner slot's operand is an INSTRUCTION: it cannot be deleted while the call
; uses it, and the rewrite may not null the slot, so `%t` survives and keeps `h`'s HANDLE
; parameter live — while nothing observes `%t`'s value (`SlotReads::Value` calls the
; parameter dead). On `main` 9a230646, for THIS caller operand (a DERIVED `p = q * 3`), both
; accepts were wrong: keeping `main`'s slot was bd tzfa's phantom read (exit 0, a warning, `p`'s
; rail dirty across the Ry — TRACE-DIFF vs the twin), and neutralising it would lower
; `t = a * 5` on runtime handle 0 (bd sqjq); for a `cq_theta` SOURCE operand the keep-the-slot
; accept already was the twin's unitary (Rule-13 r1A F-r1A-2, bd test_C_libtooling-w109).
; ⚠ SINCE bd rhk5 (9ad22639) THE KEEP-THE-SLOT ACCEPT IS CORRECT HERE TOO (bd
; test_C_libtooling-ur72, measured on `main` ba4fdad4): the spine discharges `p` although the
; clone call reads it, and the stream is the twin's plus an identity compute/uncompute pair on a
; scratch rail (2b STRICT, 0 dirty). So this file now pins an IR-only OVER-DECLINE of a program
; `main` compiles correctly, kept pending the owner's decision on bd ur72. The hand-inlined twin
; (`r = m + 1`) ACCEPTS: a knowing over-decline
; of an IR-only shape (clang-19 -O1 emits only allowlisted attributes on an int/fp parameter
; that CAN BE RECORDED DEAD — it infers `returned` on a returned, hence live, one; r1A
; F-r1A-3). Retirement trigger: the day `nullSafeSlot` admits string/unknown attributes (owner
; question bd test_C_libtooling-uyhx), this module accepts.
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
  %r = tail call i32 @h2(i32 noundef %t, i32 noundef %k)
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
