/* D2-A2 — the TREE spelling of the same over-decline, with the NODE still in
   `Pred`. `a` is loop-invariant so LICM hoists the `a == 5` LEAF out of the loop,
   while `r > 2` is loop-variant so the `and` NODE stays in the body. Step 5a's
   `Leaf->getParent() != Region.Pred` is then the only wall. */
int slice(void){
    int a = 0;
    int r = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    for (int i = 0; i < 2; ++i) {
        if (a == 5 && r > 2) { cq_phi(0.7); }
        r = cq_theta(r, 0.9);
    }
    return cq_measure(a) + cq_measure(r);
}
int main(void){(void)slice();return 0;}
