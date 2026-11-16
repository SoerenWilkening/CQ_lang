// The pass's own instruction order inside a block (cq-g3h1i). Compile time only: no effect on the output.
#pragma once

namespace llvm { class Instruction; }

namespace cq {
// a comes before b in their common block: the answer of a->comesBefore(b). LLVM renumbers the whole block at
// the first comesBefore after any insertion, so a placement loop that inserts and then compares is quadratic
// in the block (swscanf: 1550 s, 97% of it in BasicBlock::renumberInstructions). This keeps order labels with
// gaps and labels a new instruction from its neighbours, so a comparison after an insertion costs O(log n)
// amortized. Instructions erased, replaced, inserted or moved to another block need no call. An instruction
// moved inside its own block is not supported.
bool comesBefore(const llvm::Instruction *a, const llvm::Instruction *b);
// Drops every label (the end of a pass run).
void orderReset();
} // namespace cq
