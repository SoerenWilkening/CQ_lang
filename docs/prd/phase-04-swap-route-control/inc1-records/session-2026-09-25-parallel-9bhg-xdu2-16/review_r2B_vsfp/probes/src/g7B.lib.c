int h(int a, int k) { volatile int z; switch (k) { case 1: z = a; break; case 2: z = a + 1; break; default: break; } return k + 1; }
