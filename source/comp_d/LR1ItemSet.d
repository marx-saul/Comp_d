module comp_d.LR1ItemSet;

import comp_d.Set, comp_d.tool, comp_d.data;
import std.typecons;
import std.array, std.container, std.container.binaryheap;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;

// num is the index of the rule in the grammar, and the index is the index of the point
// i : [A -> X.YZ, sym] is LR0Item(i, 1, sym)
alias LR1Item = Tuple!(size_t, "num", size_t, "index", Symbol, "lookahead");

// dictionary-order of LR1Item
pure @nogc @safe bool ItemLess(LR1Item a, LR1Item b) {
    return a.num < b.num || (a.num == b.num && a.index < b.index) || (a.num == b.num && a.index == b.index && a.lookahead < b.lookahead);
}

// LR0Item set
alias LR1ItemSet = Set!(LR1Item, ItemLess);


// cardinal and dictionary-order of LR0ItemSet
// compare (a.array.length, a.array[0], a.array[1], ...) and (b.array.length, b.array[0], b.array[1], ...)
pure bool ItemSetLess(inout LR1ItemSet a, inout LR1ItemSet b) {
    if      (a.cardinal < b.cardinal) return true;
    else if (a.cardinal > b.cardinal) return false;
    auto aa = a.array, ba = b.array;
    foreach (i; 0 .. aa.length) {
        auto a_i = aa[i], b_i = ba[i];
        if      (ItemLess(a_i, b_i)) return true;
        else if (ItemLess(b_i, a_i)) return false;
    }
    return false;
}

// LR0Item set set
alias LR1ItemSetSet = Set!(LR1ItemSet, ItemSetLess);

/+
unittest {
    enum : Symbol {
        Expr, Term, Factor,
        digit, add, mul, lPar, rPar
    }
    static const grammar_info = new GrammarInfo([
        rule(Expr, Expr, add, Term),
        rule(Expr, Term),
        rule(Term, Term, mul, Factor),
        rule(Term, Factor),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar)
    ]);
    /*
    static const item_set1 = new LR0ItemSet(LR0Item(0, 0), LR0Item(8, 5), LR0Item(8, 1), LR0Item(3, 17));
    static assert (LR0Item(3, 16) !in item_set1);
    static assert (LR0Item(8, 1)   in item_set1);
    static const item_set2 = new LR0ItemSet(LR0Item(0, 1), LR0Item(1, 9), LR0Item(2, 0), LR0Item(8, 5));
    static const item_set3 = item_set1 + item_set2;
    static assert (LR0Item(2, 0) in item_set3);
    
    static const item_set_set1 = new LR0ItemSetSet(cast(LR0ItemSet) item_set1, cast(LR0ItemSet) item_set2, cast(LR0ItemSet) item_set3);
    static assert (new LR0ItemSet(LR0Item(0, 0), LR0Item(8, 5), LR0Item(8, 1), LR0Item(3, 17)) in item_set_set1);
    static assert (new LR0ItemSet(LR0Item(9, 0), LR0Item(9, 5), LR0Item(9, 1), LR0Item(9, 17)) !in item_set_set1);
    
    static const item_set_set2 = new LR0ItemSetSet(cast(LR0ItemSet) item_set1, cast(LR0ItemSet) item_set3);
    static assert (item_set_set2 in item_set_set1);
    */
    
    writeln("## LR0ItemSet unittest 1");
}
+/
