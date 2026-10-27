struct pair { int f; int g; };
__attribute__((noinline)) static void bump(int *p) { *p += 1; }
int ptr_select_rmw(int x0, double th, int k, int a0, double ta, int b0, double tb) {
    int x = x0, a = a0, b = b0;
    cq_theta(&x, th);
    cq_theta(&a, ta);
    cq_theta(&b, tb);
    int *p = (x > k) ? &a : &b;              /* which register is meant is quantum */
    *p += 1;                                 /* read-modify-write through the quantum pointer */
    bump(p);                                 /* and again through a callee that receives it */
    return cq_measure(a) + cq_measure(b);
}
int guarded_field_store(int x0, double th, int k, int y0, double ty, int c, int i) {
    int x = x0, y = y0;
    cq_theta(&x, th);
    cq_theta(&y, ty);
    struct pair s[2] = {{c, 7}, {c + 1, 8}};    /* classical index i keeps s in memory at -O1 */
    if (x > k)
        s[i].f = (y > c) ? y * 3 : y - c;      /* an in-arm select feeds a guarded store into a field */
    return cq_measure(s[0].f + s[1].f + s[i].g);
}
