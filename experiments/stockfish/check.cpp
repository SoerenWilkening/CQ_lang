// check.cpp: the five spot functions as entries f1..f5 for the sampling checker (cqcheck user): k is the quantum input.
// The setup is a static constructor of this module; it is classical and runs before the entry in both programs.
// operator new/delete over malloc/free (cq.hpp): a bodiless operator new is a host stand-in returning null under the checker
#ifndef GEN
#include "cq.hpp"
#endif
#include <cstdio>
#include <cstring>
#include "bitboard.h"
#include "position.h"
#include "uci.h"
using namespace Stockfish;
static Position pos;
static StateInfo st;
#ifdef GEN
// Native generator (build/check/gen > build/check/posdata.inc): Position::set parses its FEN with std::istringstream,
// whose libc++ bodies are host stand-ins under the checker, so the position is set natively and shipped as bytes.
// A word that points into pos or st is written as a relocation {object, offset, target object, target offset}.
int main() {
    Bitboards::init(); Position::init();
    pos.set("r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3", false, &st);
    struct { const char *n; unsigned char *p; size_t z; } o[2] = {{"POS", (unsigned char *) &pos, sizeof pos}, {"ST", (unsigned char *) &st, sizeof st}};
    for (auto &x : o) { printf("static const unsigned char %s[] = {", x.n); for (size_t i = 0; i < x.z; i++) printf("%u,", x.p[i]); puts("};"); }
    printf("static const unsigned long REL[][4] = {");
    for (int a = 0; a < 2; a++) for (size_t i = 0; i + 8 <= o[a].z; i += 8) { unsigned char *v; memcpy(&v, o[a].p + i, 8);
        for (int t = 0; t < 2; t++) if (v >= o[t].p && v < o[t].p + o[t].z) printf("{%d,%zu,%d,%zu},", a, i, t, (size_t)(v - o[t].p)); }
    puts("{9,0,0,0}};");
}
#else
#include "posdata.inc"
static int init = (Bitboards::init(), Position::init(), memcpy((void *) &pos, POS, sizeof pos), memcpy((void *) &st, ST, sizeof st),
    [] { char *o[2] = {(char *) &pos, (char *) &st};
         for (int i = 0; REL[i][0] != 9; i++) { char *v = o[REL[i][2]] + REL[i][3]; memcpy(o[REL[i][0]] + REL[i][1], &v, 8); } }(), 0);
ENTRY long f1(unsigned char x) { unsigned char k = q(x); return popcount(attacks_bb<QUEEN>(Square(k & 63), pos.pieces())); }
ENTRY long f2(unsigned char x) { unsigned char k = q(x);
    return pos.pseudo_legal(Move(SQ_F3, Square(k & 63))) + 2 * pos.pseudo_legal(Move(SQ_F1, Square(k & 63))); }
ENTRY long f3(unsigned char x) { unsigned char k = q(x); return pos.see_ge(Move(SQ_F3, SQ_E5), int(k) - 100); }
ENTRY long f4(unsigned char x) { unsigned char k = q(x); return UCIEngine::to_cp(Value(int(k) * 3 - 200), pos); }
ENTRY long f5(unsigned char x) { unsigned char k = q(x); return popcount(pos.attackers_to(Square(k & 63), pos.pieces())); }
// libc++'s abort hook is variadic and has no body in the module; the checker cannot call a variadic host function.
namespace std { inline namespace __1 { [[noreturn]] void __libcpp_verbose_abort(const char *, ...) { __builtin_abort(); } } }
#endif
