struct Big { int x[8]; };
__attribute__((noinline)) int g(int a, struct Big s) { return a * 3; }
int h(int a, struct Big *sp) { return g(a, *sp); }
