/* The lowered side of fx_call.h: a direct host call, logged in the evaluator's trace. */
void cqe_log(const char *json_object);
#define FX_LOG(line, n) ((void)(n), cqe_log(line))
#include "fx_call.h"
