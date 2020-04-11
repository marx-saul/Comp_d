module lambda;

import comp_d;
import std.stdio, std.ascii;
import std.array;
import std.conv: to;

// definition of grammar
alias grammar = defineGrammar!(`
    Expr:
        Expr Atom,
        Atom
    ;
    Atom:
        lam var dot Expr,
        lPar Expr rPar,
        var
    ;
`);
// symbol declarations
mixin ("enum : Symbol {" ~ grammar.tokenDeclarations ~ "}");

static const table_info = SLRtableInfo(grammar.grammar_info);

bool isLambda(Symbol[] input) {
    return parse(grammar.grammar_info, table_info, input);
}
