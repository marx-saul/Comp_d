module comp_d.SLR;

import comp_d.LR0ItemSet, comp_d.LRTable, comp_d.tool, comp_d.data;
import std.typecons;
import std.array, std.container, std.container.binaryheap;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln, write;
import std.conv: to;

unittest {
    enum : Symbol {
        S, Expr, Term, Factor,
        digit, add, mul, lPar, rPar
    }
    static const grammar_info = new GrammarInfo(grammar(
        rule(S, Expr),
        rule(Expr, Expr, add, Term),
        rule(Expr, Term),
        rule(Term, Term, mul, Factor),
        rule(Term, Factor),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar)
    ), false);          // no augment
    // closure CTFE test
    static const item_set1  = new LR0ItemSet(LR0Item(0, 0));   // { [S -> .Expr] }
    static const item_set2 = closure(grammar_info, item_set1);
    static assert (
        item_set2 == new LR0ItemSet(
            LR0Item(0, 0),  // S -> .Expr
            LR0Item(1, 0),  // Expr -> .Expr + Term
            LR0Item(2, 0),  // Expr -> .Term
            LR0Item(3, 0),  // Term -> .Term * Factor
            LR0Item(4, 0),  // Term -> .Factor
            LR0Item(5, 0),  // Factor -> .( Expr )
            LR0Item(6, 0)   // Factor -> .digit
        )
    );
    // goto CTFE test
    static const item_set3 = _goto(grammar_info, item_set2, Expr);
    static assert (
        item_set3 == new LR0ItemSet(
            LR0Item(0, 1),  // S -> Expr.
            LR0Item(1, 1),  // Expr -> Expr. + Term
        )
    );
    static const item_set4 = _goto(grammar_info, item_set3, add);
    static assert (
        item_set4 == new LR0ItemSet(
            LR0Item(1, 2),  // Expr -> Expr + .Term
            LR0Item(3, 0),  // Term -> .Term * Factor
            LR0Item(4, 0),  // Term -> .Factor
            LR0Item(5, 0),  // Factor -> .( Expr )
            LR0Item(6, 0)   // Factor -> .digit
        )
    );
    
    writeln("## SLR unittest 1");
}

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
        rule(Factor, lPar, Expr, rPar),
    ));
    
    static const collection = canonicalLR0Collection(grammar_info);
    static assert (
        equal( collection, [
            new LR0ItemSet(LR0Item(0, 0), LR0Item(1, 0), LR0Item(2, 0), LR0Item(3, 0), LR0Item(4, 0),LR0Item(5, 0), LR0Item(6, 0)),
            new LR0ItemSet(LR0Item(0, 1), LR0Item(6, 1)),
            new LR0ItemSet(LR0Item(1, 1), LR0Item(2, 1)),
            new LR0ItemSet(LR0Item(3, 1)),
            new LR0ItemSet(LR0Item(4, 1)), 
            new LR0ItemSet(LR0Item(0, 0), LR0Item(1, 0), LR0Item(2, 0), LR0Item(3, 0), LR0Item(4, 0), LR0Item(5, 0), LR0Item(5, 1)),
            new LR0ItemSet(LR0Item(0, 2), LR0Item(2, 0), LR0Item(3, 0), LR0Item(4, 0), LR0Item(5, 0)),
            new LR0ItemSet(LR0Item(2, 2), LR0Item(4, 0), LR0Item(5, 0)),
            new LR0ItemSet(LR0Item(0, 1), LR0Item(5, 2)),
            new LR0ItemSet(LR0Item(0, 3), LR0Item(2, 1)),
            new LR0ItemSet(LR0Item(2, 3)),
            new LR0ItemSet(LR0Item(5, 3))
        ] )
    );
    
    /+
    // show the items
    foreach (i, item_set; collection) {
        writeln(i, ":");
        foreach (item; item_set.array) {
            writeln("\t", item, ", ");
        }
    }
    +/
    /+ the result rewritten
     + (0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (5, 0), (6, 0) 
     + (0, 1), (6, 1)
     + (1, 1), (2, 1)
     + (3, 1)
     + (4, 1)
     + (0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (5, 0), (5, 1)
     + (0, 2), (2, 0), (3, 0), (4, 0), (5, 0)
     + (2, 2), (4, 0), (5, 0)
     + (0, 1), (5, 2)
     + (0, 3), (2, 1)
     + (2, 3)
     + (5, 3)
     +/
     
     
    // show the SLR table
    static const table = SLRtableInfo(grammar_info).table;
    foreach (i; 0 .. table.state_num) {
        write(i, ":\t");
        foreach (sym; [digit, add, mul, lPar, rPar, end_of_file_, Expr, Term, Factor]) {
            write(table[i, sym].action, table[i, sym].num, ", \t");
        }
        writeln();
    }
    /+ 4 -> 5, 5 -> 4 +/
    
    writeln("## SLR unittest 2");
}

// replace item_set by its closure
LR0ItemSet closure(inout const GrammarInfo grammar_info, inout LR0ItemSet item_set) {
    auto result = new LR0ItemSet( (cast(LR0ItemSet) item_set).array);
    auto grammar = grammar_info.grammar;
    
    // collect B such that [A -> s.Bt] in item_set to non_kernel_symbols
    auto non_kernel_symbols = grammar_info.symbolSet();
    
    foreach (item; result.array) {
        // . is at the end
        if (item.index >= grammar[item.num].rhs.length) continue;
        // if [A -> s.Bt] is in item_set, add B -> .u to item_set
        auto symbol = grammar[item.num].rhs[item.index];
        if (symbol in grammar_info.nonterminals) non_kernel_symbols.add(symbol);
    }
    
    while (true) {
        auto previous_cardinal = non_kernel_symbols.cardinal;
        
        foreach (rule; grammar) {
            // rule is like  B -> Au  where B is in non_kernel_symbols
            // and A is a nonterminal symbol, then add A.
            if (rule.lhs in non_kernel_symbols && rule.rhs[0] in grammar_info.nonterminals) {
                non_kernel_symbols.add(rule.rhs[0]);
            }
        }
        // no more to add
        if (non_kernel_symbols.cardinal == previous_cardinal) break;
    }
    
    // expand non_kernel_symbols
    foreach (i, rule; grammar) {
        if (rule.lhs in non_kernel_symbols) result.add(LR0Item(i, 0));
    }
    return result;
}

LR0ItemSet _goto(inout const GrammarInfo grammar_info, inout LR0ItemSet item_set, inout Symbol symbol) {
    auto result = new LR0ItemSet();
    // goto(item_set, symbol) is defined to be the closure of all items [A -> sX.t]
    // such that X = symbol and [A -> s.Xt] is in item_set.
    foreach (item; item_set.array) {
        // A -> s. (dot is at the end)
        if (item.index == grammar_info.grammar[item.num].rhs.length) continue;
        else if (grammar_info.grammar[item.num].rhs[item.index] == symbol) result.add(LR0Item(item.num, item.index+1));
    }
    
    return closure(grammar_info, result);
}

// grammar_info.grammar is supposed to be augmented when passed to this function.
// Then grammar_info.grammar[$-1] is [S' -> S]
// and S' = grammar_info.max_symbol_num is supposed to be the grammar_info.max_symbol_number.
LR0ItemSet[] canonicalLR0Collection(inout const GrammarInfo grammar_info) {
    auto item_set_0 = grammar_info.closure( new LR0ItemSet(LR0Item(grammar_info.grammar.length-1,0)) );
    auto result = new LR0ItemSetSet (item_set_0);
    
    // these does not contain S'.
    auto appearings = grammar_info.appearings.array;
    if (appearings[$-1] == grammar_info.max_symbol_num) appearings.length -= 1;
    auto nonterminals = grammar_info.nonterminals.array;
    if (nonterminals[$-1] == grammar_info.max_symbol_num) nonterminals.length -= 1;
    
    size_t k = 0;
    auto result_list = [item_set_0];
    while (true) {
        auto previous_cardinal = result.cardinal;
        
        for (; k < previous_cardinal; ++k) {
            // add goto(I, X) for each I in result and symbol X
            foreach (symbol; appearings) {
                auto item_set = _goto(grammar_info, result_list[k], symbol);
                // new item_set
                if (item_set !in result && !item_set.empty) {
                    result.add(item_set);
                    result_list ~= item_set;
                }
            }
        }
        
        // nothing was added.
        if (result.cardinal == previous_cardinal) break;
    }
    return result_list;
}

// grammar_info.grammar is supposed to be augmented when passed to this function.
// Then grammar_info.grammar[$-1] is [S' -> S]
// and S' = grammar_info.max_symbol_num is supposed to be the grammar_info.max_symbol_number.
// This considers the conflict.
LRTableInfo SLRtableInfo(inout const GrammarInfo grammar_info) {
    auto collection = canonicalLR0Collection(grammar_info);
    auto result = new LRTableInfo(collection.length, grammar_info.max_symbol_num);
    auto grammar = grammar_info.grammar;
    
    foreach (i, item_set; collection) {
        foreach (item; item_set.array) {
            auto rule = grammar[item.num];
            // item is [X -> s.At]
            if (item.index < rule.rhs.length) {
                auto sym  = rule.rhs[item.index];
                // ignore empty
                if (sym < 0) continue;
                
                // goto(I_i, A) = I_j
                auto j = collection.countUntil(_goto(grammar_info, item_set, sym));
                // [i, sym] = goto j
                if (sym in grammar_info.nonterminals) result.add( LREntry(Action.goto_, j), i, sym );
                else                                  result.add( LREntry(Action.shift, j), i, sym );
            }
            // item is [X -> sA.]
            else {
                // X is not S'
                if (rule.lhs != grammar_info.start_sym) {
                    foreach (sym; grammar_info.follow(rule.lhs).array)
                        result.add( LREntry(Action.reduce, item.num), i, sym );
                }
                // X = S'
                else {
                   result.add( LREntry(Action.accept, 0), i, end_of_file_ );
                }
            }
        }
    }
    
    return result;
}
