; lowering_reject_uncompute_offabi_qram_store.ll — DECLINE (bd test_C_libtooling-1fim).
; THE PREDICATE-CONSISTENCY fixture for the QRAM store, and the second instance of the
; class bd uow0 fixed the first of: TWO PREDICATES, ONE GATE, DIFFERENT ANSWERS.
;
; `EmitInverse::isInverseEmittable` matched `cqrt_qram_store_*` by PREFIX at ANY arity,
; while `ChainWalk::isInPlaceGateOn` demands the exact frozen ABI arity (3 plain /
; 4 controlled). An OFF-ABI-arity store therefore got an adjoint from one predicate and
; no rail from the other.
;
; MEASURED on the pre-fix pass, on exactly this module (`opt` rc=0, verify clean):
;
;   %s = call i32 @cqrt_qram_store_i32(i32 %h, i32 3)      ; mints a rail
;   ...
;   call void @cqrt_qram_store_i32_unc(i32 %h, i32 3)      ; NEVER NAMES %s
;   call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
;   call void @cqrt_free(i32 %h)                            ; frees %h anyway
;
; The store `_unc` uses the SAME-ARGS (not out-first) slot convention because a real
; store mints no rail. Here the off-ABI declaration DOES mint one (%s), so the emitted
; adjoint zeroes nothing, %s is never uncomputed, and `%h` — still entangled with the
; un-reversed %s — is freed. That free is a hidden projective collapse (Rules 6/8).
;
; NOTHING ELSE CATCHES IT. `opt -verify` is clean, and `free_pairing_check.py` (e2e
; stage 2b) reports `1 rail mint(s) of which 0 left allocated, 2 cqrt_free site(s):
; 2 verified, 0 violation(s)` and exits 0 — it CERTIFIES the broken module. State the
; reason precisely, because the obvious one is WRONG: it is NOT a loose name match.
; `classify()` FULLMATCHES the width-suffixed symbol (`free_pairing_check.py:684`, `_W`
; at `:543`), and a merely prefix-alike name such as `@cqrt_qram_store_i32x` is
; UNCLASSIFIED and fails the checker LOUDLY at rc=1 — verified by probe. The real hole
; is that the effect model keys on the NAME ALONE and never inspects ARITY or RETURN
; TYPE: anything spelled `cqrt_qram_store_<W>` is handed `reads=(1,2), writes=(0,)`,
; i.e. modelled as a NON-MINTING in-place gate, even at 2 args and even when it returns
; a value. So `%s` is never counted as a rail. Tightening the regex would fix nothing;
; the missing test is a SIGNATURE check (filed separately). The lit decline below is the
; only gate that witnesses this.
;
; REACHABILITY, stated exactly: an off-ABI DECLARATION contradicts the frozen ABI in
; arity and/or return type and is UB before the pass runs, so this is NOT reachable
; from conforming input and NOT a regression — both the pre- and post-uow0 passes emit
; the unsound free. It is reachable at all only because `declineTaintEscapes` carves
; out every `cqrt_*` callee BY NAME with no signature check. Pinned because the fix is
; a Rule-14 consistency property (`isAbiQramStore` is now the ONE definition both
; predicates consult), and a property that is only true by two spellings agreeing is
; the exact thing that broke in bd uow0.
;
; The declining message is the EXISTING WI-5 un-invertible decline, not a new one: an
; off-ABI store IS a primitive the spine has no adjoint for, which is precisely what
; that diagnostic says. No half-reversed chain and no dangling free are emitted (DD-1).
;
; THE ARITY AXIS. Its sibling `lowering_reject_uncompute_nonvoid_qram_store.ll` pins the
; RETURN-TYPE axis, which is the one that actually discriminates the shipped fix — see
; there. One axis per fixture deliberately: the driver declines at the FIRST offending
; function and stops, so a single module can witness only ONE decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
; OFF-ABI on the ARITY axis: the frozen prototype is
; `void cqrt_qram_store_i32(i32 arr, i32 idx, i32 val)` — void, arity 3.
declare i32 @cqrt_qram_store_i32(i32, i32)

define void @offabi_store(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %s = call i32 @cqrt_qram_store_i32(i32 %q, i32 3)   ; off-ABI arity: mints a rail
  %t = add i32 %s, 1                                   ; DEAD cq_template terminal off %s
  ret void
}

; CHECK: error{{.*}}cq uncompute: dead chain contains an un-invertible primitive
