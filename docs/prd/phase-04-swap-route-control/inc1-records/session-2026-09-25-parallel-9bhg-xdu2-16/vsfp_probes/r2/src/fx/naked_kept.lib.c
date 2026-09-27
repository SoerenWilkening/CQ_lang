__attribute__((naked, noinline)) int ident(int a) { __asm__("movl %edi, %eax\n\tret"); }
