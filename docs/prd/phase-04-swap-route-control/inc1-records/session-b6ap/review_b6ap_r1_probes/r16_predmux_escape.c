/* Does PredMux (which also mints tainted selects AFTER declineTaintEscapes)
   have the same escape hole?  If the ORACLE accepts this, finding 1 is a
   PRE-EXISTING class the peel joins; if it declines, the peel introduces it. */
#include <stdio.h>
int g_probe;
int main(void) {
    int b0 = cq_theta(0, 0.5);
    int r = b0 + 1;
    int s = 0;
    if (b0 == 1) { r = r * 3 + 1; s = 4; }
    g_probe = s;
    printf("%d %d %d\n", cq_measure(b0), cq_measure(r), g_probe);
    return 0;
}
