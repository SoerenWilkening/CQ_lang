/* X5-deep (merge gate 2026-09-14) — the shape Track F's retirement trigger
   asks to re-derive: an IN-LOOP bare-_Bool controlled state prep (the class
   bd wx8g now ADMITS) whose loop-header phi takes the region's MERGE-phi
   descendant on its BACK EDGE — i.e. exactly the available collider the
   dominance skip in ArmClassify's f2 helper was narrowed for. */
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int s = 0;
    int carry = 7;
    for (int k = 0; k < CQ_K; ++k) {
        int r = carry;
        if (b) r = cq_theta(7, 0.2);
        carry = r;                 /* back edge := the region's merge phi */
        s += cq_measure(r);
    }
    return s + cq_measure(b);
}
int main(void) { return slice(); }
