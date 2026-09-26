static volatile const int K = 7; int h(int a, int k) { int r = k + 1; if (a > 3) r += K - 7; return r; }
