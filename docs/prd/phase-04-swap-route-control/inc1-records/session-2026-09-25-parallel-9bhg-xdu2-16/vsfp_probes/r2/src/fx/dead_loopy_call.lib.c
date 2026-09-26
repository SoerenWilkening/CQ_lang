int h(int a, int k) { volatile int z = a; unsigned x = (unsigned)k; while (x != 7u) x = x * 3u + 1u; return (int)x; }
