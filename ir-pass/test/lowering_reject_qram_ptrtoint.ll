; lowering_reject_qram_ptrtoint.ll — DECLINE (Phase 7.5 Inc 3, the §2.8(iv)
; pattern-naming decline matrix): a tainted-index address LAUNDERED through a
; `ptrtoint`/integer-arithmetic/`inttoptr` round-trip — the C `(int*)((intptr_t)tbl
; + q)` idiom. Once the pointer becomes an integer and back, its provenance is gone
; (the optimizer / backend cannot recover a single known-shape origin), so
; reversibility is impossible (no-cloning / linearity,
; [[pointer-boundary-linearity-bennett]]). The provenance walk hits the `inttoptr`
; and loud-declines NAMING the lost provenance. PERMANENT decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@tbl = internal unnamed_addr constant [8 x i32] zeroinitializer
declare i32 @cq_theta_si32(i32, double)

define i32 @ptrint(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %base = ptrtoint ptr @tbl to i64           ; pointer -> integer
  %off = sext i32 %q to i64
  %addr = add i64 %base, %off
  %p = inttoptr i64 %addr to ptr             ; integer -> pointer (provenance lost)
  %v = load i32, ptr %p
  ret i32 %v
}

; CHECK: error{{.*}}cq QRAM access: pointer has no static array provenance
