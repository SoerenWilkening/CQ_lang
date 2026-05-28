; lowering_sub_negative.ll — Negative fixture: a tainted `sub i32` has
; no template registered (PRD §"Diagnostics baseline"
; documents this as a known soft-failure mode).
; OpcodeLowering must report it through a loud, recognizable
; "no template for opcode" diagnostic — never silently leave the `sub`
; in the IR — loud, not silent.

; The pass calls `DiagnosticInfoUnsupported(DS_Error)` which makes opt
; exit non-zero. Inverting via `not` is the canonical LIT idiom — the
; site config adds the LLVM tools dir (where `not` lives) to PATH so
; the wrapper resolves. We pipe stderr into FileCheck to verify the
; diagnostic was emitted.

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

; CHECK: error{{.*}}no template for opcode 'sub i32'{{.*}}tainted context

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t = type { i32 }

declare %qint_mid_t @cq_init_si32(i32)

define void @example() {
entry:
  %a_struct = call %qint_mid_t @cq_init_si32(i32 3)
  %a        = extractvalue %qint_mid_t %a_struct, 0

  ; Tainted `sub`: no template for this opcode. The pass
  ; must diagnose the gap rather than swallowing it silently.
  %c        = sub i32 %a, 5
  ret void
}
