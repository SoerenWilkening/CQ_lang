int gx(int a, int b) { return ((a * 2) + 7) ^ b; }
int gy(int a, int b) { int c = a * 5; int d = c - 3; int e = d << 2; return (e | 1) + b; }
int gz(int a, int b) { long long x = (long long)a * 3000000001LL; return (int)(x >> 29) + b; }
int gc(int a, int b) { int t = a > 10 ? a * 3 : a - 4; return t + b; }
int gk(int a, int b) { return a * 7 + 1; }
int gm(int a, int b) { unsigned u = (unsigned)a; return (int)(u / 3u) + b; }
