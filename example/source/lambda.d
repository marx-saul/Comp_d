module lambda;

import comp_d;
import std.stdio, std.ascii;
import std.array;
import std.conv: to;

// definition of grammar
alias grammar = defineGrammar!(`
    LambdaExpr:
        lam Vars dot LambdaExpr,
        Apply,
    ;
    Apply:
        Apply Atom,
        Atom,
    ;
    Atom:
        var,
        lPar LabmdaExpr rPar,
    ;
    Vars:
        Vars var,
        var
    ;
`);
// symbol declarations
mixin ("enum : Symbol {" ~ grammar.tokenDeclarations ~ "}");

static const table_info = SLRtableInfo(grammar.grammar_info);

bool isLambda(Symbol[] input) {
    return parse(grammar.grammar_info, table_info, input);
}
