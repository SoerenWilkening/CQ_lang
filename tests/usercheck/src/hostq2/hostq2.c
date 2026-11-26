/* Rulings Q2 at a real host call (cq-fgyee): strlen and strchr have no body in the module and run for real on both
   sides (rule 16). Where x is odd s holds a rail at the calls (a byte that is 0 or 'x' by a qubit) and the host reads
   the host bytes, not the bus (CR 1.3): not compared. Where x is even s holds no rail and both sides read "ab/cd/ef". */
unsigned long strlen(const char *);
char *strchr(const char *, int);
long f(int x) {
    char s[9] = "ab/cd/ef";
    if (x & 1) {
        unsigned char q = 0;
        cq_theta(&q, 0.5);
        s[(x >> 1) & 7] = (q & 1) ? 0 : 'x';
    }
    return cq_measure((long)strlen(s) + (strchr(s, '/') ? 100 : 0));
}
