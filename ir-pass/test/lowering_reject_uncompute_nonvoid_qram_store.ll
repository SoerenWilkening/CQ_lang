; lowering_reject_uncompute_nonvoid_qram_store.ll — DECLINE (bd test_C_libtooling-1fim,
; the Rule-13 round). THE RETURN-TYPE AXIS, and the discrimination control for the whole
; fix: an ARITY-ONLY implementation of `isAbiQramStore` compiles this module CLEAN.
;
; The sibling `lowering_reject_uncompute_offabi_qram_store.ll` pins the arity axis. This
; one exists because the FIRST DRAFT of the 1fim fix checked arity alone, and THREE
; independent Rule-13 reviewers reproduced the ORIGINAL defect against it by changing
; nothing but the return type.
;
; WHY ARITY WAS THE WRONG TEST. The property the spine stands on is "a QRAM store MINTS
; NO RAIL" — that alone is why `EmitInverse::emitInverseCall` may adjoint a store with a
; SAME-ARGS `_unc` instead of the OUT-FIRST form every rail-minting producer gets. Arity
; is a proxy for that property; VOID-ness IS that property. At the FROZEN arity (3) a
; non-void declaration mints a rail anyway, and the same-args adjoint then cannot name
; it.
;
; MEASURED against the arity-only draft, on exactly this module (`opt` rc=0, verify clean):
;
;   %s = call i32 @cqrt_qram_store_i32(i32 %h, i32 3, i32 4)   ; arity 3, NON-void: MINTS
;   %h_op = call i32 @cq_template_add_i32_hl(i32 %s, i32 1)
;   call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %s, i32 1)
;   call void @cqrt_free(i32 %h_op)
;   call void @cqrt_qram_store_i32_unc(i32 %h, i32 3, i32 4)   ; NEVER NAMES %s
;   call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
;   call void @cqrt_free(i32 %h)                                ; freed anyway
;
; `%s` is never zeroed and never freed, and `%h` — still entangled with the un-reversed
; `%s` — is freed. `cqrt_free` is a hardware reset = a projective measurement, so that is
; a hidden collapse (Rules 5/6/8).
;
; NOTHING ELSE CATCHES IT, which is the reason this fixture is the gate. `opt -verify` is
; clean, and `free_pairing_check.py` (e2e stage 2b) reports
; `1 rail mint(s) of which 0 left allocated, 2 cqrt_free site(s): 2 verified, 0
; violation(s)` and exits 0. The reason is NOT a loose name match — `classify()`
; FULLMATCHES the width-suffixed symbol (`free_pairing_check.py:684`), and a
; prefix-alike name fails it LOUDLY. The hole is that its effect model keys on the NAME
; ALONE and never inspects arity or return type, so any `cqrt_qram_store_<W>` is handed
; `reads=(1,2), writes=(0,)` — modelled as a NON-MINTING in-place gate — even when the
; call returns a value. `%s` is therefore never counted as a rail. That is a FOURTH
; spelling of the frozen-store relation, in a different language, tracked separately.
;
; REACHABILITY: an off-ABI declaration contradicts the frozen ABI and is UB before the
; pass runs, so this is not reachable from conforming input and not a regression. It is
; pinned because the fix is a Rule-14 consistency property, and a property that holds
; only because several spellings agree is exactly what broke in bd uow0 and again here.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
; OFF-ABI on the RETURN-TYPE axis ONLY: the FROZEN arity (3), but non-void — so it MINTS
; a rail the same-args `_unc` can never name. Frozen: `void cqrt_qram_store_i32(i32, i32, i32)`.
declare i32 @cqrt_qram_store_i32(i32, i32, i32)

define void @nonvoid_store(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %s = call i32 @cqrt_qram_store_i32(i32 %q, i32 3, i32 4)  ; frozen arity, NON-void
  %t = add i32 %s, 1                                         ; DEAD cq_template terminal
  ret void
}

; CHECK: error{{.*}}cq uncompute: dead chain contains an un-invertible primitive
