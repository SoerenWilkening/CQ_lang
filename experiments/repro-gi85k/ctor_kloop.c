// cq-gi85k: a static constructor's loop whose exit test reads the bus (SD[t]) is a rule-14 K-loop in the lowered
// module: at K = 4 it runs 4 trips and keeps a_K = 1 (T[0] = 30, not 254). The C oracle ran a constructor in the
// specialization id last stored (none for the first: 0; for a later one: what the previous constructor's last call
// stored), so it ran the loop uncapped and compared the uncapped T against the capped one. Fixed in checker/oracle/cqo_rt.c
// and checker/cqcheck/oracle.py: each constructor enters its entry specialization (__cqo_ctor_enter), and a cap inside the
// constructors is every sample's, at its start (CR §6 horizon). `first` is a constructor before `init` whose call
// stored id 0 (Stockfish: __cxx_global_var_init's __cxa_guard_acquire before Bitboards::init's constructor).
// Run:  experiments/repro-gi85k/chk.sh ctor_kloop.c
// Expected: "cqcheck user: PASS: §6-equal to the C program on every compared sample (2 compared)"
// (before the fix: "memory output T differs at byte 0: ours 30 != 254").
typedef unsigned long long U64;
unsigned char SD[64];
U64 T[8];
int G;
int getpid(void);
__attribute__((constructor(101))) static void first(void){ G = getpid() > 0; }
__attribute__((constructor(102))) static void init(void){
  for(int a=0;a<64;a++) SD[a]=a&7;
  for(int s=0;s<8;s++){U64 a=0; int t=s; while(SD[t]<7){t++; a|=1ULL<<t;} T[s]=a;}
}
int f(int x){cq_theta(&x,0.5); return x + (int)T[0] + G;}
