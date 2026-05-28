#define quantum __attribute__((annotate("quantum")))

int main(void) {
    quantum int a = 3;
    quantum int d = a + 5;
    return 0;
}
