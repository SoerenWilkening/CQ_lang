// spot.cpp: Stockfish functions on a quantum argument; the exit code is the measured result. -DSPOT=n picks the check,
// -DV=v the basis value under the rotation (angle 0: the replay backend keeps it), -DNATIVE the plain C++ program.
#define CQ_NO_NEW
#ifdef NATIVE
template <class T> void cq_theta(T *, double) {}
template <class T> T cq_measure(T x) { return x; }
#else
#include "cq.hpp"
#endif
#include "bitboard.h"
#include "position.h"
#include "uci.h"
using namespace Stockfish;
int main() {
    Bitboards::init(); Position::init();
    Position pos; StateInfo st;
    pos.set("r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3", false, &st);
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
    return (int)cq_measure(r);
}
