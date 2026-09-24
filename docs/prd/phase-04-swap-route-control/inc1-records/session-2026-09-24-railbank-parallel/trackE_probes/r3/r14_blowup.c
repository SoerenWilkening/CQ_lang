#include <stdlib.h>
__attribute__((noinline)) int f0(int k){return k*3+1;}
__attribute__((noinline)) int f1(int k){return f0(k+0)+f0(k+1)+f0(k+2)+f0(k+3)+f0(k+4)+f0(k+5)+f0(k+6)+f0(k+7)+f0(k+8)+f0(k+9)+f0(k+10)+f0(k+11);}
__attribute__((noinline)) int f2(int k){return f1(k+0)+f1(k+1)+f1(k+2)+f1(k+3)+f1(k+4)+f1(k+5)+f1(k+6)+f1(k+7)+f1(k+8)+f1(k+9)+f1(k+10)+f1(k+11);}
__attribute__((noinline)) int f3(int k){return f2(k+0)+f2(k+1)+f2(k+2)+f2(k+3)+f2(k+4)+f2(k+5)+f2(k+6)+f2(k+7)+f2(k+8)+f2(k+9)+f2(k+10)+f2(k+11);}
__attribute__((noinline)) int f4(int k){return f3(k+0)+f3(k+1)+f3(k+2)+f3(k+3)+f3(k+4)+f3(k+5)+f3(k+6)+f3(k+7)+f3(k+8)+f3(k+9)+f3(k+10)+f3(k+11);}
__attribute__((noinline)) int f5(int k){return f4(k+0)+f4(k+1)+f4(k+2)+f4(k+3)+f4(k+4)+f4(k+5)+f4(k+6)+f4(k+7)+f4(k+8)+f4(k+9)+f4(k+10)+f4(k+11);}
__attribute__((noinline)) int f6(int k){return f5(k+0)+f5(k+1)+f5(k+2)+f5(k+3)+f5(k+4)+f5(k+5)+f5(k+6)+f5(k+7)+f5(k+8)+f5(k+9)+f5(k+10)+f5(k+11);}
__attribute__((noinline)) int f7(int k){return f6(k+0)+f6(k+1)+f6(k+2)+f6(k+3)+f6(k+4)+f6(k+5)+f6(k+6)+f6(k+7)+f6(k+8)+f6(k+9)+f6(k+10)+f6(k+11);}
__attribute__((noinline)) int f8(int k){return f7(k+0)+f7(k+1)+f7(k+2)+f7(k+3)+f7(k+4)+f7(k+5)+f7(k+6)+f7(k+7)+f7(k+8)+f7(k+9)+f7(k+10)+f7(k+11);}
__attribute__((noinline)) static int slice(int m, int n) {
  int q = cq_theta(0, 0.5); int a = 7;
  if ((q > 1) & (f8(m) == n)) a += 3;
  return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }