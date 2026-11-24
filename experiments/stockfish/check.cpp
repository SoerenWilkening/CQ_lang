// check.cpp: the five spot functions as entries f1..f5 for the sampling checker (cqcheck user): k is the quantum input.
// The data (position, tables) is shipped as bytes by a native generator (-DGEN); a static constructor copies it in.
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
// Native generator (build/check/gen > build/check/posdata.inc). The checked module has no setup code: at the default K a
// lowered Bitboards::init is cut off in its first loop whose bound is loaded from a global (CR rules 3, 14; cq-gi85k),
// and Position::set parses its FEN with std::istringstream, a host stand-in under the checker. So the position, the
// state and every table the entries read are made natively and shipped as bytes; the magic tables themselves are
// constants of the module (RT, BT). A word that points into one of the objects is written as an assignment.
int main() {
    Bitboards::init(); Position::init();
    pos.set("r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3", false, &st);
    struct { const char *n, *dst; unsigned char *p; size_t z; } o[] = {
        {"POS", "&pos", (unsigned char *) &pos, sizeof pos}, {"ST", "&st", (unsigned char *) &st, sizeof st},
        {"RM", "RookMagics", (unsigned char *) RookMagics, sizeof RookMagics}, {"BM", "BishopMagics", (unsigned char *) BishopMagics, sizeof BishopMagics},
        {"PA", "PseudoAttacks", (unsigned char *) PseudoAttacks, sizeof PseudoAttacks}, {"BB", "BetweenBB", (unsigned char *) BetweenBB, sizeof BetweenBB},
        {"LB", "LineBB", (unsigned char *) LineBB, sizeof LineBB}, {"PC", "PopCnt16", (unsigned char *) PopCnt16, sizeof PopCnt16},
        {"SD", "SquareDistance", (unsigned char *) SquareDistance, sizeof SquareDistance},
        {"RT", "RT", (unsigned char *) RookMagics[0].attacks, 0x19000 * 8}, {"BT", "BT", (unsigned char *) BishopMagics[0].attacks, 0x1480 * 8}};
    const int N = sizeof o / sizeof *o, COPIED = 9;
    for (auto &x : o) { printf("alignas(8) static const unsigned char %s[] = {", x.n); for (size_t i = 0; i < x.z; i++) printf("%u,", x.p[i]); puts("};"); }
    puts("static void load_data() {");
    for (int a = 0; a < COPIED; a++) printf("    memcpy((void *) %s, %s, %zu);\n", o[a].dst, o[a].n, o[a].z);
    for (int a = 0; a < COPIED; a++) for (size_t i = 0; i + 8 <= o[a].z; i += 8) { unsigned char *v; memcpy(&v, o[a].p + i, 8);
        for (int t = 0; t < N; t++) if (v >= o[t].p && v < o[t].p + o[t].z)
            printf("    *(const char **) ((char *) %s + %zu) = (const char *) %s + %zu;\n", o[a].dst, i, o[t].dst, (size_t)(v - o[t].p)); }
    puts("}");
}
#else
#include "posdata.inc"
static int init = (load_data(), 0);
ENTRY long f1(unsigned char x) { unsigned char k = q(x); return popcount(attacks_bb<QUEEN>(Square(k & 63), pos.pieces())); }
ENTRY long f2(unsigned char x) { unsigned char k = q(x);
    return pos.pseudo_legal(Move(SQ_F3, Square(k & 63))) + 2 * pos.pseudo_legal(Move(SQ_F1, Square(k & 63))); }
ENTRY long f3(unsigned char x) { unsigned char k = q(x); return pos.see_ge(Move(SQ_F3, SQ_E5), int(k) - 100); }
ENTRY long f4(unsigned char x) { unsigned char k = q(x); return UCIEngine::to_cp(Value(int(k) * 3 - 200), pos); }
ENTRY long f5(unsigned char x) { unsigned char k = q(x); return popcount(pos.attackers_to(Square(k & 63), pos.pieces())); }
// libc++'s abort hook is variadic and has no body in the module; the checker cannot call a variadic host function.
namespace std { inline namespace __1 { [[noreturn]] void __libcpp_verbose_abort(const char *, ...) { __builtin_abort(); } } }
#endif
