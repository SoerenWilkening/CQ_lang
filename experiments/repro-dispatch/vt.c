struct Shape; struct VT { int (*area)(const struct Shape *, int); };
struct Shape { const struct VT *vt; int a, b; };
static int sq(const struct Shape *s, int k) { return s->a * s->a + k; }
static int rect(const struct Shape *s, int k) { return s->a * s->b - k; }
static const struct VT VS = {sq}, VR = {rect};
__attribute__((noinline)) int total(const struct Shape *const *s, int n, int k) { int t = 0; for (int i = 0; i < n; i++) t += s[i]->vt->area(s[i], k); return t; }
int f(int x, int y) { int qx = x, qy = y; cq_theta(&qx, 0.5); cq_theta(&qy, 0.5); struct Shape s = {&VS, qx, 0}, r = {&VR, x, y}; const struct Shape *v[2] = {&s, &r}; return total(v, 2, qy); }
