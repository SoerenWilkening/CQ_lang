#pragma clang section bss="__DATA,__mybss" rodata="__TEXT,__myro"
static volatile int Z;
static const volatile double R = 1e300;
int f(void) { return Z + (int)R; }
