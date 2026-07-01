/* slice_byref.c — bd g387 e2e link proof: by-ref math out-params
   (frexp/modf/remquo). The ONLY layer that LINKS, so the only proof that the
   g387 producer templates — cq_template_frexp/frexpexp/modf/modfint/remquo/
   remquoquo (incl. the NEW cross_binary remquoquo_f64_to_i32[_hl]) AND their
   void `_unc` twins — all resolve and signature-match the generated sibling ABI
   through the runtime (Rule 2, Rule 16). A green opt -verify + passing FileCheck
   on the .ll fixtures are NOT this proof.

   Each by-ref call is canonicalized (ByRefMath) into TWO Class-2 producer markers
   over the SAME live source — a primary (the return value) and a secondary (the
   out-cell write) — and the memory cell is erased. Taint does not cross memory;
   the read-back load's value is injected as the secondary producer.

   Lineages in a `__attribute__((noinline))` helper (the noinline boundary is
   LOAD-BEARING: whole-DAG uncompute is gated OFF in `main`, and at -O1 clang would
   otherwise inline `slice` so the uncompute never runs).

   (A)-(D) MEASURED forwards — prove the FORWARD symbols (live terminals, no _unc):
       frexp (mantissa+exponent), modf (frac+int part, fp second result via fptosi),
       remquo QQ (remainder + cross_binary quotient), remquo HL (classical divisor).
   (E) DEAD frexp lineage — proves the fan-out `_unc` twins + R-E source-liveness:
       BOTH producers read the SAME source; each is reversed ONCE (recompute-and-XOR
       from the still-LIVE source), the source reversed ONCE, then each rail freed.
       Kept alive past -O1 DCE by a `cq_phi` (Rz) whose own result is dropped.

   cq_theta/cq_phi/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
#include <math.h>

__attribute__((noinline))
void slice(double x, double y) {
    /* (A) frexp measured — mantissa + exponent forwards. */
    double a = cq_theta(x, 0.25);
    int ea;
    double ma = frexp(a, &ea);
    (void) cq_measure((int) ma);
    (void) cq_measure(ea);

    /* (B) modf measured — fraction + integer part (fp second result -> fptosi). */
    double b = cq_theta(y, 0.35);
    double ib;
    double fb = modf(b, &ib);
    (void) cq_measure((int) fb);
    (void) cq_measure((int) ib);

    /* (C) remquo QQ measured — cross_binary quotient (both operands quantum). */
    double c = cq_theta(x, 0.45);
    double d = cq_theta(y, 0.55);
    int qc;
    double rc = remquo(c, d, &qc);
    (void) cq_measure((int) rc);
    (void) cq_measure(qc);

    /* (D) remquo HL measured — cross_binary _hl (classical divisor literal). */
    double e = cq_theta(x, 0.65);
    int qe;
    double re = remquo(e, 2.0, &qe);
    (void) cq_measure((int) re);
    (void) cq_measure(qe);

    /* (E) DEAD frexp lineage — the fan-out `_unc` twins (Rule 13). */
    double f = cq_theta(y, 0.10);
    int ef;
    double mf = frexp(f, &ef);
    (void) cq_phi((int) mf, 0.20);   /* keep-alive mantissa; result dropped */
    (void) cq_phi(ef, 0.30);         /* keep-alive exponent; result dropped */
}
int main(void) { slice(1.5, 2.5); return 0; }
