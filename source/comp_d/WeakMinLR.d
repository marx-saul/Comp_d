// Reference: Pager, D.: A practical general method for constructing LR(k) parsers. Acta Informatica 7, 249-268 (1977).
module comp_d.WeakMinLR;

import comp_d.AATree, comp_d.Set, comp_d.tool, comp_d.data;
import comp_d.LR0ItemSet, comp_d.LRTable;
import std.typecons;
import std.array, std.container, std.container.binaryheap;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln, write;

public import comp_d.showWeakMinLR : showWeakMinimalLRtableInfo;

alias ItemGroupSet = AATree!(LR0Item, ItemLess, Set!Symbol);
bool ItemLess(LR0Item a, LR0Item b) {
    return (a.index < b.index) || (a.index == b.index && a.num < b.num);
}
unittest {
    /+
    enum : Symbol {
        S, C, c, d
    }
    static const grammar_info = new GrammarInfo([
        rule(S, empty_),
        rule(S, C, C),
        rule(C, c, C),
        rule(C, d),
    ], ["S", "C", "c", "d"]);
    +/
    
    enum : Symbol { X, Y, Z, T, W, V, a, b, c, d, e, t, u }
    static const grammar_info = new GrammarInfo([
        rule(X, a, Y, d), rule(X, a, Z, c), rule(X, a, T), rule(X, b, Y, e), rule(X, b, Z, d), rule(X, b, T),
        rule(Y, t, W), rule(Y, u, X),
        rule(Z, t, u),
        rule(T, u, X, a),
        rule(W, u, V),
        rule(V, empty_),           
    ], ["X", "Y", "Z", "T", "W", "V", "a", "b", "c", "d", "e", "t", "u"]);
    
    import comp_d.LR;
    static const table_info = weakMinimalLRtableInfo(grammar_info);
    showWeakMinimalLRtableInfo(grammar_info);
    
    writeln("## WeakMinLR unittest 1");
}

bool isSameState(ItemGroupSet a, ItemGroupSet b) {
    auto a_core = a.array, b_core = b.array;
    
    // core equality check
    if (a_core.length != b_core.length) return false;
    foreach (i; 0 .. a_core.length) {
        if (a_core[i] != b_core[i]) return false;
    }
    
    // equality check
    foreach (i; 0 .. a_core.length) {
        if (!equal(a[a_core[i]].array, b[b_core[i]].array)) return false;
    }
    
    return true;
}

// check whether they have the same core and weakly compatible
bool isWeaklyCompatible(const ItemGroupSet a, const ItemGroupSet b) {
    auto a_core = a.array, b_core = b.array;
    
    // core equality check
    if (a_core.length != b_core.length) return false;
    foreach_reverse (i; 0 .. a_core.length) {
        if (a_core[i] != b_core[i]) return false;
        // extract nucleus (ItemGroupSet.array gives an array whose items are in the descending order of dot index (see ItemLess) )
        if (a_core[i].index == 0 && b_core[i].index == 0) {
            a_core = a_core[i+1 .. $];
            b_core = b_core[i+1 .. $];
            break;
        }
    }
    
    // weak-compatibility check
    foreach (i; 0 .. a_core.length) foreach (j; i+1 .. a_core.length) {
        if (  (a[a_core[i]] & b[b_core[j]]).empty &&  (a[a_core[j]] & b[b_core[i]]).empty ) continue;
        if ( !(a[a_core[i]] & a[a_core[j]]).empty || !(b[b_core[i]] & b[b_core[j]]).empty ) continue;
        return false;
    }
    return true;
}

package void closure(const GrammarInfo grammar_info, ItemGroupSet item_group_set) {
    auto grammar = grammar_info.grammar;
    
    while (true) {
        bool nothing_to_add = true;
        
        // for all [A -> s.Bt, a] in item set and rule B -> u,
        // add [B -> .u, b] where a terminal symbol b is in FIRST(ta)
        foreach (item; item_group_set.array) {
            // . is at the last
            if (item.index >= grammar[item.num].rhs.length) continue;
            
            auto B = grammar[item.num].rhs[item.index];
            auto first_set = grammar_info.first( grammar[item.num].rhs[item.index+1 .. $] );
            
            foreach (i, rule; grammar) {
                // find all rules starting with B
                if (rule.lhs != B) continue;
                
                if (!item_group_set.hasKey(LR0Item(i, 0))) {
                    item_group_set[LR0Item(i, 0)] = new Set!Symbol();
                    nothing_to_add = false;
                }
                
                auto previous_cardinal = item_group_set[LR0Item(i, 0)].cardinal;
                item_group_set[LR0Item(i, 0)].add(first_set.array);
                // a in FIRST(ta)
                if (empty_ in first_set) {
                    item_group_set[LR0Item(i, 0)] += item_group_set[item];
                    item_group_set[LR0Item(i, 0)].remove(empty_);
                }
                if (item_group_set[LR0Item(i, 0)].cardinal > previous_cardinal) nothing_to_add = false;
            }
        }
        
        if (nothing_to_add) break;
    }
}

package ItemGroupSet _goto(const GrammarInfo grammar_info, inout ItemGroupSet item_group_set, inout Symbol symbol) {
    auto result = new ItemGroupSet();
    // goto(item_set, symbol) is defined to be the closure of all items [A -> sX.t]
    // such that X = symbol and [A -> s.Xt] is in item_set.
    foreach (item; item_group_set.array) {
        // A -> s. (dot is at the end)
        if (item.index >= grammar_info.grammar[item.num].rhs.length) continue;
        else if (grammar_info.grammar[item.num].rhs[item.index] == symbol) result[LR0Item(item.num, item.index+1)] = item_group_set[item];
    }
    closure(grammar_info, result);
    return result;
}

LRTableInfo weakMinimalLRtableInfo(const GrammarInfo grammar_info) {
    auto grammar = grammar_info.grammar;
    LRTableInfo result = new LRTableInfo(1, grammar_info.max_symbol_num);
    
    // starting state
    auto starting_state = new ItemGroupSet();
    starting_state[LR0Item(grammar_info.grammar.length-1, 0)] = new Set!Symbol(end_of_file_);
    closure(grammar_info, starting_state);
    auto state_list = [starting_state];
    
    auto appearings = grammar_info.appearings.array;
    // goto_of[sym] is the list of states that are gotos of some state by the sym.
    auto goto_of = new AATree!(Symbol, (a,b) => a<b, size_t[]);
    foreach (symbol; appearings) { goto_of[symbol] = []; }
    
    size_t k = 0;
    // calculate states
    while (true) {
        auto state_length = state_list.length;
        bool end_flag = true;
        for (; k < state_length; k++) foreach (symbol; appearings) {
            
            // calculate goto(I, X) for each X
            auto item_set = _goto(grammar_info, state_list[k], symbol);
            if (item_set.empty) continue;
            
            ////////////////////////////
            // a state already appeared
            auto index1 = countUntil!(x => isSameState(x, item_set))(state_list);
            if (index1 != -1) {
                goto_of[symbol] ~= index1;
                // shift and goto
                if (symbol in grammar_info.terminals) { result.add( LREntry(Action.shift, index1), k, symbol ); }
                else { result.add(LREntry(Action.goto_, index1), k, symbol); }
                continue;
            }
            
            end_flag = false;
            
            /////////////////////////////////////
            // check whether it is weakly compatible with previous one
            auto index2 = countUntil!(i => isWeaklyCompatible(state_list[i], item_set))(goto_of[symbol]);   // the index in goto_of
            
            /////////////
            // new state
            if (index2 == -1) {
                state_list ~= item_set;
                result.addState();
                goto_of[symbol] ~= state_list.length-1;
                // goto and shift
                if (symbol in grammar_info.nonterminals) { result.add( LREntry(Action.goto_, state_list.length-1), k, symbol ); }
                else { result.add(LREntry(Action.shift, state_list.length-1), k, symbol); }
                
                continue;
            }
            
            ////////////////////
            // weakly compatible
            index2 = goto_of[symbol][index2];   // rewrite to the index in state_list (item_set is compatible with state_list[index2])
            
            // goto and shift
            if (symbol in grammar_info.nonterminals) { result.add( LREntry(Action.goto_, index2), k, symbol ); }
            else { result.add(LREntry(Action.shift, index2), k, symbol); }
            
            ////////
            // propagately merge states
            
            // initialize
            // enlarged item-groups and their lookaheads' difference by merging
            auto enlarged = new ItemGroupSet(), core = state_list[index2].array;
            //assert (equal(core, item_set.array));
            foreach (item; core) {
                // . is at the extreme left
                if (item.index == 0) continue;
                auto diff = item_set[item] - state_list[index2][item];
                if (diff.empty) continue;
                enlarged[item] = diff;
            }
            
            size_t[]       changed_states_queue = [index2];     // the index of state that will be changed.
            ItemGroupSet[] difference_queue     = [enlarged];   // lookahead symbol 
            
            // propagate re-generation of goto
            while (!changed_states_queue.empty) {
                auto item_number      = changed_states_queue[0];
                auto difference_set   = difference_queue[0];
                
                auto item_group = state_list[item_number];  // the state that will be changed
                
                //////////
                // merge
                foreach (item; difference_set.array) {
                    item_group[item] += difference_set[item];
                }
                // take its closure
                closure(grammar_info, item_group);
                
                //////////
                // collect gotos of 'item_group' that will change
                auto new_lookaheads = new AATree!(Symbol, (a,b) => a < b, ItemGroupSet);
                foreach (item; difference_set.array) {
                    if (item.index >= grammar[item.num].rhs.length) continue;
                    
                    // the symbol immediately after the dot .
                    auto sym = grammar[item.num].rhs[item.index];
                    auto item2 = LR0Item(item.num, item.index+1);
                    
                    // goto(item_group, sym) is not empty
                    if (!result.table[item_number, sym].action.among!(Action.shift, Action.goto_)) continue;
                    
                    if (!new_lookaheads.hasKey(sym)) new_lookaheads[sym] = new ItemGroupSet();
                    new_lookaheads[sym][item2] = difference_set[item];
                }
                
                foreach (sym; new_lookaheads.array) {
                    changed_states_queue ~= result.table[item_number, sym].num;
                    difference_queue ~= new_lookaheads[sym];
                    //assert ( isWeaklyCompatible(state_list[result.table[item_number, sym].num], new_lookaheads[sym]) );
                }
                changed_states_queue = changed_states_queue [1 .. $];
                difference_queue     = difference_queue     [1 .. $];
            }
            
        }
        
        if (end_flag) break;
    }
    
    // reduce
    foreach (i, item_group_set; state_list) {
        foreach (item; item_group_set.array) {
            // . is not at the extreme right
            if (item.index < grammar[item.num].rhs.length || (item.index == 0 && grammar[item.num].rhs[0] == empty_)) continue;
            else
                foreach (sym; item_group_set[item].array) {
                    // not S'
                    if (grammar[item.num].lhs != grammar_info.start_sym) result.add(LREntry(Action.reduce, item.num), i, sym);
                    else result.add(LREntry(Action.accept, item.num), i, end_of_file_);
                }
            
        }
    }
    
    return result;
}
