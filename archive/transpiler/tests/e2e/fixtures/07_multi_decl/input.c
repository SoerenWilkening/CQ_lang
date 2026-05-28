#define quantum __attribute__((annotate("quantum")))

int main(void) {
    quantum int a = 3, b = 2;
    return 0;
}
