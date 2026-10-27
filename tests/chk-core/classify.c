/* tests/chk-core: reads "sym|ret|t0,t1,..." lines (a runtime declaration) and checks that the
 * dispatcher routes the symbol (core gate, template, family) and, for a template, that the name's
 * handle/literal layout fits the declared parameter types. Prints "FAIL <line>: <why>" per
 * failure and "routed <n> failed <m>" at the end; exit 1 if any failed. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

int cqe__classify(const char *sym, char *cls, size_t ncls);
int cqe__template_layout(const cqe_tname *t, int nf, char *mask);

int main(void) {
  char line[4096];
  int n = 0, bad = 0;
  while (fgets(line, sizeof line, stdin)) {
    line[strcspn(line, "\n")] = 0;
    if (!*line)
      continue;
    char *sym = line, *ret = strchr(line, '|');
    if (!ret) {
      printf("FAIL %s: no '|'\n", line);
      ++bad;
      continue;
    }
    *ret++ = 0;
    char *params = strchr(ret, '|');
    if (!params) {
      printf("FAIL %s: no params\n", sym);
      ++bad;
      continue;
    }
    *params++ = 0;
    char *ty[64];
    int nt = 0;
    for (char *p = strtok(params, ","); p && nt < 64; p = strtok(NULL, ","))
      ty[nt++] = p;
    char cls[64];
    ++n;
    if (cqe__classify(sym, cls, sizeof cls)) {
      printf("FAIL %s: not routed\n", sym);
      ++bad;
      continue;
    }
    if (!strncmp(cls, "template:", 9)) {
      cqe_tname t;
      cqe_parse_template(sym, &t);
      int off = t.unc ? 1 : 0;
      char mask[70];
      if (cqe__template_layout(&t, nt - off, mask)) {
        printf("FAIL %s: %d forward args do not fit the name\n", sym, nt - off);
        ++bad;
        continue;
      }
      if (t.unc ? (strcmp(ret, "void") || nt < 1 || strcmp(ty[0], "i32")) : strcmp(ret, "i32")) {
        printf("FAIL %s: return/out convention (%s)\n", sym, ret);
        ++bad;
        continue;
      }
      for (int i = 0; i < nt - off; ++i)
        if (mask[i] == 'h' && strcmp(ty[off + i], "i32")) {
          printf("FAIL %s: handle arg %d declared %s\n", sym, i, ty[off + i]);
          ++bad;
          break;
        }
    }
  }
  printf("routed %d failed %d\n", n - bad, bad);
  return bad ? 1 : 0;
}
