/* cq-o4ul: a batch driver (run.py's SHOT_BEFORE/SHOT_AFTER around each record). Records with mode 1
 * raise SIGFPE: the worker ends and the server forks a fresh one, which must take a copy of the stack
 * above the driver's call (core.c, shots) of its own, never the block the previous worker allocated
 * (core.c checks it: a stale copy ends the runner with status 98 before the record).
 * Records with mode 2 also take blocks of the system heap past the sample arena, as a C library
 * routine called in a sample does, and fill them: a stale stack copy lying in the system heap of
 * the new worker would be overwritten and put back over the driver's stack.
 * argv[1]: the modes, one digit per record (default "01210"). Each record that returns logs a mark
 * with its index. */
#include <setjmp.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <malloc/malloc.h>

sigjmp_buf *cqe__shot_jb(void);
int cqe__shot_enter(int idx);
void cqe__shot_end(void);
void cqe__shot_resume(void);
void cqe_log(const char *json_object);

int main(int argc, char **argv) {
  const char *modes = argc > 1 ? argv[1] : "01210";
  int n = (int)strlen(modes);
  for (int cqd_idx = 0; cqd_idx < n; ++cqd_idx) {
    const int CQD_SAMPLE = cqd_idx;
    if (sigsetjmp(*cqe__shot_jb(), 1) != 0)
      cqe__shot_resume();
    else if (cqe__shot_enter(CQD_SAMPLE)) {
      if (modes[cqd_idx] == '1')
        raise(SIGFPE);
      if (modes[cqd_idx] == '2')
        for (size_t sz = 256; sz <= 32768; sz += 256)
          for (int k = 0; k < 4; ++k)
            memset(malloc_zone_malloc(malloc_default_zone(), sz), 0xab, sz);
      char m[64];
      snprintf(m, sizeof m, "{\"ev\":\"mark\",\"i\":%d}", cqd_idx);
      cqe_log(m);
      cqe__shot_end();
    }
  }
  return 0;
}
