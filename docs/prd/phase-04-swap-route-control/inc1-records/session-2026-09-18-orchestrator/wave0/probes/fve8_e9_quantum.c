int slice(void) { int u; int q = cq_theta(0, 0.3); return cq_measure(q + u); }
int main(void) { return slice(); }
