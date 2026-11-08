/* tests/replay (cq-kcn5i): run argv[1..] with ASLR off (posix_spawn _POSIX_SPAWN_DISABLE_ASLR), so that two runs of one
 * program hold the same addresses; the exit status (or signal) passes through. */
#include <signal.h>
#include <spawn.h>
#include <stdio.h>
#include <sys/wait.h>
extern char **environ;
int main(int argc, char **argv) {
  if (argc < 2) return 2;
  posix_spawnattr_t a;
  posix_spawnattr_init(&a);
  posix_spawnattr_setflags(&a, 0x100);
  pid_t pid;
  if (posix_spawn(&pid, argv[1], NULL, &a, argv + 1, environ) != 0) { perror("noaslr"); return 98; }
  int st;
  while (waitpid(pid, &st, 0) < 0) {}
  if (WIFSIGNALED(st)) { signal(WTERMSIG(st), SIG_DFL); raise(WTERMSIG(st)); return 128 + WTERMSIG(st); }
  return WEXITSTATUS(st);
}
