/* t16b — a genuine i1 STATE PREP under an i1 rail condition. F2's by-design
   collision: the branch pins b to true/false on its own edges and an i1 seed
   is one of those two constants whatever the source wrote. */
int slice(void) {
    _Bool b = 0;
    _Bool r = 0;
    b = cq_theta(b, 0.5);
    if (b) { r = cq_theta((_Bool) 0, 0.9); }
    return (int) cq_measure(b) + (int) cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
