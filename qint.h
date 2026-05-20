/*
 * qint.h — v1 stub backend header for the Quantum-C transpiler.
 *
 * Provides the qint_t struct (copied verbatim from main.c) plus stub
 * implementations of init_qint and add. The stubs print their own name
 * for debug visibility and return a default-constructed qint_t.
 *
 * Header-only (static inline) — no companion .c is required.
 */

#ifndef QINT_H
#define QINT_H

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct qint {
    int *qubits;
    unsigned int num_bits;
    int64_t value;
    uint64_t mask;
    bool is_unsigned;
} qint_t;

/* Marker function declarations — not used by v1 rewrites, but declared
 * so user source referencing them still compiles. */
int amplitude(int);
int phase(int);

static inline qint_t init_qint(int64_t value, unsigned num_bits) {
    printf("init_qint(%lld, %u)\n", (long long)value, num_bits);
    return (qint_t){
        .qubits = NULL,
        .num_bits = num_bits,
        .value = value,
        .mask = 0,
        .is_unsigned = false,
    };
}

static inline qint_t add(qint_t a, qint_t b) {
    (void)a;
    (void)b;
    printf("add\n");
    return (qint_t){
        .qubits = NULL,
        .num_bits = 0,
        .value = 0,
        .mask = 0,
        .is_unsigned = false,
    };
}

#endif /* QINT_H */
