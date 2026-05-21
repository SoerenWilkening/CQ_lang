#define quantum __attribute__((annotate("quantum")))

int foo(int a){
    a += 3;
}

int main(void) {
    quantum int x;                  // pattern 1
    quantum int y = 5;              // pattern 2 (literal)
    int classic = 7;
    quantum int z = classic;        // pattern 2 (classical var)
    quantum int a = 3, b = 2;       // multi-decl, both pattern 2
    quantum int c = a + b;          // pattern 3 (Q + Q)
    quantum int d = a + 5;          // pattern 4 (Q + classical literal)
    quantum int e = a + classic;    // pattern 4 (Q + classical var)
    
    foo(e);
    
    return 0;
}
