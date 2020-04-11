// Reference: Compilers: Principles, Techniques, and Tools, written by Alfred V. Aho, Monica S. Lam, Ravi Sethi, and Jeffrey D. Ullman

import comp_d;
import std.stdio, std.typecons;
import std.range, std.array, std.container;
import std.algorithm, std.algorithm.comparison;

void main()
{
    /+
	// expression.d
	import expression;
    static assert (eval("26 - (32*2 - 23)") == -15);
    writeln("Write expressions. 'exit' to end.");
    while (true) {
        auto str = readln();
        if (str == "exit\n") break;
        else writeln(" = ", eval(str));
    }
    +/
    
    import lambda;
    assert ( isLambda([lam, var, dot, lam, var, dot, var]) );
}

/+ // You can copy&paste these codes and remove the comment out to see the static parsing.
    
    // EXAMPLE 1
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
    static assert ( parse(grammar_info.grammar, table_info.table, [digit, add, lPar, digit, add, digit, mul, digit, rPar]) );
    //showLALRtableInfo(grammar_info);
    
    /+ // EXAMPLE 2
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
    static assert ( parse(grammar_info.grammar, table_info.table, [a, c, d]) );
    +/
+/
