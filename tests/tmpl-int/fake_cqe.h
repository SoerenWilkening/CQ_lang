#ifndef FAKE_CQE_H_
#define FAKE_CQE_H_
#include "cqe.h"

#define FAKE_MAX_REGS 256
typedef struct { const char *op; cqe_op_fn fn; } fake_reg_t;
extern fake_reg_t fake_regs[FAKE_MAX_REGS];
extern int fake_nregs;
extern int fake_fail_count;
extern char fake_fail_last[512];
cqe_op_fn fake_lookup(const char *op);

#endif
