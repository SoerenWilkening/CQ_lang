int h(int a, int k) { volatile int z; int acc = 0; for (int i = 0; i < 3; i++) acc += a; z = acc; return k + 1; }
