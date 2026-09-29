#include <stddef.h>
__attribute__((noinline)) int f1(int a, int k) { return k + 1; }
__attribute__((noinline,regcall)) int f2(int a, int k) { return k + 1; }
__attribute__((noinline,ms_abi)) int f3(int a, int k) { return k + 1; }
__attribute__((noinline,vectorcall)) int f4(int a, int k) { return k + 1; }
__attribute__((noinline)) int f5(_Bool a, short s, signed char c, int k) { return k + 1; }
__attribute__((noinline)) long double f6(long double a, long double k) { return k + 1; }
__attribute__((noinline)) int f7(__int128 a, int k) { return k + 1; }
__attribute__((noinline)) _Float16 f8(_Float16 a, _Float16 k) { return k + 1; }
__attribute__((noinline)) int f9(int a __attribute__((annotate("x"))), int k) { return k + 1; }
__attribute__((noinline,preserve_most)) int f10(int a, int k) { return k + 1; }
__attribute__((noinline,swiftcall)) int f11(int a, int k) { return k + 1; }
__attribute__((noinline)) int f12(int a, int k) { return a; }
__attribute__((noinline)) float f13(float a, float k) { return k + 1; }
static __attribute__((noinline)) int f14(int a, int k) { return k + 1; }
__attribute__((noinline)) int f15(unsigned _BitInt(9) a, int k) { return k + 1; }
int use(int x, int y) { return f1(x,y)+f2(x,y)+f3(x,y)+f4(x,y)+f5(x,x,x,y)+(int)f6(x,y)+f7(x,y)+(int)f8(x,y)+f9(x,y)+f10(x,y)+f11(x,y)+f12(x,y)+(int)f13(x,y)+f14(x,y)+f14(3,y)+f15(x,y); }
