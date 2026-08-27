; probe_a1_nonconst_immediate.ll — Inc-0 census 0.5 PROBE (bd test_C_libtooling-6uqc,
; plan Risk 6). NOT A TEST. Deliberately NOT registered with lit or ctest: it is
; a hand-authored LOWERED-IR probe whose only purpose is to answer one question
; about `tools/free_pairing_check.py`, and adding it to the suite would turn a
; measurement into a gate nobody asked for.
;
; ============================ THE QUESTION =================================
; M-C (the Grover fix) would lower a single-consumer tainted `q += off` to the
; in-place `cqrt_addc_<W>(%rail, %imm)`. In the customer shape
; (tests/e2e/slice_control_seq_grover.c) `off` is a `volatile int`, LOAD-BEARING
; and deliberately so — written as a literal, `clang -O1` reassociates and
; cancels the `+3 / -3` pair. So after M-C the immediate slot would hold a
; `load volatile i32` RESULT, not a `ConstantInt`.
;
; Rule (A1) of the checker discharges an ALLOCATED rail whose only basis-changing
; writes are classical-immediate in-place updates — but only when it can SHOW the
; immediate is not a rail (`provably_not_a_rail`, added by bd az1h after a planted
; rail in that slot reported OK, exit 0). The docstring records that MEASURED over
; the 237-slice corpus all 41 addc/xorc sites pass, "every one of the 30 [SSA ones]
; is non-call integer arithmetic". A volatile LOAD is not in that measured set.
; Hence: does A1 accept it, or does Inc 2 carry a checker change?
;
; =============================== HOW TO RUN ================================
;     python3 tools/free_pairing_check.py tools/record_census/probe_a1_nonconst_immediate.ll
;
; ============================== THE FUNCTIONS ==============================
; @probe_load     — THE QUESTION. `%imm` is a `load volatile i32` result.
; @probe_rail     — NEGATIVE CONTROL. The immediate slot holds a real RAIL. If
;                   this is NOT flagged, the instrument is dead and no verdict
;                   from @probe_load means anything (bd az1h's own probe shape).
; @probe_param    — BOUNDARY. The immediate is a formal PARAMETER, which
;                   `provably_not_a_rail` explicitly refuses to vouch for.
; @probe_const    — POSITIVE CONTROL. A plain `ConstantInt`, today's shipped
;                   shape (the dtzb break index rail), must stay discharged.

@off = global i32 3, align 4

; --- THE QUESTION: a volatile-load immediate (the Grover `off` shape) --------
define void @probe_load() {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 0)
  %imm = load volatile i32, ptr @off, align 4
  call void @cqrt_addc_i32(i32 %h, i32 %imm)
  %negimm = sub i32 0, %imm
  call void @cqrt_addc_i32(i32 %h, i32 %negimm)
  call void @cqrt_free(i32 %h)
  ret void
}

; --- THE QUESTION, EXACT CUSTOMER SHAPE: TWO SEPARATE volatile loads ---------
; slice_control_seq_grover.c spells `q += off; … q -= off;` with `off` volatile
; precisely so the pair SURVIVES canonicalization — "two volatile loads are two
; values LLVM cannot prove equal". So the +off and -off immediates are DIFFERENT
; SSA values and the (A2) write-history reduction cannot pair them; only (A1) can
; discharge this rail.
define void @probe_two_loads() {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 0)
  %o1 = load volatile i32, ptr @off, align 4
  call void @cqrt_addc_i32(i32 %h, i32 %o1)
  %o2 = load volatile i32, ptr @off, align 4
  %neg = sub i32 0, %o2
  call void @cqrt_addc_i32(i32 %h, i32 %neg)
  call void @cqrt_free(i32 %h)
  ret void
}

; --- NEGATIVE CONTROL: a RAIL in the immediate slot (must be flagged) --------
define void @probe_rail() {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 0)
  %q = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_ry_i32(i32 %q, double 5.000000e-01)
  call void @cqrt_xorc_i32(i32 %h, i32 %q)
  call void @cqrt_free(i32 %h)
  ret void
}

; --- BOUNDARY: the immediate is a formal parameter ---------------------------
define void @probe_param(i32 %k) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_addc_i32(i32 %h, i32 %k)
  %negk = sub i32 0, %k
  call void @cqrt_addc_i32(i32 %h, i32 %negk)
  call void @cqrt_free(i32 %h)
  ret void
}

; --- POSITIVE CONTROL: today's shipped shape (dtzb break index rail) ---------
define void @probe_const() {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_addc_i32(i32 %h, i32 -5)
  call void @cqrt_free(i32 %h)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_addc_i32(i32, i32)
declare void @cqrt_xorc_i32(i32, i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
