#include <stdlib.h>
__attribute__((noinline)) int f0(int k){return k*3+1;}
__attribute__((noinline)) int f1(int k){return f0(k)+1;}
__attribute__((noinline)) int f2(int k){return f1(k)+2;}
__attribute__((noinline)) int f3(int k){return f2(k)+3;}
__attribute__((noinline)) int f4(int k){return f3(k)+4;}
__attribute__((noinline)) int f5(int k){return f4(k)+5;}
__attribute__((noinline)) int f6(int k){return f5(k)+6;}
__attribute__((noinline)) int f7(int k){return f6(k)+7;}
__attribute__((noinline)) int f8(int k){return f7(k)+8;}
__attribute__((noinline)) int f9(int k){return f8(k)+9;}
__attribute__((noinline)) int f10(int k){return f9(k)+10;}
__attribute__((noinline)) int f11(int k){return f10(k)+11;}
__attribute__((noinline)) int f12(int k){return f11(k)+12;}
__attribute__((noinline)) static int slice(int m, int n) {
  int q = cq_theta(0, 0.5); int a = 7;
  if ((q > 1) & (f12(m) == n)) a += 3;
  return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }