/* r1A probe A3 depth 6: width-2 DAG of out-of-line callees (a_i, b_i), each reading its
   formal through BOTH next-level clones -- linear program size, 4^D proof-walk paths. */
__attribute__((noinline)) int a6(int k) { return k + 1; }
__attribute__((noinline)) int b6(int k) { return k + 3; }
__attribute__((noinline)) int a5(int k) { return a6(k) ^ b6(k); }
__attribute__((noinline)) int b5(int k) { return a6(k) + b6(k); }
__attribute__((noinline)) int a4(int k) { return a5(k) ^ b5(k); }
__attribute__((noinline)) int b4(int k) { return a5(k) + b5(k); }
__attribute__((noinline)) int a3(int k) { return a4(k) ^ b4(k); }
__attribute__((noinline)) int b3(int k) { return a4(k) + b4(k); }
__attribute__((noinline)) int a2(int k) { return a3(k) ^ b3(k); }
__attribute__((noinline)) int b2(int k) { return a3(k) + b3(k); }
__attribute__((noinline)) int a1(int k) { return a2(k) ^ b2(k); }
__attribute__((noinline)) int b1(int k) { return a2(k) + b2(k); }
__attribute__((noinline)) int a0(int k) { return a1(k) ^ b1(k); }
__attribute__((noinline)) int b0(int k) { return a1(k) + b1(k); }
int h(int a, int k) { return a0(k); }
