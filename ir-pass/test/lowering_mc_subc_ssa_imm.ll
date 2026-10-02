; lowering_mc_subc_ssa_imm.ll — M-C `sub` with a NON-CONSTANT classical
; immediate (bd test_C_libtooling-6uqc, Increment 2b).
;
; THE POINT OF THIS FILE: the negated immediate is not always a literal. In the
; campaign's own customer (tests/e2e/slice_control_seq_grover.c) the immediate is
; a `volatile` load — deliberately, so `clang -O1` cannot cancel the `+off`/`-off`
; pair — so `q -= off` must emit the negation as ORDINARY CLASSICAL IR:
;
;     %neg = sub i32 0, %off            <- classical, untainted, prints nothing
;     call void @cqrt_addc_i32(i32 %h, i32 %neg)
;
; That `sub` is CLASSICAL CODE. It is created during Phase 2 of `lowerOps`,
; after the taint set is frozen, so it never joins `taint.Tainted`, never becomes
; a gate, and emits no trace line. `free_pairing_check.py`'s rule (A1) reads the
; immediate slot and its `provably_not_a_rail` answers TRUE for exactly this
; shape — a plain classical instruction result that is neither a rail, a formal
; parameter, nor a rail-minting call (its docstring names `sub i32 0, %6`).
;
; The ADJOINT negates again (`EmitInverse`'s `CreateNeg`), so the reversal is a
; second classical `sub` feeding `cqrt_addc_i32` — the in-place gate is undone
; before the un-rotation. The rail then holds its seed 41, not |0>, so it is kept,
; never freed (bd 5c5b, libcqops vmz9).
;
; LIMIT (2b Rule-13 round, F1): (A1) clears the immediate SLOT only. The checker
; cannot PAIR two SSA-named immediates (`%v` vs `sub iW 0, %v`), so this very
; stream — if its rail is freed under a STRICT slice — reports UNPROVEN (loud,
; safe direction; the 2a `add %q, %v` analogue behaves identically, so this is
; not a sub-specific property). No shipped strict slice hits the shape.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEROOT < %t.cqd0.ll
;
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @off
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; The forward gate's immediate is the CLASSICAL negation of the loaded value:
; CHECK:      %[[N:[a-zA-Z0-9_.]+]] = sub i32 0, %[[V]]
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[N]])
; and the adjoint negates it back:
; CHECK:      %[[N2:[a-zA-Z0-9_.]+]] = sub i32 0, %[[N]]
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[N2]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: ret void
;
; CHECK-NOT:  cq_template_sub_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@off = global i32 3

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %v = load volatile i32, ptr @off, align 4
  %a = call i32 @cq_theta_si32(i32 41, double 5.000000e-01)
  %c = sub i32 %a, %v        ; parent DEAD after -> in place, SSA imm negated
  ret void
}

; bd 5c5b review r2: the root is never freed ANYWHERE after its birth — own prefix,
; one anchor (the alloc), so the window runs alloc -> EOF and also covers a free
; slipped in BEFORE the root's un-rotation; `tools/fixture_guard_liveness.py`
; checks the window by injection.
; NOFREEROOT:     %[[RT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; NOFREEROOT-NOT: call void @cqrt_free(i32 %[[RT]])
