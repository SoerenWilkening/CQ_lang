// check.cpp: Stockfish functions as entries f1..f35 for the sampling checker (cqcheck user): k is the quantum input.
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
#include "movegen.h"
#include "evaluate.h"
#include "tt.h"
using namespace Stockfish;
namespace Stockfish {
namespace Zobrist { extern Key psq[PIECE_NB][SQUARE_NB], enpassant[FILE_NB], castling[CASTLING_RIGHT_NB], side, noPawns; }
extern std::array<Key, 8192> cuckoo;
extern std::array<Move, 8192> cuckooMove;
}
// pos: an opening; pos2: after Nf3 Nf6 Ng1 Ng8 Nf3 with its history sh2 (repetition); pos3: "kiwipete";
// pos4: perft position 4, white in check; pos5: pins on both sides (Be3, Nd2 white; Nd7 black).
static Position pos, pos2, pos3, pos4, pos5;
static StateInfo st, sh2[6], st3, st4, st5, nst;
#ifdef GEN
// Native generator (build/check/gen > build/check/posdata.inc). The checked module has no setup code: at the default K a
// lowered Bitboards::init is cut off in its first loop whose bound is loaded from a global (CR rules 3, 14; cq-gi85k),
// and Position::set parses its FEN with std::istringstream, a host stand-in under the checker. So the position, the
// state and every table the entries read are made natively and shipped as bytes; the magic tables themselves are
// constants of the module (RT, BT). A word that points into one of the objects is written as an assignment.
int main() {
    Bitboards::init(); Position::init();
    pos.set("r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3", false, &st);
    pos2.set("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", false, &sh2[0]);
    const Move hist[] = {Move(SQ_G1, SQ_F3), Move(SQ_G8, SQ_F6), Move(SQ_F3, SQ_G1), Move(SQ_F6, SQ_G8), Move(SQ_G1, SQ_F3)};
    for (int i = 0; i < 5; i++) pos2.do_move(hist[i], sh2[i + 1]);
    for (auto &s : sh2) s.dirtyPiece = {};  // NNUE update bookkeeping no entry reads; zero, so the history ships without its tail
    pos3.set("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1", false, &st3);
    pos4.set("r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1", false, &st4);
    pos5.set("4k3/3nr3/8/1B6/1b6/4B3/3N4/4K3 w - - 0 1", false, &st5);
    // ML3: the legal moves of pos3; PL4, PL5: the pseudo-legal moves of pos4 (evasions), pos5. Constants of the module.
    ExtMove l[MAX_MOVES], *e = generate<LEGAL>(pos3, l);
    printf("static const Move ML3[] = {"); for (ExtMove *m = l; m < e; m++) printf("Move(%u),", m->raw()); printf("};\nstatic const int NML3 = %d;\n", int(e - l));
    e = generate<EVASIONS>(pos4, l);
    printf("static const Move PL4[] = {"); for (ExtMove *m = l; m < e; m++) printf("Move(%u),", m->raw()); printf("};\nstatic const int NPL4 = %d;\n", int(e - l));
    e = generate<NON_EVASIONS>(pos5, l);
    printf("static const Move PL5[] = {"); for (ExtMove *m = l; m < e; m++) printf("Move(%u),", m->raw()); printf("};\nstatic const int NPL5 = %d;\n", int(e - l));
    struct { const char *n, *dst; unsigned char *p; size_t z; } o[] = {
        {"POS", "&pos", (unsigned char *) &pos, sizeof pos}, {"ST", "&st", (unsigned char *) &st, sizeof st},
        {"RM", "RookMagics", (unsigned char *) RookMagics, sizeof RookMagics}, {"BM", "BishopMagics", (unsigned char *) BishopMagics, sizeof BishopMagics},
        {"PA", "PseudoAttacks", (unsigned char *) PseudoAttacks, sizeof PseudoAttacks}, {"BB", "BetweenBB", (unsigned char *) BetweenBB, sizeof BetweenBB},
        {"LB", "LineBB", (unsigned char *) LineBB, sizeof LineBB}, {"PC", "PopCnt16", (unsigned char *) PopCnt16, sizeof PopCnt16},
        {"SD", "SquareDistance", (unsigned char *) SquareDistance, sizeof SquareDistance},
        {"POS2", "&pos2", (unsigned char *) &pos2, sizeof pos2}, 
        {"SH20", "&sh2[0]", (unsigned char *) &sh2[0], sizeof *sh2}, {"SH21", "&sh2[1]", (unsigned char *) &sh2[1], sizeof *sh2},
        {"SH22", "&sh2[2]", (unsigned char *) &sh2[2], sizeof *sh2}, {"SH23", "&sh2[3]", (unsigned char *) &sh2[3], sizeof *sh2},
        {"SH24", "&sh2[4]", (unsigned char *) &sh2[4], sizeof *sh2}, {"SH25", "&sh2[5]", (unsigned char *) &sh2[5], sizeof *sh2},
        {"POS3", "&pos3", (unsigned char *) &pos3, sizeof pos3}, {"ST3", "&st3", (unsigned char *) &st3, sizeof st3},
        {"POS4", "&pos4", (unsigned char *) &pos4, sizeof pos4}, {"ST4", "&st4", (unsigned char *) &st4, sizeof st4},
        {"POS5", "&pos5", (unsigned char *) &pos5, sizeof pos5}, {"ST5", "&st5", (unsigned char *) &st5, sizeof st5},
        {"PAW", "PawnAttacks", (unsigned char *) PawnAttacks, sizeof PawnAttacks},
        {"ZP", "Zobrist::psq", (unsigned char *) Zobrist::psq, sizeof Zobrist::psq}, {"ZE", "Zobrist::enpassant", (unsigned char *) Zobrist::enpassant, sizeof Zobrist::enpassant},
        {"ZC", "Zobrist::castling", (unsigned char *) Zobrist::castling, sizeof Zobrist::castling},
        {"ZS", "&Zobrist::side", (unsigned char *) &Zobrist::side, sizeof Zobrist::side}, {"ZN", "&Zobrist::noPawns", (unsigned char *) &Zobrist::noPawns, sizeof Zobrist::noPawns},
        {"CK", "&cuckoo", (unsigned char *) &cuckoo, sizeof cuckoo}, {"CM", "&cuckooMove", (unsigned char *) &cuckooMove, sizeof cuckooMove},
        {"RT", "RT", (unsigned char *) RookMagics[0].attacks, 0x19000 * 8}, {"BT", "BT", (unsigned char *) BishopMagics[0].attacks, 0x1480 * 8}};
    const int N = sizeof o / sizeof *o, COPIED = N - 2;  // all but RT, BT
    // A copied object's zero tail is not shipped (static storage starts zero): the NNUE accumulators of a StateInfo.
    size_t c[N]; for (int a = 0; a < N; a++) { c[a] = o[a].z; if (a < COPIED) while (!o[a].p[c[a] - 1]) c[a]--; }  // each has a nonzero byte
    for (int a = 0; a < N; a++) { printf("alignas(8) static const unsigned char %s[] = {", o[a].n); for (size_t i = 0; i < c[a]; i++) printf("%u,", o[a].p[i]); puts("};"); }
    puts("static void load_data() {");
    for (int a = 0; a < COPIED; a++) printf("#ifdef COUNT\n    memset((void *) %s, 0, %zu);  // the native count reloads after each call\n#endif\n"
                                            "    memcpy((void *) %s, %s, %zu);\n", o[a].dst, o[a].z, o[a].dst, o[a].n, c[a]);
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
// Bitboard helpers
ENTRY long f6(unsigned char x) { unsigned char k = q(x); return attacks_bb<ROOK>(Square(k & 63), pos3.pieces()); }
ENTRY long f7(unsigned char x) { unsigned char k = q(x); return attacks_bb<BISHOP>(Square(k & 63), pos3.pieces()); }
ENTRY long f8(unsigned char x) { unsigned char k = q(x); return attacks_bb<KNIGHT>(Square(k & 63)); }
ENTRY long f9(unsigned char x) { unsigned char k = q(x); return attacks_bb<KING>(Square(k & 63)); }
ENTRY long f10(unsigned char x) { unsigned char k = q(x); return pawn_attacks_bb(Color(k >> 7), Square(k & 63)); }
ENTRY long f11(unsigned char x) { unsigned char k = q(x); return between_bb(Square(k & 63), SQ_D4); }
ENTRY long f12(unsigned char x) { unsigned char k = q(x); return line_bb(Square(k & 63), SQ_E4); }
ENTRY long f13(unsigned char x) { unsigned char k = q(x);
    return aligned(Square(k & 63), SQ_C3, SQ_E5) + 2 * aligned(SQ_E1, Square(k & 63), SQ_E8); }
ENTRY long f14(unsigned char x) { unsigned char k = q(x);
    return distance<Square>(Square(k & 63), SQ_E4) + 8 * distance<File>(Square(k & 63), SQ_B7) + 64 * distance<Rank>(Square(k & 63), SQ_B7); }
ENTRY long f15(unsigned char x) { unsigned char k = q(x); return popcount(pos3.pieces() ^ (Bitboard(k) * 0x0101010101010101ULL)); }
ENTRY long f16(unsigned char x) { unsigned char k = q(x); Bitboard lo = (2ULL << (k & 63)) - 1;
    return lsb((pos3.pieces() & ~lo) | (1ULL << 63)) + 64 * msb((pos3.pieces() & lo) | 1); }
ENTRY long f17(unsigned char x) { unsigned char k = q(x); Bitboard b = pos3.pieces() & (Bitboard(k & 15) << 8);  // at most 4 trips
    long s = 0; while (b) s = s * 64 + pop_lsb(b); return s; }
ENTRY long f18(unsigned char x) { unsigned char k = q(x);
    return shift<NORTH_EAST>(Bitboard(k) << 8) | shift<SOUTH>(Bitboard(k) << 56) ^ shift<WEST>(Bitboard(k) << 32); }
ENTRY long f19(unsigned char x) { unsigned char k = q(x); return pawn_attacks_bb<BLACK>(Bitboard(k) << 48); }
// Position: k selects a move from a shipped list
ENTRY long f20(unsigned char x) { unsigned char k = q(x); return pos5.gives_check(PL5[k % NPL5]); }
ENTRY long f21(unsigned char x) { unsigned char k = q(x); return pos5.legal(PL5[k % NPL5]); }
ENTRY long f22(unsigned char x) { unsigned char k = q(x); return pos3.key_after(ML3[k % NML3]); }
ENTRY long f23(unsigned char x) { unsigned char k = q(x); Move m = PL4[k % NPL4];
    return pos4.capture(m) + 2 * pos4.capture_stage(m) + 4 * pos4.moved_piece(m); }
ENTRY long f24(unsigned char x) { unsigned char k = q(x);
    return pos4.blockers_for_king(Color(k & 1)) ^ pos4.check_squares(PieceType(1 + (k >> 1) % 6)); }
ENTRY long f25(unsigned char x) { unsigned char k = q(x); Color c = Color(k & 1);
    pos5.update_slider_blockers(c); return pos5.blockers_for_king(c) ^ pos5.pinners(~c) * 3; }
ENTRY long f26(unsigned char x) { unsigned char k = q(x);
    return pos3.attacks_by<KNIGHT>(Color(k & 1)) ^ pos3.attacks_by<BISHOP>(Color(k >> 7)) * 3; }
ENTRY long f27(unsigned char x) { unsigned char k = q(x); return pos2.is_draw(k); }
ENTRY long f28(unsigned char x) { unsigned char k = q(x); return pos2.upcoming_repetition(int(k) - 2); }
// do_move / undo_move / do_null_move on pos3; k picks Nxf7, O-O, a2a4 (sets ep), dxe6
static const Move DM[] = {Move(SQ_E5, SQ_F7), Move::make<CASTLING>(SQ_E1, SQ_H1), Move(SQ_A2, SQ_A4), Move(SQ_D5, SQ_E6)};
static long digest(const Position &p) {
    return long(p.key() ^ p.pieces(WHITE) * 3 ^ p.pieces(BLACK) * 5 ^ p.checkers() * 7 ^ (Bitboard(p.state()->castlingRights) << 3)
                ^ (Bitboard(p.ep_square()) << 9) ^ (Bitboard(p.side_to_move()) << 17) ^ (Bitboard(p.captured_piece()) << 21)); }
ENTRY long f29(unsigned char x) { unsigned char k = q(x); pos3.do_move(DM[k & 3], nst); return digest(pos3); }
ENTRY long f30(unsigned char x) { unsigned char k = q(x); Move m = DM[k & 3]; pos3.do_move(m, nst); pos3.undo_move(m);
    return digest(pos3) ^ long(nst.key); }
alignas(TranspositionTable) static unsigned char ttb[sizeof(TranspositionTable)];  // zero: no table (prefetch of null only)
ENTRY long f31(unsigned char x) { unsigned char k = q(x);
    if (k & 1) { pos3.do_null_move(nst, *(TranspositionTable *) ttb); if (k & 2) pos3.undo_null_move(); } return digest(pos3); }
// Move generation: k indexes the generated list
ENTRY long f32(unsigned char x) { unsigned char k = q(x); ExtMove l[MAX_MOVES]; int n = generate<LEGAL>(pos3, l) - l;
    return n * 65536 + l[k % n].raw(); }
ENTRY long f33(unsigned char x) { unsigned char k = q(x); ExtMove l[MAX_MOVES]; int n = generate<CAPTURES>(pos3, l) - l;
    return n * 65536 + l[k % n].raw(); }
ENTRY long f34(unsigned char x) { unsigned char k = q(x); ExtMove l[MAX_MOVES]; int n = generate<EVASIONS>(pos4, l) - l;
    return n * 65536 + l[k % n].raw(); }
// Evaluation without the network: k picks the position and the colour
ENTRY long f35(unsigned char x) { unsigned char k = q(x); return Eval::simple_eval(k & 2 ? pos3 : pos4, Color(k & 1)); }
// libc++'s abort hook is variadic and has no body in the module; the checker cannot call a variadic host function.
namespace std { inline namespace __1 { [[noreturn]] void __libcpp_verbose_abort(const char *, ...) { __builtin_abort(); } } }
#ifdef COUNT
// Native count of distinct results over the byte (build with -DCOUNT; q() is the identity).
#include <set>
extern "C" unsigned char cq_theta_ui8(unsigned char v, double) { return v; }
int main() {
    long (*f[])(unsigned char) = {f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15, f16, f17, f18, f19, f20,
                                  f21, f22, f23, f24, f25, f26, f27, f28, f29, f30, f31, f32, f33, f34, f35};
    for (int i = 0; i < int(sizeof f / sizeof *f); i++) { std::set<long> r;
        for (int x = 0; x < 256; x++) { load_data(); r.insert(f[i](x)); } printf("f%d %zu\n", i + 1, r.size()); }
}
#endif
#endif
