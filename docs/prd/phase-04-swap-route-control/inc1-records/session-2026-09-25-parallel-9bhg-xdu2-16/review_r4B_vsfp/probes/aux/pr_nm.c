#pragma clang section data="__DATA,__mmio"
static volatile int K = 7;
#pragma clang section data=""
int f(void) { return K; }
