/* drv.c: a program linked against the lowered TinyCC library (build_lib.sh): tcc_basename on a path with one quantum
 * character, calling the library's clone. */
char *tcc_basename(const char *name);
int main(void) {
    char s[9] = "ab/cd/ef";
    unsigned char q = 0;
    cq_theta(&q, 0.5);
    s[7] = (q & 1) ? '/' : 'f';
    return (int)cq_measure((long)(tcc_basename(s) - s));
}
