; lowering_fp80_union_dead_insert.ll — bd 3c6m.51 Inc 3 ACCEPT (dead-insert
; elision, Inc-1 parity): a field-insert store-back that no load ever observes —
; here the RAW straddle word (diverged bits [16,64) live in its value!) written
; to offset 0 with no later overlapping load — is ERASED rather than
; canonicalized into an RMW pack. Deadness makes the diverged landing
; unobservable in BOTH the model and the real program (no load of those bytes
; exists after the store), so this promotes where the landing-form negative
; (lowering_reject_fp80_union_padding_insert.ll — the SAME store followed by an
; fp80 reload) loud-declines. The trace carries the extraction only: no
; zext-to-i80/shl/or insert pack, no i80 keep-mask literal.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %cq-opt -passes=verify -S %t.ll -o /dev/null

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)

define i64 @dead() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca { x86_fp80 }, align 16
  store x86_fp80 %q, ptr %u, align 16
  %lo = load i64, ptr %u, align 16       ; offset-0 word (reads the SEED — precedes the store)
  %man = and i64 %lo, 4294967295
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %hi = load i64, ptr %p8, align 8       ; straddle: diverged bits [16,64)
  store i64 %hi, ptr %u, align 16        ; DEAD insert @0 — nothing reads it after
  %exp = and i64 %hi, 32767
  %r = add i64 %man, %exp
  %m = call i64 @cq_measure_sll(i64 %r)
  ret i64 %m
}

; CHECK-NOT: alloca
; CHECK-NOT: store
; CHECK: call i32 @cq_template_bitcast_f80_to_i80
; CHECK-NOT: call i32 @cq_template_zext_i64_to_i80
; CHECK-NOT: call i32 @cq_template_or_i80
; CHECK: call i64 @cqrt_measure_i64
; CHECK-NOT: error
; CHECK-NOT: alloca
; CHECK-NOT: store
