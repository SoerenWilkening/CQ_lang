/* The lowered side of fx_call.h: a direct host call, logged in the evaluator's trace. */
void cqe_log(const char *json_object);
#define FX_LOG(line, n) ((void)(n), cqe_log(line))
/* rulings Q2 (owner 2026-11-11): an ordinary host call given a pointer into an object holding a QUANTUM cell (rt_bus.c) */
void cqe__q2_check(const char *name, unsigned long long a);
#define FX_PTR_HOOK(name, p) cqe__q2_check((name), (unsigned long long)(__UINTPTR_TYPE__)(p))
#include "fx_call.h"
