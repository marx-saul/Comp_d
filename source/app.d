// Reference: Compilers: Principles, Techniques, and Tools, written by Alfred V. Aho, Monica S. Lam, Ravi Sethi, and Jeffrey D. Ullman

//import data, tool, SLR, LR, LALR;
import comp_d;
import std.stdio, std.ascii, std.typecons;
import std.array, std.container;
import std.algorithm, std.algorithm.comparison;

void main() {
    enum : Symbol {
        Expr, Term, Factor,
        digit, add, mul, lPar, rPar
    }
    auto grammar_info = new GrammarInfo(grammar(
        rule(Expr, Expr, add, Term),
        rule(Expr, Term),
        rule(Term, Term, mul, Factor),
        rule(Term, Factor),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar),
    ), ["Expr", "Term", "Factor", "digit", "+", "*", "(", ")"]);
    
    /*
    // show the SLR table
    auto table_info = SLRtableInfo(grammar_info);
    auto table = table_info.table;
    foreach (i; 0 .. table.state_num) {
        write(i, ":\t");
        foreach (sym; [digit, add, mul, lPar, rPar, end_of_file_, Expr, Term, Factor]) {
            write(table[i, sym].action, table[i, sym].num, ",  \t");
        }
        writeln();
    }
    
    writeln(table_info.is_conflict);
    */
    showSLRtableInfo(grammar_info);
}

