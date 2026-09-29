/* f2 is an external here: -O1 keeps the unused call and infers nothing. */
int f2(int a);
void g(int a) { f2(a); }
