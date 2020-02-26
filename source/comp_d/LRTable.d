module comp_d.LRTable;

import comp_d.Set, comp_d.tool, comp_d.data;
import std.typecons;
import std.array, std.container;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

enum Action : byte { error = 0, accept = 1, shift = 2, reduce = 3, goto_ = 4 }
alias State = size_t;
alias LREntry = Tuple!(Action, "action", State, "num");
alias LREntrySet = Set!(LREntry, (a,b) => a.action < b.action || (a.action == b.action && a.num < b.num) );
alias EntryIndex = Tuple!(State, "state", Symbol, "symbol");
alias EntryIndexSet = Set!(EntryIndex, (a,b) => a.state < b.state || (a.state == b.state && a.symbol < b.symbol));

//unittest {
    //auto table = new LRTable(6, 4);
    //table[1, 2] = LREntry(Action.shift, 0);
    //assert(table[1,2] == LREntry(Action.shift, 0));
    //writeln("## LRTable unittest 1");
//}

// Starting state is supposed to be 0.
// (indeed, SLR/LALR/LRtableInfo returns a LRTableInfo whose starting state is 0.)
class LRTable {
    private Symbol max_symbol_number;
    private State  state_length;
    public  State  state_num() @property inout {
        return state_length;
    }
    
    public LREntry[][] table;
    
    this(State state_num, Symbol msyn) {
        this.max_symbol_number = msyn;
        this.state_length      = state_num;
        // reserve
        table.length = state_num;
        // initialize
        foreach (state; 0 .. state_num) 
            table[state].length = msyn+2;    // consider end_of_file_ = -2
    }
    
    // return the index of symbol accessing index
    private size_t get_index(Symbol symbol) inout const {
        size_t access = void;
        if      (symbol == -2) access = 0;
        else if ( !( (0 <= symbol) && (symbol <= max_symbol_number) ) )
            assert(0, "Bug that should be fixed. LRTable.opIndex( ..., " ~ to!string(symbol) ~ " )");
        else                   access = symbol+1;
        return access;
    }
    
    // table[state, symbol]
    public LREntry opIndex(State state, Symbol symbol) inout const {
        auto access = get_index(symbol);
        return table[state][access];
    }
    // table[state, symbol]
    public LREntry opIndexAssign(LREntry value, State state, Symbol symbol) {
        auto access = get_index(symbol);
        return table[state][access] = value;
    }
}

// LR parser table Info
// considering the shift-reduce and reduce-reduce conflict
class LRTableInfo {
    // data[state][symbol+special_tokens]
    // see LRTable.opIndex
    private LREntrySet[][] set_data;    // for confliction
    public  LRTable table;               // if there were no confliction, this will be the LRTable of the grammar
    
    //public  bool is_conflict;
    
    private EntryIndexSet conflict_index_set;
    public  bool is_conflict() @property inout const {
        return conflict_index_set.cardinal > 0;
    }
    public  bool is_conflicting(State state, Symbol symbol) inout const {
        return EntryIndex(state, symbol) in conflict_index_set;
    }
    
    public EntryIndex[] conflictings() @property {
        return conflict_index_set.array;
    }
    
    private State state_number;
    public State state_num() @property inout const {
        return state_number;
    }
    
    this(State state_num, Symbol msyn) {
        // init
        table = new LRTable(state_num, msyn);
        // reserve
        set_data.length = state_num; state_number = state_num;
        // initialize
        foreach (state; 0 .. state_num) {
            set_data[state].length = msyn+2;    // consider end_of_file_ = -2
            foreach (symbol; 0 .. msyn+2) set_data[state][symbol] = new LREntrySet();
        }
        conflict_index_set = new EntryIndexSet();
    }
    
    // return the set
    // table[state, symbol]
    public LREntrySet opIndex(State state, Symbol symbol) {
        auto access = table.get_index(symbol);
        return set_data[state][access];
    }
    
    // determine the value
    // table[state, symbol] = Entry
    public void opIndexAssign(LREntry value, State state, Symbol symbol) {
        auto access = table.get_index(symbol);
        // determine the entry
        table[state, symbol] = value;
        conflict_index_set.remove(EntryIndex(state, symbol));
    }
    
    // add entry to the table[state, symbol]
    public void add(LREntry value, State state, Symbol symbol) {
        auto access = table.get_index(symbol);
        set_data[state][access].add(value);
        // conflicted
        if (table[state, symbol].action != Action.error && table[state, symbol] != value) {
            conflict_index_set.add(EntryIndex(state, symbol));
            // when shift-reduce conflict occurs, shift is chosen. 
            if (value.action == Action.shift) table[state, symbol] = value;
        }
        else table[state, symbol] = value;
    }
}

