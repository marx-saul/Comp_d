// Reference: Compilers: Principles, Techniques, and Tools, written by Alfred V. Aho, Monica S. Lam, Ravi Sethi, and Jeffrey D. Ullman

//import data, tool, SLR, LR, LALR;
import data, tool;
import std.stdio, std.ascii, std.typecons;
import std.array, std.container;
import std.algorithm, std.algorithm.comparison;

void main() {
    
}

unittest {
    auto set1 = new Set!int();
    set1.add(12, 11, 18, 19);
    auto set2 = new Set!int();
    set2.add(2, 2, 9, 3);
    
    set1 += set2;
    
    auto set3 = new Set!int();
    set3.add(18, 9, 120, 168);
    
    set1 -= set3;
    
    auto set4 = new Set!int();
    set4.add(19, 12, 11, 3, 2);
    
    assert(set1 in set4);
    assert(set4 in set1);
    assert(set1 == set4);
    assert(set1 != set3);
}

unittest {
    assert( maxSymbolNumber(grammar(rule(0, 2, 3), rule(2, 4))) == 4 );
    assert( equal( nonterminalSet( grammar(rule(0,2,3), rule(2,4)) ).toList, [0, 2] ) );
    
    enum {
        Expr, Term, Factor,
        digit, add, mul, lPar, rPar
    }
    
    firstTable( grammar(
        rule(Expr, Expr, add, Term),
        rule(Expr, Term),
        rule(Term, Term, mul, Factor),
        rule(Term, Factor),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar)
    )).each!( (x) { if (x) writeln(x.toList); else writeln("[]"); } );
    
    /+enum first_table =  firstTable( grammar(
        rule(Expr, Expr, add, Term),
        rule(Expr, Term),
        rule(Term, Term, mul, Factor),
        rule(Term, Factor),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar)
    ));+/
    
    //firstTable(grammar(rule(0,2,3), rule(2,4))).each!( (x) { if (x) writeln(x.toList); else writeln("[]"); } );
    //assert( equal( firstTable(grammar(rule(0,2,3), rule(2,4)) ), [Set!Symbol(4), ] );
}
