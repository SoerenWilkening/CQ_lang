/* h04 — the merge %out ESCAPES via `return` (never measured). */
#include "CQ.h"
int slice(void){ bool b=0; b=cq_theta(b,0.5); return b?2:5; }
int main(void){ return slice(); }
