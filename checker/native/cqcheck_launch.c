/* The cqcheck launcher (cq-8m6v step 6, owner option b): `cqcheck <args>` is `python3 -m cqcheck <args>`
 * without the pyenv shim's start and without site-packages (the checker needs only the standard
 * library): it execs the real interpreter recorded at build time (CQ_PY) with -S and the checker's
 * directory (CQ_CHECKER) first on sys.path. No daemon: the run is this process, inside whatever
 * process group started it (heavy.sh). Built by cqcheck.native.launcher into the tool cache. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef CQ_PY
#error "CQ_PY: the interpreter's path"
#endif
#ifndef CQ_CHECKER
#error "CQ_CHECKER: the checker directory"
#endif

int main(int argc, char **argv) {
  static const char boot[] = "import sys; sys.argv[0] = 'cqcheck'; sys.path.insert(0, " CQ_CHECKER "); "
                             "from cqcheck.cli import main; sys.exit(main())";
  char **v = calloc((size_t)argc + 4, sizeof *v);
  if (!v)
    return 99;
  int k = 0;
  v[k++] = CQ_PY;
  v[k++] = "-S";
  v[k++] = "-c";
  v[k++] = (char *)boot;
  for (int i = 1; i < argc; ++i)
    v[k++] = argv[i];
  v[k] = NULL;
  execv(CQ_PY, v);
  perror("cqcheck: exec " CQ_PY);
  return 98;
}
