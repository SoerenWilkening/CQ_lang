; lowering_uncompute_copy_aliased_slots_leak.ll — SAFE LEAK (bd test_C_libtooling-5pio,
; the Rule-13 round). THE SAME VALUE IN BOTH SLOTS of a method-B copy-out.
;
; `ChainWalk::isCopyOutSink` recognizes `cqrt_copy_<W>(src, dst)` reading `H` as its
; SOURCE, and BOTH of its readers — the closure scan in `DagTraversal` and
; `isTerminalHandle` — `continue` on the FIRST match. So for `cqrt_copy_<W>(%x, %x)`
; the value was read purely as a PRESERVED SOURCE and its DESTINATION role — the role
; that for every other value forces `D.NotClosed` and stops the DAG being reversed —
; simply vanished.
;
; MEASURED before the fix (`opt` rc=0, `opt -verify` clean):
;
;   %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 1)
;   call void @cqrt_copy_i32(i32 %h_op, i32 %h_op)      ; WRITES %h_op
;   call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 1)
;   call void @cqrt_free(i32 %h_op)                      ; freed with one un-adjointed
;                                                        ; write still on it
;
; The copy WRITES `%h_op`, that write is never adjointed (the spine only ever saw the
; read), and the rail is then freed — a `cqrt_free` on a register that is not provably
; |0>, i.e. a hidden projective measurement (Rules 5/6/8).
;
; PRE-EXISTING, not introduced by the 5pio freeze — `railOf` already reasons explicitly
; about the same-value-in-two-slots case for IN-PLACE gates, and this predicate simply
; never got that treatment. It is fixed here because bd 5pio makes `isCopyOutSink`
; load-bearing for the record FREEZE and not only for closure, so its holes carry more
; weight than they did.
;
; FIX: `isCopyOutSink` requires arg 0 and arg 1 to be DISTINCT. The aliased form is
; then an unrecognized user, the DAG is `NotClosed`, no reversal is emitted, and the
; rail is LEFT ALLOCATED — Rule 6's sanctioned fallback, and the over-declining
; direction. No emitter mints an aliased copy.
;
; WHAT STAGE 2b SEES, stated because this is one of the rare cases where it DOES see
; something: `free_pairing_check.py` flags the aliased call itself as
; `VIOLATION B1-input-aliases-written-rail` on BOTH sides of the fix — the aliased copy
; is not a unitary at all, so no backend can realize it either way. What the fix
; changes is the `cqrt_free`: before, "1 cqrt_free site(s): 0 verified, 1 unproven";
; after, "0 cqrt_free site(s) … 0 unproven". So 2b witnesses the aliasing but NOT the
; unsound free that followed from it, and this fixture is the gate for the latter.
;
; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the `+ 1` lowers IN PLACE,
; so the aliased copy's two slots are the ROOT rail. The leak this file pins (no
; `_unc`, no free, nothing measured) is unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare void @cqrt_copy_i32(i32, i32)

define i32 @aliased_copy_slots(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = add i32 %q, 1
  call void @cqrt_copy_i32(i32 %a, i32 %a)   ; SAME value as src AND dst
  ret i32 0
}

; The forward stream lowers; the aliased copy is emitted verbatim.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 1)
; CHECK:     call void @cqrt_copy_i32(i32 %[[H]], i32 %[[H]])
;
; NOTHING is reversed and NOTHING is freed — both rails are left allocated. The
; `CHECK-NOT`s are the discrimination controls: pre-fix the pass emitted the `_unc`
; and then `cqrt_free(%[[OP]])` on a rail the copy had written.
; CHECK-NOT: cq_template_add_i32_hl_unc
; CHECK-NOT: cqrt_free
; CHECK-NOT: cqrt_measure
