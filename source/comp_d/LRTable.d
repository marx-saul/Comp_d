module comp_d.LRTable;

import comp_d.tool, comp_d.data;
import std.typecons;
import std.array, std.container;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

enum Action : byte { error = 0, accept = 1, shift = 2, reduce = 3, goto_ = 4 }
alias State = size_t;
alias LREntry = Tuple!(Action, "action", State, "state");
LREntry LRentry(Action a, State s) {
    return LREntry(a, s);
}

unittest {
    auto table = new LRTable(6, 4);
    table[1, 2] = LRentry(Action.shift, 0);
    assert(table[1,2] == LRentry(Action.shift, 0));
}

// LR parser table
class LRTable {
    private Symbol max_symbol_number;
    private State  max_state_number;
    // data[state][symbol+special_tokens]
    // see LRTable.opIndex
    LREntry[][] data;
    
    this(State mstn, Symbol msyn) {
        this.max_symbol_number = msyn;
        this.max_state_number  = mstn;
        // reserve
        data.length = mstn+1;
        // initialize
        foreach (s; 0 .. mstn+1) {
            data[s].length = msyn+special_tokens;
        }
    }
    
    // table[state, symbol]
    public LREntry opIndex(State state, Symbol symbol) {
        if ( !( (0 <= symbol+special_tokens) && (symbol <= max_symbol_number) ) )assert(0,
                "\033[1m\033[32mBug that should be fixed. LRTable.opIndex("
                ~ to!string(state) ~ ", " ~ to!string(symbol) ~ ")\033[0m"
            );
        return data[state][symbol+special_tokens];
    }
    // table[state, symbol] = LREntry(Action.shift, 12);
    public LREntry opIndexAssign(LREntry value, State state, Symbol symbol) {
        if ( !( (0 <= symbol+special_tokens) && (symbol <= max_symbol_number) ) )
            assert(0,
                "\033[1m\033[32mBug that should be fixed. LRTable.opIndexAssign("
                ~ to!string(value) ~ ", " ~ to!string(state) ~ ", " ~ to!string(symbol) ~ ")\033[0m"
            );
        return data[state][symbol+special_tokens] = value;
    }
}


