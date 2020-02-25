// Reference: Compilers: Principles, Techniques, and Tools, written by Alfred V. Aho, Monica S. Lam, Ravi Sethi, and Jeffrey D. Ullman

//import data, tool, SLR, LR, LALR;
import comp_d;
import std.stdio, std.ascii, std.typecons;
import std.array, std.container;
import std.algorithm, std.algorithm.comparison;

void main() {
    enum : Symbol {
        Expr, Expr_, Term, Term_, Factor,
        digit, add, mul, lPar, rPar
    }
    static const grammar_info = new GrammarInfo(grammar(
        rule(Expr, Term, Expr_),
        rule(Expr_, add, Term, Expr_),
        rule(Expr_, empty_),
        rule(Term, Factor, Term_),
        rule(Term_, mul, Factor, Term_),
        rule(Term_, empty_),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar),
    ), ["Expr", "Expr'", "Term", "Term'", "Factor", "id", "+", "*", "(", ")"]);
    Symbol[] inputs = [digit, add, lPar, digit, add, digit, mul, digit, rPar, end_of_file_];
    showLALRtableInfo(grammar_info);
    /+
    enum : Symbol {
        S, A, B, a, b, c, d, e
    }
    // reduce-reduce conflict occurs when passed to SLR
    auto grammar_info = new GrammarInfo(grammar(
        rule(S, a, A, d),
        rule(S, b, B, d),
        rule(S, a, B, e),
        rule(S, b, A, e),
        rule(A, c),
        rule(B, c),
    ), ["S", "A", "B", "a", "b", "c", "d", "e"]);
    Symbol[] inputs = [star, star, star, id, eq, star, star, id, end_of_file_];
    +/
    /+
    enum : Symbol {
        S, L, R, eq, star, id
    }
    static const grammar_info = new GrammarInfo(grammar(
        rule(S, L, eq, R),
        rule(S, R),
        rule(L, star, R),
        rule(L, id),
        rule(R, L),
    ), ["S", "L", "R", "=", "*", "id"]);
    Symbol[] inputs = [star, star, star, id, eq, star, star, id, end_of_file_];
    +/
    
    static const table_info = LALRtableInfo(grammar_info);
    static const table = table_info.table;
    State[] stack = [0];
    size_t ptr;
    
    parse: while (true) {
        auto state = stack[$-1];
        //writeln(grammar_info.nameOf(inputs[ptr]), " ", state);
        auto entry = table[state, inputs[ptr]];
        
        switch (entry.action) {
        case Action.shift:
            stack ~= entry.num;
            ++ptr;
            //writeln("shift  ", stack);
        break;
        
        case Action.reduce:
            auto rule = grammar_info.grammar[entry.num];
            //writeln(entry);
            // empty generating rule
            if (!(rule.rhs.length == 1 && rule.rhs[0] == empty_))
                stack.length -= rule.rhs.length;
            auto state2 = stack[$-1];
            if (table[state2, rule.lhs].action == Action.goto_) { stack ~= table[state2, rule.lhs].num; }
            else { writeln("error! ", state2, " ", rule.lhs); break parse; }
            //writeln("reduce ", entry.num, stack);
        break;
        
        case Action.accept:
            writeln("accept!!");
        break parse;
        
        case Action.error:
            writeln("error!!");
        break parse;
        
        default:
            assert(0);
        }
    }
}

