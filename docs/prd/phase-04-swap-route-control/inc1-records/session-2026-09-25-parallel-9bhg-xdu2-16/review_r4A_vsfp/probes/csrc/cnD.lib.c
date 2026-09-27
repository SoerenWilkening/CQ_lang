__attribute__((noinline)) int g(int y) { return y * 3; }
int h(int b) { return g(b + 1); }
