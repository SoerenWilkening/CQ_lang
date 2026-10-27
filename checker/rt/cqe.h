/* Frozen interface (cq-arch). Changes only under cq-arch's freeze rule. */
#ifndef CQE_H_
#define CQE_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* checker/rt/cqe.h (C17, linked with the program under test) */
typedef struct { uint32_t bits; char kind; uint32_t nw; uint64_t *w; } cqe_val;   /* 'i' or 'f', little-endian words */
typedef struct { char op[24], pred[8], w[8], to[8], shape[8]; uint8_t rm, exc, strided, unc; } cqe_tname;
int     cqe_parse_template(const char *sym, cqe_tname *out);
typedef int (*cqe_op_fn)(const cqe_tname *, const cqe_val *args, int nargs, cqe_val *out);
void    cqe_register_op(const char *op, cqe_op_fn);   /* a family registers from a constructor */
int32_t cqe_new_rail(const char *w, const cqe_val *init, int known);
const cqe_val *cqe_rail(int32_t h);
void    cqe_xor_into(int32_t h, const cqe_val *v);
void    cqe_set_known(int32_t h, int known);
void    cqe_log(const char *json_object);              /* one trace line */
void    cqe_fail(const char *fmt, ...);                /* a violation: logged, run marked failed */

#ifdef __cplusplus
}
#endif

#endif /* CQE_H_ */
