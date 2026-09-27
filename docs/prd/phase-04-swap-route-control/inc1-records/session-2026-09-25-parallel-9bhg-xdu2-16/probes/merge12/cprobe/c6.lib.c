static volatile int Z = 0;
int h(int a, int k) { return (Z ? a : 0) + k + 1; }
