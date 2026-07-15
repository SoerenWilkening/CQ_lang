; lowering_reject_fp80_union_escape.ll — bd 3c6m.51 OFF-PATTERN (over-decline is
; safe): the union address ESCAPES to an opaque call, so promoteFp80Union cannot
; prove every access is a load/store into the cell — it leaves the union
; byte-untouched, and the tainted `store x86_fp80` then declines at the existing
; escape guard (kMsgStore). Pins that the peephole does NOT over-promote a union
; whose address leaves (a promotion there would drop the escaping call's view of
; the bytes — a silent miscompile).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare void @sink(ptr)

define void @escape() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca { x86_fp80 }, align 16
  store x86_fp80 %q, ptr %u, align 16
  call void @sink(ptr %u)                       ; address escapes — union NOT promotable
  ret void
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
; CHECK-NOT: cq_template_bitcast_f80_to_i80
