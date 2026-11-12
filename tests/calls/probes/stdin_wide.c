/* tests/calls probe, ruling Q5: every input call consumes from the one stream, the wide ones and gets too: fgetwc under a
   quantum predicate (nothing consumed where it reads 0), fgetws with a rail length, getwchar, then gets reads the rest of
   the line (its new-line consumed, not stored) and getwc sees end of file once the stream is gone. */
#include <stdio.h>
#include <wchar.h>
char *gets(char *);
int stdin_wide(signed char x0) {
    signed char x = x0;
    cq_theta(&x, 0.3);
    wint_t c1 = 0;
    if (x & 1)
        c1 = fgetwc(stdin);
    wchar_t w[8] = {0};
    fgetws(w, (x & 3) + 2, stdin);
    wint_t c2 = getwchar();
    char line[32] = {0};
    char *p = gets(line);
    char rest[32] = {0};
    p = gets(rest);
    p = gets(rest);
    wint_t c3 = getwc(stdin);
    return cq_measure((int)c1 * 7 + (int)w[0] * 3 + (int)w[2] * 5 + (int)c2 * 11 + line[0] + line[2] * 13 + rest[0] * 17
                      + (p != 0) * 19 + (int)c3 + x);
}
