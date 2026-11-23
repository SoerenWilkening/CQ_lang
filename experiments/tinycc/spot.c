/* spot.c: §6 spot checks of lowered TinyCC code. It includes the ONE_SOURCE compiler, so the entries can call its
 * static functions; each entry takes 8 quantum bits from cq_theta and measures a result. The checker cannot yet run
 * a module holding all of TinyCC (cq-4hrxi), so the entries are extracted with what they reach:
 *   clang -O1 -include ../../spec/CQ.h -Isrc -Dmain=tcc_main -S -emit-llvm spot.c -o build/spot_full.ll
 *   llvm-extract --recursive --func=spot_btype --func=spot_basename --func=spot_pstrcat \
 *       --rglob='__const\..*' --rglob='switch\.table\..*' -S build/spot_full.ll -o build/spot.ll
 *   ../../driver/cqcc -S --cq-check --cq-entry spot_basename build/spot.ll -o build/spot_basename.ll */
#include "tcc.c"

/* tcc_basename: the position of the last '/' in "ab/cd/ef", one character quantum */
long spot_basename(uint8_t pos) {
    char s[9] = "ab/cd/ef";
    uint8_t q = 0;
    cq_theta(&q, 0.5);
    s[pos % 8] = (q & 1) ? '/' : (char)('a' + (q >> 5));
    return cq_measure((long)(tcc_basename(s) - s));
}

/* pstrcat: append a string whose length is quantum to a fixed prefix, into a buffer of classical size */
long spot_pstrcat(uint8_t size) {
    char buf[16] = "tcc", add[9] = "abcdefgh";
    uint8_t q = 0;
    cq_theta(&q, 0.5);
    add[q & 7] = 0;
    pstrcat(buf, 4 + size % 12, add);
    return cq_measure((long)(strlen(buf) * 256 + (unsigned char)buf[strlen(buf) - 1]));
}

/* btype_size: the size of a basic type, the type code quantum */
long spot_btype(uint8_t base) {
    uint8_t q = 0;
    cq_theta(&q, 0.5);
    return cq_measure((long)btype_size((q + base) & VT_BTYPE));
}
