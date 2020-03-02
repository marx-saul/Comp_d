module example.lang;

import comp_d;
import std.stdio, std.ascii;
import std.array;
import std.conv: to;

alias grammar = defineGrammar!(`
    Expr:
        @add Expr add Term,
        @sub Expr sub Term,
        Term;
    
    Term:
        @mul Term mul Factor,
        @div Term div Factor,
        Factor;
    
    Factor:
        @_Expr_ lPar Expr rPar,
        @digit  id,
        @uadd   add id,
        @usub   sub id;
`);

static const table_info = SLRtableInfo(grammar.grammar_info);

struct Token {
    Symbol symbol;
    int value;
}

class Parser : comp_d.Parser {
    this() {
        super(grammar.grammar_info, table_info);
    }
    override void reduce(size_t number_of_rule) {
        
    }
}

void test() {
    
}
