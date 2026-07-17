; lowering_reject_fp80_union_pack_storeafter.ll — DECLINE (bd 3c6m.55 Inc 1,
; Lever A.1d — the P1 DOMINANCE probe): a reconstruct pack whose manl store
; executes AFTER the fp80 reload. Byte-range coverage alone would call [0,80)
; fully written, but the reload reads bits [0,32) BEFORE their store runs —
; coverage must be by stores that DOMINATE the reload (instruction-level
; order), or the promoted model threads a value real execution never had at
; that point. packDefinednessOk P1 fails on the non-dominating store, the
; alloca is NOT a candidate, and the tainted word stores fall to the existing
; loud kMsgStore taint-escape decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare i64 @cq_theta_sll(i64, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @packcell_storeafter(i64 %w0) {
entry:
  %q = call i64 @cq_theta_sll(i64 %w0, double 5.000000e-01)
  %manl64 = and i64 %q, 4294967295
  %manl = trunc i64 %manl64 to i32
  %hi = lshr i64 %q, 32
  %manh = trunc i64 %hi to i32
  %u = alloca %union.IEEEl2bits, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %old = load i64, ptr %p8, align 8
  %keep = and i64 %old, -65536
  %es = and i64 %q, 65535
  %w = or disjoint i64 %keep, %es
  store i64 %w, ptr %p8, align 8
  %p4 = getelementptr inbounds i8, ptr %u, i64 4
  store i32 %manh, ptr %p4, align 4
  %e = load x86_fp80, ptr %u, align 16
  store i32 %manl, ptr %u, align 16
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %e)
  ret x86_fp80 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
; CHECK-NOT: cq_template_bitcast_i80_to_f80
