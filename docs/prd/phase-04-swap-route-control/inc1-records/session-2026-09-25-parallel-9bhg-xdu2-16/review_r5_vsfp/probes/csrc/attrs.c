#include <stdlib.h>
typedef _Bool B; typedef signed char SC; typedef unsigned char UC; typedef short S; typedef unsigned short US;
typedef long long LL; typedef __int128 I128; typedef long double LD; typedef _Float16 H;
#define F(T,n) __attribute__((noinline)) int f_##n(T a, int k) { return k + 1; } \
  static __attribute__((noinline)) int s_##n(T a, int k) { return k * 2; } \
  __attribute__((noinline)) int u_##n(T a, int k) { return (int)a + k; }
F(B,b) F(SC,sc) F(UC,uc) F(S,s) F(US,us) F(int,i) F(unsigned,u) F(LL,ll) F(I128,i128) F(float,f) F(double,d) F(LD,ld) F(H,h)
volatile int sink;
int main(int c, char **v) { int m = atoi(v[1]);
#define C(T,n) sink += f_##n((T)m, m) + s_##n((T)m, m) + u_##n((T)(m&1), m);
C(B,b) C(SC,sc) C(UC,uc) C(S,s) C(US,us) C(int,i) C(unsigned,u) C(LL,ll) C(I128,i128) C(float,f) C(double,d) C(LD,ld) C(H,h)
return 0; }
