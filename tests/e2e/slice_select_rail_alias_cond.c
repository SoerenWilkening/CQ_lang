/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-5 / prep-b2): THREE of the five lineages
   RETIRED, two kept. The golden below is a NEW PROGRAM's trace, not an audit
   substitution, and it is recorded as such in
   docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md.

   RETIRED — (A) `int r = cq_phi(q,.25); (q < r) ? 11 : 22`,
             (B) the same at f64 with `<`,
             (D) `int re = cq_phi(qe,.35); (qe == re) ? 11 : 22`.
   All three existed to exercise a compare whose two operands are SSA-DISTINCT
   but ONE RAIL, and the ONLY way to build that pair in CQ was the RENAMING
   in-place gate `%r = cq_phi(%q, θ)`. Under owner decision D1 `cq_phi` renames
   nothing, so `r` IS `q`, the compares become `x < x` / `x == x` on one SSA
   value, and `clang -O1` folds them to constants at STAGE 1 (prep-b PROBE 3,
   MEASURED: the three lineages collapse to `cq_measure_si32(i32 22)`,
   `cq_measure_f64(double 2.0)` and `cq_measure_si32(i32 11)`, and the module
   then declines `cq_measure_<sfx> operand not recognized; expected a tainted i32
   handle`). The property cannot be spelled in the language any more; it is
   retired here rather than left as three folded constants pretending to test it.

   KEPT — (C) the arithmetic Case A `p * p`, which is a GENUINE aliased-operand
   site and lowers to `cq_template_mul_i32(h0, h0)` in the golden below; and (E)
   the f64 `(qg >= qg) ? 1.0 : 2.0`, which survives stage 1 at all only because
   `x >= x` is FALSE for NaN and so cannot fold to a constant.

   ⚠ SAY WHAT (E) IS NOW, because the obvious reading is wrong and I measured it:
   `clang -O1` does NOT leave `fcmp oge x, x`; it rewrites it to `fcmp ord x, x`
   and then to `fcmp ord x, 0.0`, so the emitted line is
   `cq_template_fcmp_ord_f64_hl(h2, 0x0p+0)` — a Q+C compare with NO aliased
   operand. (E) is therefore kept as a live customer of the kjd1 fp-DATA select
   copy family (`cqrt_copy_f64_controlled` ×2, the `cqrt_x` bracket, the void
   out-first `_unc` strip and the Rule-6 free), NOT as an alias witness.

   NET COVERAGE LOSS, recorded rather than papered over: the ALIASED-OPERAND
   COMPARE has no spelling left in CQ at any width — `cq_template_icmp_slt_i32(h,h)`,
   `cq_template_icmp_eq_i32(h,h)`, `cq_template_fcmp_olt_f64(h,h)`,
   `cq_template_fcmp_oge_f64(h,h)` and their four `_unc` twins leave this golden.
   Only the ARITHMETIC alias (C) survives. The reason is structural, not a fence:
   every aliased compare `x REL x` is a compile-time constant or an ordered-ness
   test, so `clang -O1` rewrites it before the pass ever sees it, and the one CQ
   construct that used to build two SSA-distinct names for one rail — the
   RENAMING `%r = cq_phi(%q, θ)` — is exactly what owner decision D1 removes.
   Recorded in GOLDEN_REGEN.md. */
/* 3qlq Inc 1: migrated to register-free cq_phi -- four `T r = cq_phi(q, th)` -> `T r = q; cq_phi(th);` (RENAME SITES).
   FLAG (the whole mechanism): this slice's header states that `%q` and
   `%r = cq_phi(%q,.)` are SSA-DISTINCT yet ONE RAIL, and that this is why
   `q < r` is NOT foldable by InstCombine. After the migration r IS q, so all four
   compares are `x < x` / `x == x` / `x >= x` on ONE SSA value and InstCombine folds
   them at STAGE 1. The alias the slice was written to exercise cannot be spelled
   with a register-free cq_phi at all. Purpose does NOT survive.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_select_rail_alias_cond.c — bd big5 (2026-07-31) e2e link proof for the
   ALIASED-RAIL condition compare, the shape bd 7q3s fenced for one day on a
   premise the owner then refuted.

   THE MECHANISM (the durable half of 7q3s, unretracted): `cq_phi` (Rz) is an
   IN-PLACE gate whose lowered result RAUWs to its argument's i32 handle, so two
   SSA-DISTINCT values become ONE RAIL during RotationLowering. `%q` and
   `%r = cq_phi(%q,·)` are therefore not foldable by InstCombine — unlike `x==x`
   — yet both lower to `h0`. A PRE-MUTATION SSA TEST CANNOT SEE THIS.

   WHY IT LOWERS RATHER THAN DECLINING — the CASE A / CASE B partition (owner
   ruling 2026-07-31, bd memory [aliased-rail-gate-is-realizable-2026-07-31]):

     CASE A — aliased INPUTS of an OUT-OF-PLACE gate whose output is a FRESH |0>
     rail. Aliasing the inputs makes the gate a UNARY function of the shared
     operand, which is always realizable and usually free: `icmp_slt(a,a)` is
     constant FALSE, `icmp_eq(a,a)` constant TRUE, `toffoli(c,c,G)` == `cnot(c,G)`,
     `fmul(a,a)` == squaring. A PHASE-9 BACKEND OBLIGATION, not a compiler defect.

     CASE B — an input aliasing a rail the gate WRITES (`cqrt_cnot(c,c)` erases;
     `cqrt_cswap(c,c,b)` is not unitary). NOT realizable — and this slice emits
     none: read the golden and check that every `_unc` / `_controlled` / `copy`
     line has its WRITTEN rail distinct from its read operands.

   THIS IS THE ONLY LAYER THAT LINKS (Rule 2), so it is the only proof that the
   aliased mint's symbols — `cq_template_icmp_slt_i32(h0,h0)` and its void
   out-first `_unc` twin — resolve and signature-match the generated ABI, and that
   stage 2b (`tools/free_pairing_check.py`, Rule 6) still proves the flag rail is
   |0> at its `cqrt_free`.

   FIVE LINEAGES:
     (A) integer rail-aliased condition feeding a 4.4 select — the canonical form,
         reachable from four lines of plain C at the -O1 ship floor.
     (B) the same at f64, through the kjd1 fp-DATA select copy family.
     (C) an ARITHMETIC Case A (`q*q` on one rail) in the SAME translation unit —
         the consistency witness. 118 of 226 committed goldens already ship an
         aliased-operand forward template call (slice_libm_real_acos.c:102 `z=x*x`
         -> `cq_template_fmul_f64(h0, h0)`), and they were GREEN WITH THE FENCE
         IN — the condition-tree walk never inspects arithmetic, so the fence
         could not and did not condemn any golden. The defect was an
         INCONSISTENCY OF PRINCIPLE, not a contradiction: the DATA path already
         depends on Case A being realizable. Here the two sit side by side in one
         TU so the inconsistency cannot be re-introduced unnoticed.
     (D) the CONSTANT-TRUE integer predicate `icmp_eq(a,a)`. This is the
         demanding half of the Rule-6 obligation and (A)/(B) do NOT cover it:
         `icmp_slt(a,a)` / `fcmp_olt(a,a)` are constant FALSE, so their flag rail
         is left at |0> trivially and the strip is a no-op on it. `icmp_eq(a,a)`
         is constant TRUE, so the flag rail is |1> after the mint and the `_unc`
         strip must actually RETURN it to |0> before `cqrt_free` — exactly the
         pairing bd 8txa moved onto the void out-first `_unc` so the golden could
         witness it. Sound because the strip is the adjoint of the mint at the
         same operands and the data rail is unchanged between the two (the merge
         copies write `%out`, never `q`).
     (E) the ENTANGLED-FLAG f64 case. `fcmp_oge(a,a)` is NOT constant TRUE —
         READ THIS BEFORE "FIXING" IT. `oge` is an ORDERED predicate, so it is
         FALSE whenever an operand is NaN: `fcmp_oge(a,a)` is exactly `ord(a)` =
         `!isnan(a)`, the ordered twin of the `fcmp uno(a,a)` == `isnan(a)` case
         pinned in control_swap_accept_select_aliased_leaf.ll. In fact NO ordered
         fcmp can be constant on aliased operands, and the unordered ones that
         CAN (`ueq`/`uge`/`ule`) are not emitted by clang -O1 from `>=`. So the
         flag rail here is a SUPERPOSITION CORRELATED WITH THE DATA RAIL, which
         is a STRICTLY HARDER Rule-6 witness than a constant: the strip must
         return an entangled rail to |0> without measuring it. Traced and
         confirmed: Sum_x a_x|x>|ord(x)>|0> -> copies -> Sum_x a_x|x>|ord(x)>
         |sel(x)> -> `_unc(g,h,h)` -> Sum_x a_x|x>|0>|sel(x)>, a product |0> at
         the free.
     MIND RULE 9 *AND* VALUE SEMANTICS IF YOU EXTEND THIS. Two independent traps,
     both measured: (1) `q <= r` does not reach here as written — clang -O1
     canonicalizes it to `icmp sgt` with the arms swapped; `==` and `>=` survive
     as themselves. (2) surviving as the same PREDICATE is not the same as being
     constant-TRUE on aliased operands — that is the value-semantics half, and it
     is where an earlier draft of this comment was wrong about `oge`.

   cq_theta/cq_phi/cq_measure resolve from CQ.h (force-included by run_slice.sh). */

__attribute__((noinline))
void slice(int x, double d) {
    /* (C) an ARITHMETIC Case A — `p * p` on ONE rail. SURVIVES the migration:
       nothing about it depended on a renaming diagonal gate.               */
    int p = x; cq_theta(&p, 0.10);
    (void) cq_measure(p * p);            /* cq_template_mul_i32(h, h)        */

    /* (E) an f64 aliased-rail condition feeding a kjd1 fp-DATA select.
       SURVIVES because `x >= x` is NOT foldable to a constant: it is FALSE
       when x is NaN, so `clang -O1` rewrites it to `fcmp ord x, x` — still an
       ALIASED-OPERAND compare, which is the mechanism this slice links.     */
    double qg = d; cq_theta(&qg, 0.20);
    double sg = (qg >= qg) ? 1.0 : 2.0;
    (void) cq_measure(sg);
}

int main(void) { slice(3, 0.5); return 0; }
