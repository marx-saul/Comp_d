module comp_d.LALR;

import comp_d.SLR: closure, _goto, canonicalLR0Collection, SLRtableInfo;
import comp_d.LR : closure;
import comp_d.LR0ItemSet, comp_d.LR1ItemSet, comp_d.LRTable, comp_d.tool, comp_d.data;
import std.typecons;
import std.array, std.container, std.container.binaryheap;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln, write;

// grammars that passed to these functions must be augmented.

unittest{
    writeln("## LALR unittest 1");
}

LR0ItemSet lookaheads(LR0ItemSet item_set) {
    auto result = new LR0ItemSet();
    return result;
}

// grammar_info.grammar is supposed to be augmented when passed to this function.
// Then grammar_info.grammar[$-1] is [S' -> S]
// and S' = grammar_info.max_symbol_num is supposed to be the grammar_info.max_symbol_number.
// This considers the conflict.
LRTableInfo LALRtableInfo(inout const GrammarInfo grammar_info) {
    auto result = SLRtableInfo(grammar_info);
    auto state_num = result.state_num;
    
    // 
    auto propagates = new SymbolSet[state_num];
    
    // inner-generate
    
    
    return result;
}

/+
// grammar_info.grammar is supposed to be augmented when passed to this function.
// Then grammar_info.grammar[$-1] is [S' -> S]
// and S' = grammar_info.max_symbol_num is supposed to be the grammar_info.max_symbol_number.
// This considers the conflict.
LRTableInfo LALRtableInfo(inout const GrammarInfo grammar_info) {
    auto collection = canonicalLR0Collection(grammar_info);
    auto result = new LRTableInfo(collection.length, grammar_info.max_symbol_num);
    auto grammar = grammar_info.grammar;
    
    foreach (i, item_set; collection) {
        foreach (item; item_set.array) {
            auto rule = grammar[item.num];
            // item is  [X -> s.At]
            if (item.index < rule.rhs.length) {
                auto sym  = rule.rhs[item.index];
                // ignore empty
                if (sym < 0) continue;
                
                // goto(item_set, A) = item_set2
                auto item_set2 = _goto(grammar_info, item_set, sym);
                if (item_set2.cardinal == 0) continue;
                
                auto j = collection.countUntil(_goto(grammar_info, item_set, sym));
                // [i, sym] = goto j
                if (sym in grammar_info.nonterminals) result.add( LREntry(Action.goto_, j), i, sym );   // As goto is empty if . is at the end
                else                                  result.add( LREntry(Action.shift, j), i, sym );
            }
            // item is [X -> s.]
            else {
                // X is not S'
                if (rule.lhs != grammar_info.start_sym)
                    foreach (sym; grammar_info.follow(rule.lhs).array)
                        result.add( LREntry(Action.reduce, item.num), i, sym );
                // X = S'
                else
                   result.add( LREntry(Action.accept, 0), i, end_of_file_ );
            }
        }
    }
    
    return result;
}
+/
/+
// When conflict occurs, one can use this function to see where the conflict occurs
void showLALRtableInfo(inout const GrammarInfo grammar_info) {
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
    auto table_info = SLRtableInfo(grammar_info);
    auto table = table_info.table;
    auto symbols_array = grammar_info.terminals.array ~ [end_of_file_] ~ grammar_info.nonterminals.array[0 .. $-1] ;
    foreach (sym; symbols_array) {
        write("\t", grammar_info.nameOf(sym));
    }
    writeln();
    
    alias Index2 = Tuple!(State, "state", Symbol, "symbol");
    Index2[] conflictings;
    
    foreach (i; 0 .. table.state_num) {
        write(i, ":\t");
        foreach (sym; symbols_array) {
            auto act = table[i, sym].action;
            // conflict
            if (table_info[i, sym].cardinal > 1) { write("\033[1m\033[31mcon\033[0m, \t"); conflictings ~= Index2(i, sym); }
            else if (act == Action.error)  { write("err, \t"); }
            else if (act == Action.accept) { write("\033[1m\033[37macc\033[0m, \t"); }
            else if (act == Action.shift)  { write("\033[1m\033[36ms\033[0m-", table[i, sym].num, ", \t"); }
            else if (act == Action.reduce) { write("\033[1m\033[33mr\033[0m-", table[i, sym].num, ", \t"); }
            else if (act == Action.goto_)  { write("\033[1m\033[32mg\033[0m-", table[i, sym].num, ", \t"); }
        }
        writeln();
    }
    
    foreach (index2; conflictings) {
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
}+/
