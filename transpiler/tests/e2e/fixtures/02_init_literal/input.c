#define quantum __attribute__((annotate("quantum")))

int main(void) {
    quantum int x = 5;
    return 0;
}
