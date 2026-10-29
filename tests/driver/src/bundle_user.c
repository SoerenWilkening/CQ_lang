/* Calls two symbols the version 1 injection bundle defines (memcmp, logb): with a non-empty manifest
   cqcc links their bodies in (cq-jxaw); with the empty stub they stay declarations. */
#include <math.h>
#include <string.h>

int bundle_user(const char *a, const char *b, double x) {
    return memcmp(a, b, 4) + (int)logb(x);
}
