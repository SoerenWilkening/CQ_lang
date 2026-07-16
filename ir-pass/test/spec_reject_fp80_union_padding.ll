; spec_reject_fp80_union_padding.ll — DECLINE PIN (bd vqlq): the COMPOSED
; boundary of the two vqlq enablers — a spec-candidate callee whose union the
; §4.1 walk refuses (the raw offset-8 word, padding bits [80,128), escapes
; through the return) is silently dropped by the promotion (opportunistic
; seed), so the callee reaches detectSpecializations still in MEMORY form and
; the body gate declines it loudly, exactly as before vqlq. The widening opens
; only the fence-provable shapes; everything else keeps today's loud decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %y = call i32 @punread(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

define i32 @punread(i32 noundef %0) {
  %2 = alloca %union.IEEEl2bits, align 16
  %3 = sitofp i32 %0 to x86_fp80
  store x86_fp80 %3, ptr %2, align 16
  %4 = getelementptr inbounds i8, ptr %2, i64 8
  %5 = load i64, ptr %4, align 8      ; the offset-8 word straddles the padding
  %6 = trunc i64 %5 to i32            ; bits [64,96): 16 meaningful + 16 PADDING
  ret i32 %6                          ; diverged bits escape the return — no promote
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct
