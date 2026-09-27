__attribute__((naked, noinline)) int ident(int a) { __asm__("movl %edi, %eax\n\tret"); }
__attribute__((noinline)) int ident2(int a) { return 7; }
int use(int m) { return ident(m * 3) + ident2(m * 5); }
