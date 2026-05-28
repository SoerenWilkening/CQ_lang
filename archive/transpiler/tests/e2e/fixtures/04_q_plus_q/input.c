#define quantum __attribute__((annotate("quantum")))

int main(void) {
    quantum int a = 3;
    quantum int b = 2;
    quantum int c = a + b;
    return 0;
}
