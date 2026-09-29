/* n04 lib — a lib-internal call (inlined by -O1 in the lib TU) */
int h(int a, int k) { return k + 1; }
int g(int a, int k) { return h(a, k) * 2; }
