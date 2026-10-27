/* Test-only helpers of mock_core.c (cq-w0-rt-mem). */
#ifndef RT_MEM_MOCK_CORE_H_
#define RT_MEM_MOCK_CORE_H_
#include <stdint.h>

#include "cqe.h"

int mock_dispatch(const char *op, const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out);
cqe_op_fn mock_handler(const char *op);
int mock_fails(void);
const char *mock_last_fail(void);
int mock_known(int32_t h);
void mock_free(int32_t h);
uint64_t *mock_words(int32_t h);

#endif
