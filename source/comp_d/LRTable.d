module comp_d.LRTable;

import comp_d.tool, comp_d.data;
import std.typecons;
import std.array, std.container;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

enum Action : byte { error = 0, accept = 1, shift = 2, reduce = 3, goto_ = 4 }
alias State = size_t;
alias LREntry = Tuple!(Action, "action", State, "num");

unittest {
    auto table = new LRTable(6, 4);
    table[1, 2] = LREntry(Action.shift, 0);
    assert(table[1,2] == LREntry(Action.shift, 0));
    writeln("## LRTable unittest 1");
}

// LR parser table
class LRTable {
    private Symbol max_symbol_number;
    private State  state_length;
    public  State  state_num() @property inout {
        return state_length;
    }
    // data[state][symbol+special_tokens]
    // see LRTable.opIndex
    LREntry[][] data;
    
    this(State state_num, Symbol msyn) {
        this.max_symbol_number = msyn;
        this.state_length      = state_num;
        // reserve
        data.length = state_num;
        // initialize
        foreach (s; 0 .. state_num) {
            data[s].length = msyn+2;    // consider end_of_file_ = -2
        }
    }
    
    // table[state, symbol]
    public LREntry opIndex(State state, Symbol symbol) inout {
        if (symbol == -2) return data[state][0];
        if ( !( (0 <= symbol) && (symbol <= max_symbol_number) ) )
            assert(0,
                "\033[1m\033[32mBug that should be fixed. LRTable.opIndex("
                ~ to!string(state) ~ ", " ~ to!string(symbol) ~ ")\033[0m"
            );
        return data[state][symbol+1];
    }
    // table[state, symbol] = LREntry(Action.shift, 12);
    public LREntry opIndexAssign(LREntry value, State state, Symbol symbol) {
        if (symbol == -2) return data[state][0] = value;
        if ( !( (0 <= symbol) && (symbol <= max_symbol_number) ) )
            assert(0,
                "\033[1m\033[32mBug that should be fixed. LRTable.opIndexAssign("
                ~ to!string(value) ~ ", " ~ to!string(state) ~ ", " ~ to!string(symbol) ~ ")\033[0m"
            );
        return data[state][symbol+1] = value;
    }
}


