/* D2-A1 — the customer's SIMPLEST C spelling, bd `drbq.12` / PRD §13.10 Q1 / §13.11
   worry 7: `for (…) { if (q == 5) r = cq_theta(r, .9); }` with `r` disjoint from `q`
   and NO gate on `q`, so `clang -O1` LICM-hoists the compare out of `Pred`. */
int slice(void){
    int a = 0;
    int r = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    for (int i = 0; i < 2; ++i) {
        if (a == 5) { r = cq_theta(r, 0.9); }
    }
    return cq_measure(a) + cq_measure(r);
}
int main(void){(void)slice();return 0;}
