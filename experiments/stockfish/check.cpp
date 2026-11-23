// check.cpp: the five spot functions as entries f1..f5 for the sampling checker (cqcheck user): k is the quantum input.
// The setup is a static constructor of this module; it is classical and runs before the entry in both programs.
// operator new/delete over malloc/free (cq.hpp): a bodiless operator new is a host stand-in returning null under the checker
#include "cq.hpp"
#include "bitboard.h"
#include "position.h"
#include "uci.h"
using namespace Stockfish;
static Position pos;
static StateInfo st;
static int init = (Bitboards::init(), Position::init(),
    pos.set("r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3", false, &st), 0);
ENTRY long f1(unsigned char x) { unsigned char k = q(x); return popcount(attacks_bb<QUEEN>(Square(k & 63), pos.pieces())); }
ENTRY long f2(unsigned char x) { unsigned char k = q(x);
    return pos.pseudo_legal(Move(SQ_F3, Square(k & 63))) + 2 * pos.pseudo_legal(Move(SQ_F1, Square(k & 63))); }
ENTRY long f3(unsigned char x) { unsigned char k = q(x); return pos.see_ge(Move(SQ_F3, SQ_E5), int(k) - 100); }
ENTRY long f4(unsigned char x) { unsigned char k = q(x); return UCIEngine::to_cp(Value(int(k) * 3 - 200), pos); }
ENTRY long f5(unsigned char x) { unsigned char k = q(x); return popcount(pos.attackers_to(Square(k & 63), pos.pieces())); }
// libc++'s abort hook is variadic and has no body in the module; the checker cannot call a variadic host function.
namespace std { inline namespace __1 { [[noreturn]] void __libcpp_verbose_abort(const char *, ...) { __builtin_abort(); } } }
