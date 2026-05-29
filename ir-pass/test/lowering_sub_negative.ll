; lowering_sub_negative.ll — Negative fixture: a tainted `sub i32` has no
; template. OpcodeLowering must report it through a loud, recognizable
; "no template for opcode" diagnostic — never silently leave the sub in.
; The pass calls DiagnosticInfoUnsupported(DS_Error) so opt exits non-zero;
; `not` inverts it and stderr is piped to FileCheck.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: error{{.*}}no template for opcode 'sub i32'{{.*}}tainted context

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  ; Tainted `sub`: no template for this opcode — must diagnose, not swallow.
  %c = sub i32 %a, 5
  ret void
}
