module comp_d.LR;

import comp_d.LR1ItemSet, comp_d.LRTable, comp_d.tool, comp_d.data;
import std.typecons;
import std.array, std.container, std.container.binaryheap;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln, write;
import std.conv: to;

// grammars that passed to the functions must be augmented.

unittest {
    enum : Symbol {
        S, C, c, d
    }
    auto grammar_info = new GrammarInfo([
        rule(S, empty_),
        rule(S, C, C),
        rule(C, c, C),
        rule(C, d),
    ], ["S", "C", "c", "d"]);
    /*
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
    */
    
    auto table_info = LRtableInfo(grammar_info);
    showLRtableInfo(grammar_info);
    writeln("## LR.d unittest 1");
}


unittest {
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
    
    auto table_info = LRtableInfo(grammar_info);
    showLRtableInfo(grammar_info);
    writeln("## LR.d unittest 2");
}

// replace item_set by its closure
package pure void closure(const GrammarInfo grammar_info, LR1ItemSet item_set) {
    auto grammar = grammar_info.grammar;
    
    while (true) {
        auto previous_cardinal = item_set.cardinal;
        // for all [A -> s.Bt, a] in item set and rule B -> u,
        // add [B -> .u, b] where a terminal symbol b is in FIRST(ta)
        foreach (item; item_set.array) {
            // . is at the end
            if (item.index >= grammar[item.num].rhs.length) continue;
            
            auto B = grammar[item.num].rhs[item.index];
            foreach (i, rule; grammar) {
                if (rule.lhs != B) continue;
                // symbol = b
                foreach (symbol; grammar_info.first( grammar[item.num].rhs[item.index+1 .. $] ~ [item.lookahead] ).array )
                    item_set.add(LR1Item(i, 0, symbol));
            }
        }
        // nothing was added
        if (item_set.cardinal == previous_cardinal) break;
    }
}

package pure LR1ItemSet _goto(const GrammarInfo grammar_info, inout LR1ItemSet item_set, inout Symbol symbol) {
    auto result = new LR1ItemSet();
    // goto(item_set, symbol) is defined to be the closure of all items [A -> sX.t]
    // such that X = symbol and [A -> s.Xt] is in item_set.
    foreach (item; item_set.array) {
        // A -> s. (dot is at the end)
        if (item.index == grammar_info.grammar[item.num].rhs.length) continue;
        else if (grammar_info.grammar[item.num].rhs[item.index] == symbol) result.add(LR1Item(item.num, item.index+1, item.lookahead));
    }
    
    closure(grammar_info, result);
    return result;
}

// grammar_info.grammar is supposed to be augmented when passed to this function.
// Then grammar_info.grammar[$-1] is [S' -> S]
// and S' = grammar_info.max_symbol_num is supposed to be the grammar_info.max_symbol_number.
package pure LR1ItemSet[] canonicalLR1Collection(const GrammarInfo grammar_info) {
    auto item_set_0 = new LR1ItemSet(LR1Item(grammar_info.grammar.length-1, 0, end_of_file_));
    grammar_info.closure( item_set_0 );
    auto result = new LR1ItemSetSet (item_set_0);
    
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
pure LRTableInfo LRtableInfo(inout const GrammarInfo grammar_info) {
    return LRtableInfo(grammar_info, canonicalLR1Collection(grammar_info));
}

private pure LRTableInfo LRtableInfo(const GrammarInfo grammar_info, const LR1ItemSet[] collection) {
    auto result = new LRTableInfo(collection.length, grammar_info.max_symbol_num);
    auto grammar = grammar_info.grammar;
    
    foreach (i, item_set; collection) {
        foreach (item; item_set.array) {
            auto rule = grammar[item.num];
            // item is  [X -> s.At]
            if (item.index < rule.rhs.length) {
                auto sym  = rule.rhs[item.index];
                // if empty, i.e. [A -> .ε], then action[i,a] = reduce for all a in FOLLOW(A)
                if (sym == empty_) {
                    result.add( LREntry(Action.reduce, item.num), i, item.lookahead );
                    continue;
                }
                
                // goto(item_set, A) = item_set2
                auto item_set2 = _goto(grammar_info, item_set, sym);
                if (item_set2.cardinal == 0) continue;
                
                //countUntil is impure
                //auto j = collection.countUntil(_goto(grammar_info, item_set, sym));
                size_t j;
                auto goto_item_set = _goto(grammar_info, item_set, sym);
                foreach (j_index, j_item_set; collection) {
                    if (j_item_set.opEquals(goto_item_set)) {
                        j = j_index;
                        break;
                    }
                }
                
                // [i, sym] = goto j
                if (sym in grammar_info.nonterminals) result.add( LREntry(Action.goto_, j), i, sym );   // As goto is empty if . is at the end
                else                                  result.add( LREntry(Action.shift, j), i, sym );
            }
            // item is [X -> s.]
            else {
                // X is not S'
                if (rule.lhs != grammar_info.start_sym)
                    result.add( LREntry(Action.reduce, item.num), i, item.lookahead );
                // X = S'
                else
                   result.add( LREntry(Action.accept, 0), i, end_of_file_ );
            }
        }
    }
    
    return result;
}


// When conflict occurs, one can use this function to see where the conflict occurs
void showLRtableInfo(const GrammarInfo grammar_info, const LRTableInfo table_info) {
    auto grammar = grammar_info.grammar;
    auto collection = canonicalLR1Collection(grammar_info);
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
            writeln("], ", grammar_info.nameOf(item.lookahead));
        }
        writeln("},");
    }
    
    // show the table
    //auto table_info = LRtableInfo(grammar_info, collection);
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
            else if (act == Action.goto_)  { write("\033[1m\033[32mg\033[0m-", entry.num, ", "); }
        }
        writeln();
    }
}

void showLRtableInfo(const GrammarInfo grammar_info) {
    auto collection = canonicalLR1Collection(grammar_info);
    showLRtableInfo(grammar_info, LRtableInfo(grammar_info, collection));
}
