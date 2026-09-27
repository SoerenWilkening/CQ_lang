int h(int a, int k) { int s = 0; for (int i = 0; i < 4; i++) s += (a >> i) & 1; return s * 0 + k; }
