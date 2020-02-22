// Reference: Compilers: Principles, Techniques, and Tools, written by Alfred V. Aho, Monica S. Lam, Ravi Sethi, and Jeffrey D. Ullman

//import data, tool, SLR, LR, LALR;
import data, tool;
import std.stdio, std.ascii, std.typecons;
import std.array, std.container;
import std.algorithm, std.algorithm.comparison;

void main() {
    
}

unittest {
    enum set1 = SymbolSet(4, [2,3,-1]);
    SymbolSet Test1() {
        auto result = SymbolSet(4, [2,3,1]);
        result.add(-2,-1);
        return result;
    }
    enum set2 = Test1();
    static assert (1 !in set1);
    static assert (set1 in set2);
    enum set3 = SymbolSet(4, [-2, 1]);
    static assert (set1 + set3 == set2);
    
    static assert (SymbolSet(4, [-3, -2, -1, 0, 1, 2, 3]) - SymbolSet(4, [-3, -1, 0, 2, 3]) == set3);
}


unittest {
    enum {
        Expr, Term, Factor,
        digit, add, mul, lPar, rPar
    }
    
    static const grammar_info = new GrammarInfo(grammar(
        rule(Expr, Expr, add, Term),
        rule(Expr, Term),
        rule(Term, Term, mul, Factor),
        rule(Term, Factor),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar)
    ));
    // FIRST(Expr) = FIRST(Term) = FIRST(Factor) = {digit, lPar}
    grammar_info.test();
    writeln();
}


unittest {
    enum {
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
        rule(Factor, lPar, Expr, rPar)
    ));
    
    grammar_info.test();
    writeln();
    writeln(grammar_info.first([Expr_, Term_]).array);
}

