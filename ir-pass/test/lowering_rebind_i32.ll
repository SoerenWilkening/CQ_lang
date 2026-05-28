; lowering_rebind_i32.ll — Width-parametric mid-struct rebind for
; the i32 ABI. Pins that `qint_mid_t` is recognized through
; `WidthDispatch::midStructToSuffix` (the lookup-table path) — the symbol
; output is identical to the original because i32 was already the
; legacy width, but the recognition path is new.
;
; Two frontend suffixes share the i32 ABI (`si32`, `ui32`); only one
; needs an L3 fixture. We pick `si32` (qint_mid_t) — it's the original
; lineage carrier. The end-to-end pattern (extractvalue + add +
; measure) is already covered by `lowering_basic.ll`; this fixture keeps
; the shape uniform with the other six rebind fixtures (init-only).

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i32(i32 99)

; CHECK-NOT: cq_init_si32
; CHECK-NOT: extractvalue

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t = type { i32 }

declare %qint_mid_t @cq_init_si32(i32)

define void @example() {
entry:
  %a = call %qint_mid_t @cq_init_si32(i32 99)
  ret void
}
