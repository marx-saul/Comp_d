module comp_d.LALR;

import comp_d.SLR: canonicalLR0Collection, SLRtableInfo;
import comp_d.LR : closure;
import comp_d.LR0ItemSet, comp_d.LR1ItemSet, comp_d.LRTable;
import comp_d.Set, comp_d.tool, comp_d.data;

import std.typecons;
import std.array, std.container, std.container.binaryheap;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln, write;

// grammars that passed to these functions must be augmented.
unittest{
    enum : Symbol {
        S, L, R, eq, star, id
    }
    auto grammar_info = new GrammarInfo([
        rule(S, L, eq, R),
        rule(S, R),
        rule(L, star, R),
        rule(L, id),
        rule(R, L),
    ], ["S", "L", "R", "=", "*", "id"]);
    
    auto table_info = LALRtableInfo(grammar_info);
    showLALRtableInfo(grammar_info);
    writeln("## LALR.d unittest 1");
}

alias LookAhead = Tuple!(size_t, "i", size_t, "j", Symbol, "symbol");
private pure @nogc @safe bool lookAheadLess(LookAhead a, LookAhead b) {
    return a.i < b.i || (a.i == b.i && a.j < b.j) || (a.i == b.i && a.j == b.j && a.symbol < b.symbol);
}
alias LookAheadSet = Set!(LookAhead, lookAheadLess);

// grammar_info.grammar is supposed to be augmented when passed to this function.
// Then grammar_info.grammar[$-1] is [S' -> S]
// and S' = grammar_info.max_symbol_num is supposed to be the grammar_info.max_symbol_number.
// This considers the conflict.
private pure LookAheadSet Propagates(const GrammarInfo grammar_info, const LR0ItemSet[] collection, const LRTableInfo table) {
    auto grammar = grammar_info.grammar;
    
    // kernel item is [S' -> .S] or an item whose dot is not at the start.
    bool isKernel (const LR0Item item) {
        return item == LR0Item(grammar.length-1, 0) || item.index > 0;
    }
    
    /*********************/
    // In this function, (i,j) refers to collection[i].array[j]
    /*********************/
    alias Index2 = Tuple!(size_t, "i", size_t, "j");
    
    // propagate_set[i][j] = { (i,j) } is the propagation item sets of collection[i].array[j]
    Index2[][][] propagate_set;
    
    Index2 indexOf(const LR0Item item) {
        foreach (i, item_set; collection) foreach (j, item2; item_set.array)
            if (item == item2) return Index2(i, j);
        assert(0);
    }
    
    // initialization
    propagate_set.length = collection.length;
    foreach (i; 0 .. collection.length) {
        propagate_set[i].length = collection[i].cardinal;
    }
    
    // (i, j, symbol) means that symbol have propagation symbol
    // add [S' -> .S], $
    auto tmp_ind = indexOf(LR0Item(grammar.length-1, 0));
    auto lookaheads = new LookAheadSet( LookAhead(tmp_ind.i, tmp_ind.j, end_of_file_) );
    
    
    // calculate all propagates and inner-generates(initialize to lookahead)
    foreach (i, item_set; collection) foreach (j, kernel_item; item_set.array) {
        if (!isKernel(kernel_item)) continue;
        
        // calculate the LR1-closure of each kernel item in LR0-collection with lookahead #.
        auto lookahead_item_set = new LR1ItemSet(LR1Item(kernel_item.num, kernel_item.index, virtual));
        closure(grammar_info, lookahead_item_set);
        foreach (LR1item; lookahead_item_set.array) {
            // . is at the last
            if (LR1item.index >= grammar[LR1item.num].rhs.length) continue;
            // ignore [A -> .ε]
            if (grammar[LR1item.num].rhs[LR1item.index] == empty_) continue;
            
            auto item = LR0Item(LR1item.num, LR1item.index+1);
            // for [A -> s.Bu] in I = item_set, propagate or inner-generate to [A -> sB.u] in goto(I,B).
            auto index_of_item_i = table.table[i, grammar[LR1item.num].rhs[LR1item.index]].num;
            auto index_of_item_j = countUntil(collection[index_of_item_i].array, item);
            auto index_of_item = Index2(index_of_item_i, index_of_item_j);
            
            // propagate
            if (LR1item.lookahead == virtual) { propagate_set[i][j] ~= index_of_item; }
            // inner-generate
            else { lookaheads.add( LookAhead(index_of_item.i, index_of_item.j, LR1item.lookahead) ); }
        }
    }
    
    // execute propagates until there is nothing to.
    while (true) {
        auto previous_cardinal = lookaheads.cardinal;
        foreach (lookahead; lookaheads.array) {
            auto i = lookahead.i, j = lookahead.j, symbol = lookahead.symbol;
            // execute propagate (propagate_set[i][j] is the set of items where the lookahead propagate.)
            foreach (index2; propagate_set[i][j]) {
                lookaheads.add(LookAhead(index2.i, index2.j, lookahead.symbol));
                //writeln(i, " ", j, " to ", index2.i, " ", index2.j);
            }
        }
        // nothing was added.
        if (lookaheads.cardinal == previous_cardinal) break;
    }
    
    return lookaheads;
}

// grammar_info.grammar is supposed to be augmented when passed to this function.
// Then grammar_info.grammar[$-1] is [S' -> S]
// and S' = grammar_info.max_symbol_num is supposed to be the grammar_info.max_symbol_number.
// This considers the conflict.
pure LRTableInfo LALRtableInfo(const GrammarInfo grammar_info) {
    return LALRtableInfo(grammar_info, canonicalLR0Collection(grammar_info));
}

private pure LRTableInfo LALRtableInfo(const GrammarInfo grammar_info, const LR0ItemSet[] collection) {
    auto result = SLRtableInfo(grammar_info, collection);
    auto lookaheads = Propagates(grammar_info, collection, result);
    auto lookaheads_array = lookaheads.array;
    
    foreach (entry_index; result.conflictings) {
        auto state = entry_index.state, symbol = entry_index.symbol;
        // solve the shift/reduce confliction
        if ( result.table[state, symbol].action == Action.shift
          && lookaheads_array.filter!(a => a.i == state).all!(a => a.symbol != symbol) )
        {
            // determine to shift
            result[state, symbol] = result.table[state, symbol];
        }   
    }
    
    return result;
}

// When conflict occurs, one can use this function to see where the conflict occurs
void showLALRtableInfo(const GrammarInfo grammar_info, const LRTableInfo table_info) {
    auto grammar = grammar_info.grammar;
    auto collection = canonicalLR0Collection(grammar_info);
    // show the collection
    foreach (k, item_set; collection.array) {
        // write item
        writeln("ITEM-", k, " = {");
        foreach (item; item_set.array) {
            auto rule = grammar[item.num];
            if (item.num == grammar.length-1) write("\t\033[1m\033[31m", item.num, "\033[0m");
            else write("\t", item.num);
            write(": [", grammar_info.nameOf(rule.lhs), "  ->  ");
            foreach (l; 0 .. item.index)               write(grammar_info.nameOf(rule.rhs[l]), " ");
            write("\b\033[1m\033[37m.\033[0m");
            foreach (l; item.index .. rule.rhs.length) write(grammar_info.nameOf(rule.rhs[l]), " ");
            writeln("], ");
        }
        writeln("},");
    }
    
    // show the table
    //auto table_info = LALRtableInfo(grammar_info, collection);
    auto table = table_info.table;
    auto symbols_array = grammar_info.terminals.array ~ [end_of_file_] ~ grammar_info.nonterminals.array[0 .. $-1] ;
    foreach (sym; symbols_array) {
        write("\t", grammar_info.nameOf(sym));
    }
    writeln();
    foreach (i; 0 .. table.state_num) {
        write(i, ":\t");
        foreach (sym; symbols_array) {
            auto act = table[i, sym].action;
            // conflict
            if (table_info.is_conflicting(i, sym)) { write("\033[1m\033[31mcon\033[0m, \t"); }
            else if (act == Action.error)  { write("err, \t"); }
            else if (act == Action.accept) { write("\033[1m\033[37macc\033[0m, \t"); }
            else if (act == Action.shift)  { write("\033[1m\033[36ms\033[0m-", table[i, sym].num, ", \t"); }
            else if (act == Action.reduce) { write("\033[1m\033[33mr\033[0m-", table[i, sym].num, ", \t"); }
            else if (act == Action.goto_)  { write("\033[1m\033[32mg\033[0m-", table[i, sym].num, ", \t"); }
        }
        writeln();
    }
    //writeln(table_info.is_conflict);
    foreach (index2; table_info.conflictings) {
        auto i = index2.state; auto sym = index2.symbol;
        write("action[", i, ", ", grammar_info.nameOf(sym), "] : ");
        foreach (entry; table_info[i, sym].array) {
            auto act = entry.action;
            if      (act == Action.error)  { write("err, "); }
            else if (act == Action.accept) { write("\033[1m\033[37macc\033[0m, "); }
            else if (act == Action.shift)  { write("\033[1m\033[36ms\033[0m-", entry.num, ", "); }
            else if (act == Action.reduce) { write("\033[1m\033[33mr\033[0m-", entry.num, ", "); }
            else if (act == Action.goto_)  { assert(0); /*write("\033[1m\033[32mg\033[0m-", entry.num, ", ");*/ }
        }
        writeln();
    }
}

void showLALRtableInfo(const GrammarInfo grammar_info) {
    auto collection = canonicalLR0Collection(grammar_info);
    showLALRtableInfo(grammar_info, LALRtableInfo(grammar_info, collection));
}
