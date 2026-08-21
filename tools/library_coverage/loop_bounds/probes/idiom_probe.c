/* (b) three spellings of the SAME bit-scan, to find which one LLVM's
 * LoopIdiomRecognize will turn into llvm.ctlz. */
int openlibm_form(int hx) {           /* s_ilogbf.c:35 verbatim shape */
  int ix;
  for (ix = -126, hx <<= 8; hx > 0; hx <<= 1) ix -= 1;
  return ix;
}
int ne_zero_shr_form(unsigned x) {    /* LLVM's documented ctlz idiom shape */
  int i = 0;
  while (x != 0) { x >>= 1; i++; }
  return i;
}
int mask_form(unsigned manh) {        /* s_ilogbl.c:41 verbatim shape */
  unsigned long m = 1ul << 31; int b = 0;
  while (!(manh & m)) { m >>= 1; b++; }
  return b;
}
