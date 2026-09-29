/* k07T — hand-inlined twin of k07 */
#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, 0.5); int acc = 0; for (int i = 0; i < m; i++) acc += cq_measure(q + i); q = cq_theta(q, 0.7); return acc + cq_measure(q); }
