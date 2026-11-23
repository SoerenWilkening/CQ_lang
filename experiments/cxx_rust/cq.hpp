// The experiment's header: the driver's cq.hpp, operator new/delete over malloc/free as source (unless CQ_NO_NEW), and
// the two helpers the programs use.
#pragma once
#include "../../driver/cq.hpp"
#ifndef CQ_NO_NEW
// The C++ runtime's allocation functions as source (a program may replace them): over malloc/free, which the pass knows (rule 16).
#include <cstddef>
#include <new>
extern "C" { void *malloc(size_t); void free(void *); void *aligned_alloc(size_t, size_t); }
void *operator new(size_t n) { return malloc(n); }
void *operator new[](size_t n) { return malloc(n); }
void *operator new(size_t n, std::align_val_t a) { return aligned_alloc((size_t)a, n); }
void operator delete(void *p) noexcept { free(p); }
void operator delete[](void *p) noexcept { free(p); }
void operator delete(void *p, size_t) noexcept { free(p); }
void operator delete[](void *p, size_t) noexcept { free(p); }
void operator delete(void *p, std::align_val_t) noexcept { free(p); }
void operator delete(void *p, size_t, std::align_val_t) noexcept { free(p); }
#endif
// q(v): v made quantum, the one-line form the programs here use.
template <class T> inline __attribute__((always_inline)) T q(T v) { cq_theta(&v, 0.5); return v; }
#define ENTRY extern "C" 
