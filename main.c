#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <math.h>
typedef struct qint {
  int *qubits;
  unsigned int num_bits;
  int64_t value;
  uint64_t mask;
  bool is_unsigned;
} qint_t;

/*
 * qint_t is a general structure
 * set num_bits to:
 * 1 for "quantum bool"
 * 8 for "quantum char"
 * 16 for "quantum short" or "quantum int"
 * 32 for "quantum long"
 * 64 for "quantum long long"
 *
 * "value" stores a classical value. here are also measurement results stored
 *  -> if "a = measure(b) // b is quantum int"
 *  -> the perform a | b.value to get full outcome
 *  -> REASON: quantum-classical hybrid data representation
 * "mask" is a bitmask storing which bits are in superposition or not
 * */

#define quantum __attribute__((annotate("quantum")))

#define phi(a) return a;
#define theta(a) return a;

int func(int a) {
    return a + 3;
}

int ipow(int a, int b){
    int res = a;
    for (int i = 0; i < b - 1; i++){
        res *= a;
    }
    return res;
}

int main(void) {
    
    quantum int a = 3, b = 2;
    quantum int c = a ^ b;
    int N = 3;
    
    quantum double d = 3;
    
    ipow(a, 5);
    pow(d, 5.);
    
    // qint d = pow_qint(a, 5);
    // mod_qint(d, N);
    
    // -O3
    // d = pow_mod(a, 5, N);
    
    if (c == 3) {
        phi(a) + 3;
    }
}
