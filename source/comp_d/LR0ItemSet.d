module comp_d.LR0ItemSet;

import comp_d.Set, comp_d.tool, comp_d.data;
import std.typecons;
import std.array, std.container, std.container.binaryheap;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

// num is the index of the rule in the grammar, and the index is the index of the point
// i : A -> X.YZ is LR0Item(i, 1)
alias LR0Item = Tuple!(size_t, "num", size_t, "index");

// dictionary-order of LR0Item
bool ItemLess(LR0Item a, LR0Item b) {
    return a.num < b.num || (a.num == b.num && a.index < b.index);
}

// LR0Item set
alias LR0ItemSet = Set!(LR0Item, ItemLess);


// cardinal and dictionary-order of LR0ItemSet
// compare (a.array.length, a.array[0], a.array[1], ...) and (b.array.length, b.array[0], b.array[1], ...)
bool ItemSetLess(inout LR0ItemSet a, inout LR0ItemSet b) {
    auto aa = a.array, ba = b.array;
    if      (aa.length < ba.length) return true;
    else if (aa.length > ba.length) return false;
    
    foreach (i; 0 .. aa.length) {
        auto a_i = aa[i], b_i = ba[i];
        if      (ItemLess(a_i, b_i)) return true;
        else if (ItemLess(b_i, a_i)) return false;
    }
    return false;
}

// LR0Item set set
alias LR0ItemSetSet = Set!(LR0ItemSet, ItemSetLess);

unittest {
    enum : Symbol {
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
    static const item_set1 = new LR0ItemSet(LR0Item(0, 0), LR0Item(8, 5), LR0Item(8, 1), LR0Item(3, 17));
    static assert (LR0Item(3, 16) !in item_set1);
    static assert (LR0Item(8,1) in item_set1);
    writeln("LR0ItemSet unittest 1");
}
