/* slice_control_cascade_two_bools_int.c — THE `int` SPELLING THE OWNER REFUSED
   (probe `m11`), pinned so the widening cannot change it.

   The flagship with `int b1` instead of `_Bool b1`. The select's condition is
   then a COMPARE over the merge phi (`icmp ne i32 %phi, 0`), not the phi itself,
   so it took the ordinary compare-leaf path and LOWERED ON THE FROZEN ORACLE —
   28 lines, STRICT 2b clean, with no Track M change.

   ⚠ IT IS HERE AS A NON-REGRESSION PIN, AND AS THE RECORD OF WHY THE WIDENING
   WAS OWED. This is the workaround the owner rejected in as many words -- "WE DO
   NOT WANT TO WRITE `int b1`. also WE DO NOT WANT ANOTHER cq function ... I dont
   see the need for the over-decline" (2026-09-11) -- so a green row here is not
   a capability claim; it is the thing whose EXISTENCE made the `_Bool` decline an
   over-decline rather than a physics wall. Read it with the flagship: same
   program, same circuit shape, one type name apart.

   Its trace differs from the flagship's in the expected way and only that way:
   the compare mints a flag, so `b1`'s register is `i32`-wide and the merge is
   controlled through the minted flag rather than through a CNOT-copy of the
   register itself. */
int slice(void) {
    int a = 5;
    _Bool b0 = 0;
    int b1 = 0;

    if (a >= 3){
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) a -= 3;

    if (a >= 3){
        b1 = cq_theta(b1, 0.5);
    }
    if (b1) a -= 3;

    return (int) cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
