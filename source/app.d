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
    auto grammar_info = new GrammarInfo(grammar(
        rule(Expr, Term, Expr_),
        rule(Expr_, add, Term, Expr_),
        rule(Expr_, empty_),
        rule(Term, Factor, Term_),
        rule(Term_, mul, Factor, Term_),
        rule(Term_, empty_),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar)
    ));
    //writeln(grammar_info.grammar);
    auto collection = canonicalLR0Collection(grammar_info);
    // show the items
    foreach (item_set; collection) {
        foreach (item; item_set.array) {
            write(item, ", ");
        }
        writeln();
    }
}

