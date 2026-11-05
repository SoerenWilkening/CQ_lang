/* rt_tape.h: what the tape family needs of the bus (BACKEND_ABI §1.11: capture and the INPUT rows).
 * rt_bus.c registers it from a constructor. With no bus registered every cell is HOST. */
#ifndef CQE_RT_TAPE_H_
#define CQE_RT_TAPE_H_

#include <stdint.h>

typedef struct {
  /* The cell's basis byte, a HOST cell read guarded (unreadable: 0). Returns 1 for a QUANTUM cell, 0 for a
   * HOST one. Touches nothing and logs nothing. */
  int (*peek)(uint64_t addr, uint8_t *byte);
  /* A store the backend makes for an effect entry whose address, control or length is quantum (§1.10 "A write
   * the backend itself makes ... is a bus store"): the cell becomes QUANTUM; write != 0: a fresh kept tape slot
   * takes the displaced content and the cell holds byte; write == 0 (this branch does not store): the cell keeps
   * its value and the slot stays 0. The hook sets the slot rail's exit role itself: the dispatcher sets roles
   * only for rails made under a qram op. */
  void (*qstore)(uint64_t addr, uint8_t byte, int write);
} cqe_tape_bus;

void cqe_tape_set_bus(const cqe_tape_bus *bus);

#endif
