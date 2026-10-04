/* Phase 2 canonical slice (PRD §2.1). cq_theta/cq_measure resolve from
   CQ.h, force-included by run_slice.sh (-include CQ.h -I include). */
int slice(void) {
    int x = 3;
    cq_theta(&x, 0.5);
    int y = x + 1;
    int z = cq_measure(y);
    return z;
}
int main(void) { (void) slice(); return 0; }
