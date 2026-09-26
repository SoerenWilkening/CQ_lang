struct S2 { int x, y; }; int h(int a, int k) { volatile struct S2 s; s.x = a; s.y = k; return k + 1; }
