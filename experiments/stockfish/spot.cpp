// spot.cpp: Stockfish functions on a quantum argument; the exit code is the measured result. -DSPOT=n picks the check,
// -DV=v the basis value under the rotation (angle 0: the replay backend keeps it), -DNATIVE the plain C++ program.
// -DSETUP is the classical setup, compiled natively into both builds: a static constructor fills spot_pos before main.
// It is not in the lowered module because rule 27 has no flow: once main makes a declared-clone call with a rail actual,
// every listed call in the module, Bitboards::init, Position::init and Position::set before cq_theta included, is a
// declared clone (cq-or1sa).
#define CQ_NO_NEW
#ifdef NATIVE
template <class T> void cq_theta(T *, double) {}
template <class T> T cq_measure(T x) { return x; }
#elif !defined(SETUP)
#include "cq.hpp"
#endif
#include "bitboard.h"
#include "position.h"
using namespace Stockfish;
#ifdef SETUP
Position spot_pos;
static StateInfo spot_st;
static int spot_init = (Bitboards::init(), Position::init(),
    spot_pos.set("r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3", false, &spot_st), 0);
// The engine's tables and the state are statics of native code here, which no lowered module registers (BACKEND_ABI
// 1.10, Objects); in a fully lowered program the defining module does it. The native program has no registry.
extern "C" void __cq_object(long long, long long) __attribute__((weak));
static int spot_reg = !__cq_object ? 0 :
    (__cq_object((long long) RookMagics[0].attacks, 0x19000 * 8), __cq_object((long long) BishopMagics[0].attacks, 0x1480 * 8),
     __cq_object((long long) &spot_st, sizeof spot_st), 0);
#else
#if SPOT == 4 // uci.h brings numa.h's dynamically initialized SYSTEM_THREADS_NB: only where the check needs it
#include "uci.h"
#endif
extern Position spot_pos;
#ifdef ALL  // every value of the 8-bit input in one program: prints "v result" per value, compared with the native output
#include <cstdio>
static long one(unsigned char V);
#ifndef STEP
#define STEP 1
#endif
int main() { for (int v = 0; v < 256; v += STEP) { printf("%d %ld\n", v, one((unsigned char) v)); fflush(stdout); } return 0; }
static long one(unsigned char V) {
#else
int main() {
#endif
    Position &pos = spot_pos;
    unsigned char k = V; cq_theta(&k, 0.0);
#if SPOT == 1   // header code over the engine's magic tables: queen attacks from a quantum square
    long r = popcount(attacks_bb<QUEEN>(Square(k & 63), pos.pieces()));
#elif SPOT == 2 // Position::pseudo_legal, the destination square quantum
    long r = pos.pseudo_legal(Move(SQ_F3, Square(k & 63))) + 2 * pos.pseudo_legal(Move(SQ_F1, Square(k & 63)));
#elif SPOT == 3 // Position::see_ge on Nf3xe5, the threshold quantum
    long r = pos.see_ge(Move(SQ_F3, SQ_E5), int(k) - 100);
#elif SPOT == 4 // UCIEngine::to_cp (floating point win-rate model), the value quantum
    long r = UCIEngine::to_cp(Value(int(k) * 3 - 200), pos) & 127;
#elif SPOT == 5 // Position::attackers_to, the square quantum
    long r = popcount(pos.attackers_to(Square(k & 63), pos.pieces()));
#endif
#ifdef ALL
    return cq_measure(r);
#else
    return (int)cq_measure(r);
#endif
}
#endif
