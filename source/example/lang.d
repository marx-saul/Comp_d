module example.lang;

import comp_d;
import std.stdio, std.ascii;
import std.array;
import std.conv: to;

enum : Symbol {
    Expr, Term, Factor,
    id, add, sub, mul, div, lPar, rPar
}
static const grammar_info = new GrammarInfo(grammar(
    rule(Expr, Expr, add, Term),
    rule(Expr, Expr, sub, Term),
    rule(Expr, Term),
    rule(Term, Term, mul, Factor),
    rule(Term, Term, div, Factor),
    rule(Term, Factor),
    rule(Factor, lPar, Expr, rPar),
    rule(Factor, id),
    rule(Factor, add, id),
    rule(Factor, sub, id),
), ["Expr", "Term", "Factor", "id", "+", "-", "*", "/"]);
static const table_info = SLRtableInfo(grammar_info);

class Parser : comp_d.Parser {
    this(inout GrammarInfo g_i, inout LRTableInfo t_i, Symbol[] eops = [], string[] rl = []) {
        super(g_i, t_i, eops, rl);
    }
}

class MyLexer : comp_d.Lexer {
    Symbol[] tokens;
    override bool empty() @property { return tokens.empty; }
    override Symbol front_symbol() @property { return tokens.front; }
    override void popFront() { tokens.popFront(); }
}

void test() {
    auto parser = new Parser(grammar_info, table_info);
    auto inputs = [id, add, id, mul, id];
    auto lexer = new MyLexer();
    assert(parser.parse(lexer));
}
