/* slice_compare_measure.c — Phase 3 e2e smoke: data-position compares measured
   through the zext flag-handle bridge (PRD §7, §2.8, IMPLEMENTATION §1.3).

   A tainted compare in pure data/measure position (no `br i1` / `select i1`
   user) lowers to a flag-handle template returning i32 (logically 1-qubit),
   never an i1. Clang's own `zext i1 -> i32` (the C `int` result of a relational
   operator) then lowers to a zext cast template that widens the flag handle
   before measurement. Capturing the (i1 -> i32) widths BEFORE the compare's
   cross-type RAUW is what makes the bridge correct (IMPLEMENTATION §1.3).

   Two compares, one per family:
     xi <  10    -> cq_template_icmp_slt_i32_hl(hi, 10) -> flag
                 -> cq_template_zext_i1_to_i32(flag)    -> widened
                 -> cqrt_measure_i32(widened)
     xf != 1.0f  -> cq_template_fcmp_une_f32_hl(hf, 1.0) -> flag   (closes -7ws:
                 -> cq_template_zext_i1_to_i32(flag)    -> widened  clang emits
                 -> cqrt_measure_i32(widened)                       `une`, not `one`)

   cq_theta/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
int slice(void) {
    int   xi = 3;
    float xf = 2.0f;
    xi = cq_theta(xi, 0.5);    /* taint xi -> handle (alloc i32(3), ry_i32)   */
    xf = cq_theta(xf, 0.25);   /* taint xf -> handle (alloc f32(2.0), ry_f32) */

    int lt  = (xi < 10);       /* icmp slt -> flag -> zext i1->i32 -> measure */
    int neq = (xf != 1.0f);    /* fcmp une -> flag -> zext i1->i32 -> measure */

    return cq_measure(lt) + cq_measure(neq);
}
int main(void) { (void) slice(); return 0; }
