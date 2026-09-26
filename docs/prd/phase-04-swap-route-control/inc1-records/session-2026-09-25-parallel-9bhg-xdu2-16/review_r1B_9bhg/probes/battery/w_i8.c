#include <stdlib.h>
char hw(char a, char k);
__attribute__((noinline)) char fw(char m) { char q = cq_theta(m, .5); return hw(q, m); }
int main(int argc, char **argv) { char m = (char)atoi(argv[1]); char n = (char)atoi(argv[2]); char q2 = cq_theta(n, .25); char u = q2 + fw(m); return (int)cq_measure(u); }
