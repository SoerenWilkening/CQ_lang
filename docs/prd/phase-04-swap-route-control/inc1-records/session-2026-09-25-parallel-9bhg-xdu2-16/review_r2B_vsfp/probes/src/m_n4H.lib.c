int in1(int a, int k) { return k + 1; }
int in2(int a, int k) { return a + k; }
int out1(int a, int b) { return in1(a, b) * 2 + a; }
int out2(int a, int b) { return in2(a, b) * 2 + b; }
int out3(int a, int b) { return in1(a, b) * 2 + b; }
