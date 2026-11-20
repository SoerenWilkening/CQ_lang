/* ABC has a global `int time`; macOS's headers declare time(). The system headers come first (their guards make
 * abc.h's own includes no-ops), then ABC's `time` is renamed. No ABC source is changed. */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/time.h>
#include <sys/select.h>
#define time abc_time
