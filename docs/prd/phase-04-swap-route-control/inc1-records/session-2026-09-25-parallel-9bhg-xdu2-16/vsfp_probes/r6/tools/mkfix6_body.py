
# ================================================================ bd vsfp ROUND 6 entries
CLONE_NOTPL = {}
INNER_ZERO = set()
NONULL = set()

MT = V / "r6"
CLONE_NOTPL["spec_accept_phantom_arg_read_musttail_inner_slot.ll"] = "__cq_q_h_"
INNER_ZERO.add("spec_accept_phantom_arg_read_musttail_inner_slot.ll")
E("spec_accept_phantom_arg_read_musttail_inner_slot.ll", MT / "mt1.s1.ll", "main",
  """; spec_accept_phantom_arg_read_musttail_inner_slot.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-w7nm; bd vsfp Rule-13 r5 F-Z-1, probe `mt1`; 2 TUs llvm-linked, stage 1 as the
; reviewer recorded it).
;
; r2B's `k19` main (`p = q * 3` feeds `h`'s dead slot and the oracle `(p ^ q) == 10`) with
; `int h(int a, int k) { __attribute__((musttail)) return h2(a, k); }` and `h2` reading `a` only in
; a volatile-fold empty diamond. `h2`'s clone records slot 0 dead; inside `h`'s clone that slot is
; on a `musttail` call. Round 5 asked the drop's WHOLE eligibility (`dropEligibleSlot`, whose
; `musttail` refusal is a POLICY conservatism) in the liveness call-slot rule, so the inner slot
; counted as a READ, `h`'s parameter became live, the outer phantom slot was never neutralised, and
; the spine left `p`'s template rail dirty across `Ry(0.7)` — bd tzfa's wrong unitary, exit 0, the
; ORACLE's stream byte-for-byte. Round 6 asks `nullSafeSlot` there (slot type + attributes only). The
; CLONE prefix pins that `h`'s clone passes `0` into the inner `musttail` call and holds no
; template; the main CHECKs pin the twin's stream (the `mul_i32_hl_unc` + `cqrt_free` of `p` before
; the second Ry). The e2e pair `e2e-spec-dropped-arg-musttail-inner-twin-identical` links it.
;""")
