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
    /* (A) integer: %q and %r are SSA-DISTINCT, ONE RAIL after lowering. */
    int q = cq_theta(x, 0.50);
    int r = q; cq_phi(0.25);
    int s = (q < r) ? 11 : 22;           /* icmp slt h0, h0 — CASE A */
    (void) cq_measure(s);

    /* (B) f64: the same alias through the kjd1 fp select copy family. */
    double qf = cq_theta(d, 0.75);
    double rf = qf; cq_phi(0.125);
    double sf = (qf < rf) ? 1.0 : 2.0;   /* fcmp olt h?, h? — CASE A */
    (void) cq_measure(sf);

    /* (C) arithmetic Case A on one rail — the consistency witness. */
    int p = cq_theta(x, 0.10);
    (void) cq_measure(p * p);            /* cq_template_mul_i32(h?, h?) */

    /* (D) CONSTANT-TRUE integer predicate — the flag rail is |1> at the mint,
       so the strip must return it to |0> before the free (Rule 6). */
    int qe = cq_theta(x, 0.05);
    int re = qe; cq_phi(0.35);
    int se = (qe == re) ? 11 : 22;       /* icmp eq(a,a) == constant TRUE */
    (void) cq_measure(se);

    /* (E) f64 ENTANGLED flag, NOT a constant: `fcmp oge(a,a)` == ord(a) ==
       !isnan(a). No ORDERED fcmp is constant on aliased operands. */
    double qg = cq_theta(d, 0.20);
    double rg = qg; cq_phi(0.40);
    double sg = (qg >= rg) ? 1.0 : 2.0;  /* fcmp oge(a,a) == !isnan(a) */
    (void) cq_measure(sg);
}
int main(void) { slice(3, 0.5); return 0; }
