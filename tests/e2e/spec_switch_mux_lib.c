/* spec_switch_mux_lib.c — the CLASSICAL library TU for the bd p3kd.7.1 golden.
   Compiles WITHOUT CQ.h. Two helpers whose bodies `scanBody` refused before bd
   p3kd.7.1 although the clone path lowers them:

     smux: an exhaustive `switch (x & 3)`. clang -O1 keeps the `switch` with an
           `unreachable` default (all four cases are written) and folds the
           case-0 constant into the merge phi: the atan2-family shape.
     cmux: `x > 5 ? 7 : 9`, an integer select with two constant arms: the
           exp/expf/tgammal shape (`select i1 %c, i32 C1, i32 C2`). */
int smux(int x) {
    switch (x & 3) {
    case 0:
        return 3;
    case 1:
        return x + 4;
    case 2:
        return x * 5;
    default:
        return x - 1;
    }
}

int cmux(int x) { return x > 5 ? 7 : 9; }
