void sink(volatile int *p);
int h(int a, int k) { volatile int z = a; sink(&z); return k + 1; }
