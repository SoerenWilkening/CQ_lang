#!/bin/bash
# writes probe programs pN.c from a body template (scratch)
cd "$(dirname "$0")"
mk() { # name  decls  body  ret
cat > $1.c <<EOF
#include <stdlib.h>
static const int tbl[8] = {3,1,4,1,5,9,2,6};
__attribute__((noinline)) static int slice(int n, int m) {
$2
$3
    return $4;
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }
EOF
}
mk p1 "int q = cq_theta(0, 0.25); int a = 0, z = 0;" "for (int i = 0; i < n && i < 8; ++i) if (q && m == n) { a += tbl[i]; z -= tbl[i]; }" "cq_measure(q) + cq_measure(a) + cq_measure(z)"
mk p2 "int q = cq_theta(0, 0.25); int a = 7;" "if (q && m == n) a += 3;" "cq_measure(q) + cq_measure(a)"
mk p3 "int q = cq_theta(0, 0.25); int a = 7;" "if (m == n && q) a += 3;" "cq_measure(q) + cq_measure(a)"
mk p4 "int q = cq_theta(0, 0.25); int a = 7;" "if (q || m == n) a += 3;" "cq_measure(q) + cq_measure(a)"
mk p5 "int q = cq_theta(0, 0.25); int a = 0;" "for (int i = 0; i < n; ++i) if (q && i < m) a += tbl[i & 7];" "cq_measure(q) + cq_measure(a)"
mk p6 "int q = cq_theta(0, 0.25);" "if (q && m == n) cq_phi(0.5);" "cq_measure(q)"
mk p7 "_Bool b = cq_theta((_Bool)0, 0.5); int a = 7;" "if (b && m == n) a += 3;" "cq_measure(b) + cq_measure(a)"
mk p8 "int q = cq_theta(0, 0.25); int a = 7;" "if (q > 2 && m == n && n > 3) a += 3;" "cq_measure(q) + cq_measure(a)"
mk p9 "int q = cq_theta(0, 0.25); int a = 7;" "if ((q > 2) != (m == n)) a += 3;" "cq_measure(q) + cq_measure(a)"
mk p10 "int q = cq_theta(0, 0.25); int a = 7;" "a = (q && m == n) ? a + 3 : a - 1;" "cq_measure(q) + cq_measure(a)"
mk p11 "int q = cq_theta(0, 0.25); int a = 0;" "for (int i = 0; i < n; ++i) if (q && m == n) a += 3;" "cq_measure(q) + cq_measure(a)"
mk p12 "int q = cq_theta(0, 0.25); int a = 0;" "for (int i = 0; i < n; ++i) if (q) a += 3;" "cq_measure(q) + cq_measure(a)"
mk p13 "int q = cq_theta(0, 0.25); int a = 0;" "for (int i = 0; i < n; ++i) if (q && i < m) a += 3;" "cq_measure(q) + cq_measure(a)"
mk p14 "int q = cq_theta(0, 0.25); int a = 0;" "for (int i = 0; i < n && i < 8; ++i) if (q) a += tbl[i];" "cq_measure(q) + cq_measure(a)"
mk p15 "int a = 0;" "for (int i = 0; i < n; ++i) { int q = cq_theta(0, 0.25); if (q && m == n) a += 3; }" "cq_measure(a)"
mk p16 "int a = 0;" "for (int i = 0; i < n; ++i) { int q = cq_theta(i, 0.25); if (q > 1 && i < m) a += 3; a = cq_measure(a); }" "a"
mk p17 "int q = cq_theta(0, 0.25); int a = 0;" "for (int i = 0; i < n; ++i) if (q > 1 && q < 5) a += 3;" "cq_measure(q) + cq_measure(a)"
mk p18 "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;" "for (int i = 0; i < n; ++i) if (q > 1 && r < 5) a += 3;" "cq_measure(q) + cq_measure(r) + cq_measure(a)"
mk p19 "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;" "for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3;" "cq_measure(q) + cq_measure(r) + cq_measure(a)"
mk p20 "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;" "for (int i = 0; i < n; ++i) if ((q > 1) & (r < i)) a += 3;" "cq_measure(q) + cq_measure(r) + cq_measure(a)"
mk p21 "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); _Bool f = 0; int a = 7;" "if (q > 3) f = tbl[m & 7] > n; if (f && r) a += 3;" "cq_measure(q) + cq_measure(r) + cq_measure(a) + cq_measure(f)"
mk p22 "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int f = 0; int a = 7;" "if (q > 3) f = tbl[m & 7]; if (f > n && r) a += 3;" "cq_measure(q) + cq_measure(r) + cq_measure(a) + cq_measure(f)"
