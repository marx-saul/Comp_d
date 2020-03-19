module comp_d.parser;

import comp_d.data, comp_d.tool, comp_d.LRTable;

import std.range, std.array;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

// disposable parser class (one class instance per one parse)
class Parser {
    private GrammarInfo _grammar_info_;
    private LRTableInfo _table_info_;
    
    this(inout GrammarInfo g_i, inout LRTableInfo t_i) {
        _grammar_info_ = cast(GrammarInfo) g_i;
        _table_info_   = cast(LRTableInfo) t_i;
    }
    
    // return which action the parser did.
    private Action oneStep(Symbol token, ref State[] stack) {
        auto table = _table_info_.table;
        auto grammar = _grammar_info_.grammar;
        auto entry = table[stack[$-1], token];
        
        switch (entry.action) {
            case Action.shift:
                stack ~= entry.num;
                shift();
            break;
        
            case Action.reduce:
                auto rule = grammar[entry.num];
                // empty generating rule
                if (!(rule.rhs.length == 1 && rule.rhs[0] == empty_))
                    // reduce (pop rule.rhs.length states)
                    stack.length -= rule.rhs.length;
                    
                // new top
                auto state2 = stack[$-1];
                // push goto(state2, rule.lhs);
                if (table[state2, rule.lhs].action == Action.goto_) { stack ~= table[state2, rule.lhs].num; }
                else { assert(0); }
                reduce(entry.num);
            break;
            
            case Action.accept:
                accept();
            break;
                
            case Action.error:
                error(stack[$-1]);
            break;
                
            default:
                assert(0, to!string(entry.action));
        }
        return entry.action;
    }
    
    // you have to push end_of_file_.
    // -1 : continue, 0 : accept, 1 : error, -2 : nonterminal pushed
    private State[] symbol_stack = [0];
    public int pushToken(Symbol token) {
        Action action;
        do {
            if (token in _grammar_info_.nonterminals) return -2;
            action = oneStep(token, symbol_stack);
        } while (action == Action.reduce);
        
        if      (action == Action.accept) { return 0; }
        else if (action == Action.error ) { return 1; }
        else { return -1; }
    }
    
    protected void accept() {
    }
    protected void reduce(size_t) {
    }
    protected void error(State) {
    }
    protected void shift() {
    }

}

