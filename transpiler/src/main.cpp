// P6 driver: libtooling entry point. Parses standard --/-- compile
// args via CommonOptionsParser, instantiates ClangTool, and runs the
// QuantumRewriteAction frontend action over every input file. The
// rewritten source is written to stdout by the action itself; the
// e2e test harness redirects/diffs against expected.c.
//
// `--help` (handled by CommonOptionsParser itself) prints LLVM's
// libtooling usage and exits — preserving the smoke_help contract from
// P0 by accepting any exit code that yields a usable USAGE message.
#include "Matcher.h"

#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>
#include <llvm/Support/CommandLine.h>
#include <llvm/Support/Error.h>
#include <llvm/Support/raw_ostream.h>

static llvm::cl::OptionCategory toolCategory("quantum_transpiler options");

int main(int argc, const char **argv) {
    auto parserOrErr = clang::tooling::CommonOptionsParser::create(
        argc, argv, toolCategory);
    if (!parserOrErr) {
        llvm::errs() << llvm::toString(parserOrErr.takeError());
        return 1;
    }
    clang::tooling::ClangTool tool(parserOrErr->getCompilations(),
                                   parserOrErr->getSourcePathList());
    return tool.run(
        clang::tooling::newFrontendActionFactory<qct::QuantumRewriteAction>()
            .get());
}
