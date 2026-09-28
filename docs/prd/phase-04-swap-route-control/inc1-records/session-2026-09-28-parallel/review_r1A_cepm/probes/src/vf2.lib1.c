/* f3 is an external here: f2 gets no memory(none)/willreturn, so a call to f2
   is a liveness ROOT of the pass. */
int f3(int a);
int f2(int a) { return f3(a) + 1; }
