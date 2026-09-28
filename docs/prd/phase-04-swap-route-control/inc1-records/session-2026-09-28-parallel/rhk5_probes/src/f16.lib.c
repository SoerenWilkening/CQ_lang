/* f16 lib — clone with a QROM read indexed by the parameter */
static const int T[8] = {3, 1, 4, 1, 5, 9, 2, 6};
int h(int a, int k) { return T[k & 7]; }
