/* Linux <linux/if_tun.h>: only the constants temu.c's tun_open uses */
#include <net/if.h>
#define IFF_TAP 0x0002
#define IFF_NO_PI 0x1000
#define TUNSETIFF _IOW('T', 202, int)
