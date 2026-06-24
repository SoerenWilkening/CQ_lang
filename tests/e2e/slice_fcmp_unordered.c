/* slice_fcmp_unordered.c — Phase 7.1 (8rvn, iw81.4 §4.4) e2e smoke: the
   UNORDERED fcmp predicates lower, link, and trace end-to-end.

   Before 8rvn the fcmp surface was the 6 predicates Clang emits from plain C
   `== != < > <= >=` ({oeq,une,olt,ogt,ole,oge}); the unordered twins had no
   template and loud-declined. 8rvn ships the full ordered/unordered comparison
   family, so the negated relational compares and `__builtin_isunordered` — which
   Clang -O1 folds straight to the unordered predicates — now lower to their
   generated templates and LINK (this is the only layer that links, proving every
   emitted `cq_template_fcmp_<pred>_f32_hl` resolves and signature-matches):

     !(x >= 1.0f)              -> fcmp ult  -> flag -> zext i1->i32 -> measure
     !(x <  1.0f)              -> fcmp uge  -> flag -> zext i1->i32 -> measure
     !(x >  1.0f)              -> fcmp ule  -> flag -> zext i1->i32 -> measure
     !(x <= 1.0f)              -> fcmp ugt  -> flag -> zext i1->i32 -> measure
     __builtin_isunordered(x,) -> fcmp uno  -> flag -> zext i1->i32 -> measure

   Each compare's i1 result is a DATA flag (Clang's `int` result of the
   expression), widened by `zext i1->i32` before measurement — never a rotation
   angle. cq_theta/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
int slice(void) {
    float x = 2.0f;
    x = cq_theta(x, 0.25);          /* taint x -> handle (alloc f32(2.0), ry_f32) */

    int lt = !(x >= 1.0f);          /* fcmp ult */
    int ge = !(x <  1.0f);          /* fcmp uge */
    int le = !(x >  1.0f);          /* fcmp ule */
    int gt = !(x <= 1.0f);          /* fcmp ugt */
    int uo = __builtin_isunordered(x, 1.0f);  /* fcmp uno */

    return cq_measure(lt) + cq_measure(ge) + cq_measure(le)
         + cq_measure(gt) + cq_measure(uo);
}
int main(void) { (void) slice(); return 0; }
