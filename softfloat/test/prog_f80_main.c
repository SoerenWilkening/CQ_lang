/* The host main of the f80 link test. */
#include <stdio.h>
long double g_a(long double); long long g_b(long double);
int main(void) { printf("%.21Lg %lld\n", g_a(2.0L), g_b(2.0L)); return 0; }
