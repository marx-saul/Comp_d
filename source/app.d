// Reference: Compilers: Principles, Techniques, and Tools, written by Alfred V. Aho, Monica S. Lam, Ravi Sethi, and Jeffrey D. Ullman

//import data, tool, SLR, LR, LALR;
import comp_d;
import std.stdio, std.ascii, std.typecons;
import std.array, std.container;
import std.algorithm, std.algorithm.comparison;

void main() {
    /+
    enum : Symbol {
        Expr, Expr_, Term, Term_, Factor,
        digit, add, mul, lPar, rPar
    }
    auto grammar_info = new GrammarInfo(grammar(
        rule(Expr, Term, Expr_),
        rule(Expr_, add, Term, Expr_),
        rule(Expr_, empty_),
        rule(Term, Factor, Term_),
        rule(Term_, mul, Factor, Term_),
        rule(Term_, empty_),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar),
    ), ["Expr", "Expr'", "Term", "Term'", "Factor", "id", "+", "*", "(", ")"]);
    
    showSLRtableInfo(grammar_info);
    +/
    enum : Symbol {
        S, A, B, a, b, c, d, e
    }
    // reduce-reduce conflict occurs
    auto grammar_info = new GrammarInfo(grammar(
        rule(S, a, A, d),
        rule(S, b, B, d),
        rule(S, a, B, e),
        rule(S, b, A, e),
        rule(A, c),
        rule(B, c),
    ), ["S", "A", "B", "a", "b", "c", "d", "e"]);
    
    showLRtableInfo(grammar_info);
}

