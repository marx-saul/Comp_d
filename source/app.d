// Reference: Compilers: Principles, Techniques, and Tools, written by Alfred V. Aho, Monica S. Lam, Ravi Sethi, and Jeffrey D. Ullman

//import data, tool, SLR, LR, LALR;
import comp_d;
import std.stdio, std.typecons;
import std.range, std.array, std.container;
import std.algorithm, std.algorithm.comparison;

void main() {
    import example;
    /+
    static assert (eval("26 - (32*2 - 23)") == -15);
    writeln("Write expressions. 'exit' to end.");
    while (true) {
        auto str = readln();
        if (str == "exit\n") break;
        else writeln(" = ", eval(str));
    }
    +/
    test();
    
    
    /+
    alias grammar2 = defineGrammar!(`
        S :
        @one_step
            S l S r,
        @empty
            empty,
        ;
    `);
    static const left = grammar2.numberOf("l"), right = grammar2.numberOf("r");
    
    alias parser2 = injectParser!(grammar2.grammar_info, "SLR");
    static assert (parser2.parse([left, left, right, left, right, right]) == 0);    // accept
    static assert (parser2.parse([left, left, right, left, right]) == 1);           // error
    static assert (parser2.parse([right, left]) == 1);                              // error
    static assert (parser2.parse!(Symbol[])([]) == 0);                              // accept
    
    int pair_num;
    alias parser2_2 = injectParser!(grammar2.grammar_info, "SLR",
        { /* accept */ },
        (x) { if (grammar2.labelOf(x) == "one_step") {pair_num++;} },  // reduce
        (x) { /* error */ }
    );
    parser2_2.parse([left, left, right, left, left, left, right, right, right, right]);
    assert (pair_num == 5);
    +/
}

/+ You can copy&paste these codes and remove the comment out to see the static parsing.
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
    Symbol[] inputs = [digit, add, lPar, digit, add, digit, mul, digit, rPar];
    //showLALRtableInfo(grammar_info);
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
    //static int x = 0;
    assert(parse!({writeln("accept");}, (x){/+ reduce +/}, (x) {writeln("error");})(grammar_info.grammar, table_info.table, inputs) == 0);  // accept
    static const Symbol[] inputs2 = [lPar, digit, rPar, rPar];
    alias parser = generateParser!(grammar_info, table_info);
    static assert (parser.parse(inputs2) == 1);             // parsing result is error.
    
    alias parser2 = injectParser!(grammar_info, "SLR");
    static assert (parser2.parse(inputs2) == 1);
    +/
