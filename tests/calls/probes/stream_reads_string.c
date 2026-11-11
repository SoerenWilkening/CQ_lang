/* tests/calls probe, cq-xdscs (rule 16, BACKEND_ABI §1.11): stream calls by name that READ a string whose first byte is
   quantum, their results unread (so no stated deviation excuses them): deferred effect entries. Each is performed at the
   end of the shot on the measured string, which it reads up to its first 0 byte: on x0 = 0 the string is "" although the
   capture runs on to the first HOST 0. */
#include <stdio.h>
int stream_reads_string(signed char x0) {
  char s[16] = {0};
  s[1] = 'a', s[2] = 'b';
  s[0] = x0;
  cq_theta(&s[0], 0.3);
  perror(s);
  puts(s);
  return 0;
}
