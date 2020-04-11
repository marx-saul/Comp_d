// Reference: Pager, D.: A practical general method for constructing LR(k) parsers. Acta Informatica 7, 249-268 (1977).
module comp_d.StrongMinLR;

import comp_d.AATree, comp_d.Set, comp_d.tool, comp_d.data;
import comp_d.LR0ItemSet, comp_d.LRTable;
import comp_d.WeakMinLR: closure, _goto, isSameState, ItemGroupSet;

import std.typecons;
import std.array, std.container, std.container.binaryheap;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln, write;

alias FEntry = Tuple!(Symbol, size_t, size_t);
pure bool FEntryLess(FEntry a, FEntry b) {
    return (a[0] < b[0]) || (a[0] == b[0] && a[1] < b[1]) || (a[0] == b[0] && a[1] == b[1] && a[2] < b[2]);
}
alias FSet = AATree!(FEntry, FEntryLess, bool);


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
    
    auto table_info = strongMinimalLRtableInfo(grammar_info);
    showStrongMinimalLRtableInfo(grammar_info);
    
    writeln("## StrongMinLR.d unittest 1");
}

unittest {
    enum : Symbol { S, A, B, C, D, E, F, X, Y, Z, a, b, c, d, f }
    auto grammar_info = new GrammarInfo([
        rule(S, a, Z, a), rule(S, b, Z, c), rule(S, a, X, b), rule(S, b, X, d), rule(S, a, Y, d), rule(S, b, Y, a), 
        rule(A, a, D, F),
        rule(B, b),
        rule(C, a, D, f),
        rule(D, d),
        rule(E, empty_),
        rule(F, empty_),
        rule(X, a, A, E),
        rule(Y, a, B),
        rule(Z, a, C),
    ], ["S", "A", "B", "C", "D", "E", "F", "X", "Y", "Z", "a", "b", "c", "d", "f"]);
    
    auto table_info = strongMinimalLRtableInfo(grammar_info);
    showStrongMinimalLRtableInfo(grammar_info);
    
    writeln("## StrongMinLR.d unittest 2");
}

unittest {
    enum : Symbol { X, Y, Z, T, W, V, a, b, c, d, e, t, u }
    auto grammar_info = new GrammarInfo([
        rule(X, a, Y, d), rule(X, a, Z, c), rule(X, a, T), rule(X, b, Y, e), rule(X, b, Z, d), rule(X, b, T),
        rule(Y, t, W), rule(Y, u, X),
        rule(Z, t, u),
        rule(T, u, X, a),
        rule(W, u, V),
        rule(V, empty_),           
    ], ["X", "Y", "Z", "T", "W", "V", "a", "b", "c", "d", "e", "t", "u"]);
    
    auto table_info = strongMinimalLRtableInfo(grammar_info);
    showStrongMinimalLRtableInfo(grammar_info);
    
    writeln("## StrongMinLR.d unittest 3");
}

unittest {
    enum : Symbol { S, X, Y, B, a, b }
    auto grammar_info = new GrammarInfo([
        rule(S, a, Y, a), rule(S, a, X, b), rule(S, b, Y, b), rule(S, b, X, a),
        rule(X, a, B),
        rule(Y, a, b),
        rule(B, b),
    ], ["S", "X", "Y", "B", "a", "b"]);
    
    auto table_info = strongMinimalLRtableInfo(grammar_info);
    showStrongMinimalLRtableInfo(grammar_info);
    
    writeln("## StrongMinLR.d unittest 4");
}

// check whether they have the same core and strongly compatible
package pure bool isStronglyCompatible(const ItemGroupSet a, const ItemGroupSet b, const GrammarInfo grammar_info, FSet fset) {
    auto a_core = a.keys, b_core = b.keys;
    
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
    
    // weak-compatibility check (weak => strong)
    foreach (i; 0 .. a_core.length) foreach (j; i+1 .. a_core.length) {
        if (  (a[a_core[i]] & b[b_core[j]]).empty &&  (a[a_core[j]] & b[b_core[i]]).empty ) continue;
        if ( !(a[a_core[i]] & a[a_core[j]]).empty || !(b[b_core[i]] & b[b_core[j]]).empty ) continue;
        goto strong_comp_check;
    }
    return true;
    
    // strong-compatibility check
    strong_comp_check:
    auto grammar = grammar_info.grammar;
    import std.algorithm.mutation: reverse;
    
    /+ Tail is not obtained as follows:
    SymbolSet[] tail_a, tail_b;
    foreach (i; 0 .. a_core.length) {
        auto string_a = grammar[a_core[i].num].rhs[a_core[i].index .. $].dup;
        auto string_b = grammar[b_core[i].num].rhs[b_core[i].index .. $].dup;
        tail_a ~= grammar_info.first(string_a.reverse);
        tail_b ~= grammar_info.first(string_b.reverse);
    }
    +/
    
    foreach (i; 0 .. a_core.length) {
        foreach (j; i+1 .. a_core.length) {
            // TAIL(scanned_a) & TAIL(scanned_b) = φ
            //if ((tail_a[i] & tail_b[j]).cardinal == 0) continue;
            
            // scanned_a ( = grammar[a_core[i].num].rhs[a_core[i].index .. $]) and scanned_b have shared decendant.
            if (check(a_core[i].num, a_core[i].index, b_core[j].num, b_core[j].index, grammar_info, fset)) return false;
        }
    }
    
    return true;
}

private pure bool check(size_t num1, size_t index1, size_t num2, size_t index2, const GrammarInfo grammar_info, FSet fset) {
    if (num1 == num2 && index1 == index2) return false;
    
    auto grammar = grammar_info.grammar;
    
    auto str1 = grammar[num1].rhs[index1 .. $], str2 = grammar[num2].rhs[index2 .. $];
    //writeln("str1 = ", str1.map!(i => grammar_info.nameOf(i)), "\n", "str2 = ", str2.map!(i => grammar_info.nameOf(i)));
    if (equal(str1, str2)) return true;
    
    // str1[s] does not generate empty, while str1[s+1], ... str1[$-1] does
    // str2[t] does not generate empty, while str2[t+1], ... str2[$-1] does
    // str1[0] == str2[0] && ... && str1[match] == str2[match] && str1[match+1] != str2[match+1] 
    size_t s = 0, t = 0;
    bool s_flag = false, t_flag = false;
    foreach_reverse (i; 0 .. str1.length)
        if (empty_ !in grammar_info.first([str1[i]])) {
            s = i;
            s_flag = true;
            break;
        }
    foreach_reverse (i; 0 .. str2.length)
        if (empty_ !in grammar_info.first([str2[i]])) {
            t = i;
            t_flag = true;
            break;
        }
    
    // coincide
    if (s_flag && t_flag && equal(str1[0 .. s+1], str2[0 .. t+1])) return true;
    
    // str1[0] == str2[0] && ... && str1[match] == str2[match] && str1[match+1] != str2[match+1]
    size_t match = 0;
    bool match_flag = false;
    foreach (i; 0 .. min(str1.length, str2.length))
        if (str1[i] == str2[i]) {
            match = i;
            match_flag = true;
        }
        else break;
    
    
    // trivial checks
    
    // all generate empty
    if (!s_flag && !t_flag) return false;
    // str1 =>(strong rightmost) str1[0] ... str1[match] (match+1 >= s+1)
    //                             ||             ||
    // str2 =>(strong rightmost) str2[0] ... str2[match] (match+1 >= t+1)
    else if (match_flag && match >= max(s,t)) return true;
    
    
    // Write str1 = a0 a1 ... an, str2 = b0 b1 ... bm.
    // Check if there exist i >= s and j >= t such that 
    // i >= j, j-1 <= match and [A -> α a0 a1 ... aj-1 . aj ... an] and some [bj -> .ω] share descendant
    //  or
    // i <= j, i-1 <= match and [B -> β b0 b1 ... bi-1 . bi ... bm] and some [ai -> .ω] share descendant,
    // where [A -> α.str1] and [B -> β.str2] correspond to LR0Item(num1, index1) and LR0Item(num2, index2) respectively.
    //writeln(s, " ", str1.length, " ", t, " ", str2.length);
    foreach (i; s .. str1.length) foreach (j; t .. str2.length) {
        //writeln("i = ", i, ", j = ", j);
        //writeln("str1[i] = ", grammar_info.nameOf(str1[i]), ", str2[j] = ", grammar_info.nameOf(str2[j]));
        if ( i >= j && (j == 0 || (match_flag && j-1 <= match)) ) {
            if (str2[j] in grammar_info.nonterminals)
                foreach (rule_num, rule; grammar) if (rule.lhs == str2[j]) {
                    //writeln("here184 ", rule_num);
                    bool check_result;
                    auto fentry = FEntry(rule_num, num1, index1+j);
                    if (!fset.hasKey(fentry))
                        check_result = fset[fentry] = check(rule_num, 0, num1, index1+j, grammar_info, fset);
                    else
                        check_result = fset[fentry];
                    
                    if (check_result) return true; 
                }
        }
        if ( i <= j && (i == 0 || (match_flag && i-1 <= match)) ) {
            if (str1[i] in grammar_info.nonterminals)
                foreach (rule_num, rule; grammar) if (rule.lhs == str1[i]) {
                    //writeln("here198 ", rule_num);
                    bool check_result;
                    auto fentry = FEntry(rule_num, num2, index2+j);
                    if (!fset.hasKey(fentry))
                        check_result = fset[fentry] = check(rule_num, 0, num2, index2+i, grammar_info, fset);
                    else
                        check_result = fset[fentry];
                    
                    if (check_result) return true; 
                }
        }
    }
    
    return false;
}

pure LRTableInfo strongMinimalLRtableInfo(const GrammarInfo grammar_info) {
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
    
    // for strong compatibility check
    auto fset = new FSet;
    
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
            // countUnitl is impure
            //auto index1 = countUntil!(x => isSameState(x, item_set))(state_list);
            size_t index1 = state_list.length;
            foreach (i, x; state_list) {
                if (isSameState(x, item_set)) {
                    index1 = i;
                    break;
                }
            }
            
            if (index1 != state_list.length) {
                goto_of[symbol] ~= index1;
                // shift and goto
                if (symbol in grammar_info.terminals) { result.add( LREntry(Action.shift, index1), k, symbol ); }
                else { result.add(LREntry(Action.goto_, index1), k, symbol); }
                continue;
            }
            
            end_flag = false;
            
            /////////////////////////////////////
            // check whether it is strongly compatible with previous one
            //auto index2 = countUntil!(ind => isStronglyCompatible(state_list[ind], item_set, grammar_info, fset))(goto_of[symbol]);   // the index in goto_of
            size_t index2 = goto_of[symbol].length;
            foreach (i, ind; goto_of[symbol]) {
                if (isStronglyCompatible(state_list[ind], item_set, grammar_info, fset)) {
                    index2 = i;
                    break;
                }
            }
            
            /////////////
            // new state
            if (index2 == goto_of[symbol].length) {
                state_list ~= item_set;
                result.addState();
                goto_of[symbol] ~= state_list.length-1;
                // goto and shift
                if (symbol in grammar_info.nonterminals) { result.add( LREntry(Action.goto_, state_list.length-1), k, symbol ); }
                else { result.add(LREntry(Action.shift, state_list.length-1), k, symbol); }
                
                continue;
            }
            
            ////////////////////
            // strongly compatible
            index2 = goto_of[symbol][index2];   // rewrite to the index in state_list (item_set is compatible with state_list[index2])
            
            // goto and shift
            if (symbol in grammar_info.nonterminals) { result.add( LREntry(Action.goto_, index2), k, symbol ); }
            else { result.add(LREntry(Action.shift, index2), k, symbol); }
            
            ////////
            // propagately merge states
            
            // initialize
            // enlarged item-groups and their lookaheads' difference by merging
            auto enlarged = new ItemGroupSet(), core = state_list[index2].keys;
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
                
                scope(exit) changed_states_queue = changed_states_queue [1 .. $];
                scope(exit) difference_queue     = difference_queue     [1 .. $];
                
                auto item_group = state_list[item_number];  // the state that will be changed
                
                //////////
                // merge
                foreach (item; difference_set.keys) {
                    item_group[item] += difference_set[item];
                }
                // take its closure
                closure(grammar_info, item_group);
                
                //////////
                // collect gotos of 'item_group' that will change
                auto new_lookaheads = new AATree!(Symbol, (a,b) => a < b, ItemGroupSet);
                foreach (item; difference_set.keys) {
                    if (item.index >= grammar[item.num].rhs.length) continue;
                    
                    // the symbol immediately after the dot .
                    auto sym = grammar[item.num].rhs[item.index];
                    auto item2 = LR0Item(item.num, item.index+1);
                    
                    // goto(item_group, sym) is empty
                    if (!result.table[item_number, sym].action.among!(Action.shift, Action.goto_)) continue;
                    
                    if (!new_lookaheads.hasKey(sym)) new_lookaheads[sym] = new ItemGroupSet();
                    new_lookaheads[sym][item2] = difference_set[item];
                }
                
                foreach (sym; new_lookaheads.keys) {
                    changed_states_queue ~= result.table[item_number, sym].num;
                    difference_queue ~= new_lookaheads[sym];
                    //assert ( isStronglyCompatible(state_list[result.table[item_number, sym].num], new_lookaheads[sym], grammar_info, fset) );
                }
                
            }
            
        }
        
        if (end_flag) break;
    }
    
    // reduce
    foreach (i, item_group_set; state_list) {
        foreach (item; item_group_set.keys) {
            // . is not at the extreme right and it is not A -> .ε
            if (item.index < grammar[item.num].rhs.length && !(item.index == 0 && grammar[item.num].rhs[0] == empty_)) continue;
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

// show
void showStrongMinimalLRtableInfo(const GrammarInfo grammar_info) {
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
    
    // for strong compatibility check
    auto fset = new FSet;
    
    size_t k = 0;
    // calculate states
    while (true) {
        auto state_length = state_list.length;
        bool end_flag = true;
        for (; k < state_length; k++) foreach (symbol; appearings) {
            
            // calculate goto(I, X) for each X
            auto item_set = _goto(grammar_info, state_list[k], symbol);
            if (item_set.empty) continue;
            
            //writeln("goto(", k, ", ", grammar_info.nameOf(symbol), ")");
            ////////////////////////////
            // a state already appeared
            auto index1 = countUntil!(x => isSameState(x, item_set))(state_list);
            if (index1 != -1) {
                
                //writeln("\t= ", index1);
                
                goto_of[symbol] ~= index1;
                // shift and goto
                if (symbol in grammar_info.terminals) { result.add( LREntry(Action.shift, index1), k, symbol ); }
                else { result.add(LREntry(Action.goto_, index1), k, symbol); }
                //writeln("appeared, ", index1, " ", isSameState(state_list[index1], item_set));
                continue;
            }
            
            end_flag = false;
            
            /////////////////////////////////////
            // check whether it is strongly compatible with previous one
            auto index2 = countUntil!(i => isStronglyCompatible(state_list[i], item_set, grammar_info, fset))(goto_of[symbol]);   // the index in goto_of
            
            /////////////
            // new state
            if (index2 == -1) {
                /*
                writeln("\tnew state");
                writeln("\tSTATE-", state_list.length, " = {");
                foreach (item; item_set.array) {
                    auto rule = grammar[item.num];
                    if (item.num == grammar.length-1) write("\t\t\033[1m\033[31m", item.num, "\033[0m");
                    else write("\t\t", item.num);
                    write(": [", grammar_info.nameOf(rule.lhs), "  ->  ");
                    foreach (l; 0 .. item.index)               write(grammar_info.nameOf(rule.rhs[l]), " ");
                    write("\b\033[1m\033[37m.\033[0m");
                    foreach (l; item.index .. rule.rhs.length) write(grammar_info.nameOf(rule.rhs[l]), " ");
                    write("],\t{");
                    foreach (sym; item_set[item].array) { write(grammar_info.nameOf(sym), ", "); }
                    writeln("\b\b}");
                }
                writeln("\b\t}");
                */
                state_list ~= item_set;
                result.addState();
                goto_of[symbol] ~= state_list.length-1;
                // goto and shift
                if (symbol in grammar_info.nonterminals) { result.add( LREntry(Action.goto_, state_list.length-1), k, symbol ); }
                else { result.add(LREntry(Action.shift, state_list.length-1), k, symbol); }
                
                continue;
            }
            
            ////////////////////
            // strongly compatible
            index2 = goto_of[symbol][index2];   // rewrite to the index in state_list (item_set is compatible with state_list[index2])
            /*
            writeln("\tstrongly compatible with STATE-", index2);
            
            writeln("\tstate is :");
            writeln("\t{");
            foreach (item; item_set.array) {
                auto rule = grammar[item.num];
                if (item.num == grammar.length-1) write("\t\t\033[1m\033[31m", item.num, "\033[0m");
                else write("\t\t", item.num);
                write(": [", grammar_info.nameOf(rule.lhs), "  ->  ");
                foreach (l; 0 .. item.index)               write(grammar_info.nameOf(rule.rhs[l]), " ");
                write("\b\033[1m\033[37m.\033[0m");
                foreach (l; item.index .. rule.rhs.length) write(grammar_info.nameOf(rule.rhs[l]), " ");
                write("],\t{");
                foreach (sym; item_set[item].array) { write(grammar_info.nameOf(sym), ", "); }
                writeln("\b\b}");
            }
            writeln("\b\t}");
            */
            // goto and shift
            if (symbol in grammar_info.nonterminals) { result.add( LREntry(Action.goto_, index2), k, symbol ); }
            else { result.add(LREntry(Action.shift, index2), k, symbol); }
            
            ////////
            // propagately merge states
            
            // initialize
            // enlarged item-groups and their lookaheads' difference by merging
            auto enlarged = new ItemGroupSet(), core = state_list[index2].keys;
            assert (equal(core, item_set.keys));
            foreach (item; core) {
                // . is at the extreme left
                if (item.index == 0) continue;
                auto diff = item_set[item] - state_list[index2][item];
                if (diff.empty) continue;
                //state_list[index2][item] += diff;
                enlarged[item] = diff;
            }
            
            size_t[]       changed_states_queue = [index2];     // the index of state that will be changed.
            ItemGroupSet[] difference_queue     = [enlarged];   // lookahead symbol 
            
            // propagate re-generation of goto
            while (!changed_states_queue.empty) {
                auto item_number      = changed_states_queue[0];
                auto difference_set   = difference_queue[0];
                
                scope(exit) changed_states_queue = changed_states_queue [1 .. $];
                scope(exit) difference_queue     = difference_queue     [1 .. $];
                /*
                writeln("\tmerge to STATE-", item_number);
                
                writeln("\tmerging items and lookahead sets = {");
                foreach (item; difference_set.array) {
                    auto rule = grammar[item.num];
                    if (item.num == grammar.length-1) write("\t\t\033[1m\033[31m", item.num, "\033[0m");
                    else write("\t\t", item.num);
                    write(": [", grammar_info.nameOf(rule.lhs), "  ->  ");
                    foreach (l; 0 .. item.index)               write(grammar_info.nameOf(rule.rhs[l]), " ");
                    write("\b\033[1m\033[37m.\033[0m");
                    foreach (l; item.index .. rule.rhs.length) write(grammar_info.nameOf(rule.rhs[l]), " ");
                    write("],\t{");
                    foreach (sym; difference_set[item].array) { write(grammar_info.nameOf(sym), ", "); }
                    writeln("\b\b}");
                }
                writeln("\b\t}");
                */
                
                auto item_group = state_list[item_number];  // the state that will be changed
                
                //////////
                // merge
                foreach (item; difference_set.keys) {
                    item_group[item] += difference_set[item];
                }
                // take its closure
                closure(grammar_info, item_group);
                /*
                writeln("\tafter merging = {");
                foreach (item; item_group.array) {
                    auto rule = grammar[item.num];
                    if (item.num == grammar.length-1) write("\t\t\033[1m\033[31m", item.num, "\033[0m");
                    else write("\t\t", item.num);
                    write(": [", grammar_info.nameOf(rule.lhs), "  ->  ");
                    foreach (l; 0 .. item.index)               write(grammar_info.nameOf(rule.rhs[l]), " ");
                    write("\b\033[1m\033[37m.\033[0m");
                    foreach (l; item.index .. rule.rhs.length) write(grammar_info.nameOf(rule.rhs[l]), " ");
                    write("],\t{");
                    foreach (sym; item_group[item].array) { write(grammar_info.nameOf(sym), ", "); }
                    writeln("\b\b}");
                }
                writeln("\b\t}");
                */
                //////////
                
                // collect gotos of 'item_group' that will change
                auto new_lookaheads = new AATree!(Symbol, (a,b) => a < b, ItemGroupSet);
                foreach (item; difference_set.keys) {
                    if (item.index >= grammar[item.num].rhs.length) continue;
                    
                    // the symbol immediately after the dot .
                    auto sym = grammar[item.num].rhs[item.index];
                    auto item2 = LR0Item(item.num, item.index+1);
                    
                    // goto(item_group, sym) is empty
                    if (!result.table[item_number, sym].action.among!(Action.shift, Action.goto_)) continue;
                    
                    if (!new_lookaheads.hasKey(sym)) new_lookaheads[sym] = new ItemGroupSet();
                    new_lookaheads[sym][item2] = difference_set[item];
                }
                
                foreach (sym; new_lookaheads.keys) {
                    changed_states_queue ~= result.table[item_number, sym].num;
                    difference_queue ~= new_lookaheads[sym];
                    /*
                    // show differences
                    writeln("\tgoto(", item_number, ", ", grammar_info.nameOf(sym), ") merging by");
                    writeln("\tafter merging = {");
                    foreach (item; new_lookaheads[sym].array) {
                        auto rule = grammar[item.num];
                        if (item.num == grammar.length-1) write("\t\t\033[1m\033[31m", item.num, "\033[0m");
                        else write("\t\t", item.num);
                        write(": [", grammar_info.nameOf(rule.lhs), "  ->  ");
                        foreach (l; 0 .. item.index)               write(grammar_info.nameOf(rule.rhs[l]), " ");
                        write("\b\033[1m\033[37m.\033[0m");
                        foreach (l; item.index .. rule.rhs.length) write(grammar_info.nameOf(rule.rhs[l]), " ");
                        write("],\t{");
                        foreach (sym_; new_lookaheads[sym][item].array) { write(grammar_info.nameOf(sym_), ", "); }
                        writeln("\b\b}");
                    }
                    writeln("\b\t}");
                    */
                    assert ( isStronglyCompatible(state_list[result.table[item_number, sym].num], new_lookaheads[sym], grammar_info, fset) );
                }
            }
        }
        
        if (end_flag) break;
    }
    
    // reduce
    foreach (i, item_group_set; state_list) {
        foreach (item; item_group_set.keys) {
            // . is not at the extreme right and it is not A -> .ε
            if (item.index < grammar[item.num].rhs.length && !(item.index == 0 && grammar[item.num].rhs[0] == empty_)) continue;
            else
                foreach (sym; item_group_set[item].array) {
                    // not S'
                    if (grammar[item.num].lhs != grammar_info.start_sym) result.add(LREntry(Action.reduce, item.num), i, sym);
                    else result.add(LREntry(Action.accept, item.num), i, end_of_file_);
                }
            
        }
    }
    /********************************************************/
    /********************************************************/
    /********************************************************/
    // show collection
    foreach (i, item_set; state_list) {
        writeln("STATE-", i, " = {");
        foreach_reverse (item; item_set.keys) {
            auto rule = grammar[item.num];
            if (item.num == grammar.length-1) write("\t\033[1m\033[31m", item.num, "\033[0m");
            else write("\t", item.num);
            write(": [", grammar_info.nameOf(rule.lhs), "  ->  ");
            foreach (l; 0 .. item.index)               write(grammar_info.nameOf(rule.rhs[l]), " ");
            write("\b\033[1m\033[37m.\033[0m");
            foreach (l; item.index .. rule.rhs.length) write(grammar_info.nameOf(rule.rhs[l]), " ");
            write("], \t{");
            foreach (sym; item_set[item].array) { write(grammar_info.nameOf(sym), ", "); }
            writeln("\b\b}");
        }
        writeln("\b}");
    }
    auto symbols_array = grammar_info.terminals.array ~ [end_of_file_] ~ grammar_info.nonterminals.array[0 .. $-1] ;
    foreach (sym; symbols_array) {
        write("\t", grammar_info.nameOf(sym));
    }
    writeln();
    foreach (i; 0 .. result.table.state_num) {
        write(i, ":\t");
        foreach (sym; symbols_array) {
            auto act = result.table[i, sym].action;
            // conflict
            if (result.is_conflicting(i, sym)) { write("\033[1m\033[31mcon\033[0m, \t"); }
            else if (act == Action.error)  { write("err, \t"); }
            else if (act == Action.accept) { write("\033[1m\033[37macc\033[0m, \t"); }
            else if (act == Action.shift)  { write("\033[1m\033[36ms\033[0m-", result.table[i, sym].num, ", \t"); }
            else if (act == Action.reduce) { write("\033[1m\033[33mr\033[0m-", result.table[i, sym].num, ", \t"); }
            else if (act == Action.goto_)  { write("\033[1m\033[32mg\033[0m-", result.table[i, sym].num, ", \t"); }
        }
        writeln();
    }
    //writeln(table_info.is_conflict);
    foreach (index2; result.conflictings) {
        auto i = index2.state; auto sym = index2.symbol;
        write("action[", i, ", ", grammar_info.nameOf(sym), "] : ");
        foreach (entry; result[i, sym].array) {
            auto act = entry.action;
            if      (act == Action.error)  { write("err, "); }
            else if (act == Action.accept) { write("\033[1m\033[37macc\033[0m, "); }
            else if (act == Action.shift)  { write("\033[1m\033[36ms\033[0m-", entry.num, ", "); }
            else if (act == Action.reduce) { write("\033[1m\033[33mr\033[0m-", entry.num, ", "); }
            else if (act == Action.goto_)  { assert(0); /*write("\033[1m\033[32mg\033[0m-", entry.num, ", ");*/ }
        }
        writeln();
    }
    
    //return result;
}
