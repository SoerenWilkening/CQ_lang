; lowering_reject_fp80_union_pack_unmasked.ll — DECLINE (bd 3c6m.55 Inc 1,
; Lever A.1d — the P2 probe): a reconstruct pack whose RMW pre-load keeps
; UNDEFINED significant bits. The offset-8 pre-load reads bits [64,80) — the
; expsign field — before ANY store defines them; the mask here is `and -256`,
; which keeps bits [8,16) of that undefined field (real execution reads stack
; garbage there; the promoted model would read mem2reg's reaching value).
; packDefinednessOk P2 (every user of an uncovered-bit word load must be an
; `and` whose constant mask zeroes ALL uncovered significant bits) fails, the
; alloca is NOT a candidate, and the tainted word stores fall to the existing
; loud kMsgStore taint-escape decline. Mirrors the sound positive
; lowering_fp80_union_reconstruct_pack.ll (`and -65536` — every uncovered
; significant bit dies in the mask).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare i64 @cq_theta_sll(i64, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @packcell_unmasked(i64 %w0) {
entry:
  %q = call i64 @cq_theta_sll(i64 %w0, double 5.000000e-01)
  %manl64 = and i64 %q, 4294967295
  %manl = trunc i64 %manl64 to i32
  %hi = lshr i64 %q, 32
  %manh = trunc i64 %hi to i32
  %u = alloca %union.IEEEl2bits, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %old = load i64, ptr %p8, align 8
  %keep = and i64 %old, -256
  %es = and i64 %q, 255
  %w = or disjoint i64 %keep, %es
  store i64 %w, ptr %p8, align 8
  %p4 = getelementptr inbounds i8, ptr %u, i64 4
  store i32 %manh, ptr %p4, align 4
  store i32 %manl, ptr %u, align 16
  %e = load x86_fp80, ptr %u, align 16
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %e)
  ret x86_fp80 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
; CHECK-NOT: cq_template_bitcast_i80_to_f80
