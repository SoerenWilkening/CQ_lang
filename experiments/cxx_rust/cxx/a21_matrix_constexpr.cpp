#include "cq.hpp"
template <int N> struct M { int a[N][N]; constexpr M operator*(const M &o) const { M r{}; for (int i = 0; i < N; i++) for (int j = 0; j < N; j++) for (int k = 0; k < N; k++) r.a[i][j] += a[i][k] * o.a[k][j]; return r; } };
ENTRY int f(int x, int y) { M<2> m{{{1, q(x)}, {1, y}}}; auto r = m * m * m; return r.a[0][0] + r.a[1][1] + r.a[0][1]; }
