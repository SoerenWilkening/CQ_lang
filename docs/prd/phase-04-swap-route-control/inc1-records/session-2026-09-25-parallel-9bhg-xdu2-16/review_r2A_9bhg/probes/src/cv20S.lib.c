static const int T[8] = {3,1,4,1,5,9,2,6};
int h(int a, int k) { return T[a & 7] + k; }
