module comp_d.parser;

import comp_d.SLR, comp_d.LALR, comp_d.LR;
import comp_d.data, comp_d.tool, comp_d.LRTable;

import std.range, std.array;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;

enum bool IsSomeType(S, T) = is(S == T) || is(S == const T) || is(S == inout T) || is(S == inout const T);

// parse
int parse(alias _accept = {}, alias _reduce = (x){}, alias _error = (x){}, alias _shift = {}, Range)
(inout const Grammar grammar, inout const LRTable table, Range input)
    if ( is( typeof( { _accept(); _reduce(size_t.init); _error(State.init); _shift(); } ) ) 
      && isInputRange!Range && IsSomeType!(typeof(input.front), Symbol)
    )
{
    State[] stack = [0];
    while (true) {
        auto result = oneStep!(_accept, _reduce, _error, _shift, Range)(grammar, table, input, stack);
        if (result.among!(0, 1)) return result;
    }
}

// 0: accept, -1: continue, 1: error
private int oneStep(alias _accept, alias _reduce, alias _error, alias _shift, Range)
(inout const Grammar grammar, inout const LRTable table, ref Range input, ref State[] stack)
{
    auto token = input.empty ? end_of_file_ : input.front;
    auto entry = table[stack[$-1], token];

    switch (entry.action) {
        case Action.shift:
            stack ~= entry.num;
            _shift();
            input.popFront();
        return -1;
    
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
            _reduce(entry.num);
        return -1;
        
        case Action.accept:
            _accept();
        return 0;
            
        case Action.error:
            _error(stack[$-1]);
        return 1;
            
        default:
            assert(0);
        }
}


template Parser(alias grammar, alias table)
    if (IsSomeType!(grammar))
{
    
}

/*
// input range
// reduce (num) is called when the parser reduced by the rule grammar[num]
// error (state) is called when the top of the stack is state and the entry is error.
// grammar is supposed not to have any unnecessary empty like [empty_, empty_], [X, empty_, Y, empty_]
template Parser(alias _accept = {}, alias _reduce = (x){}, alias _error = (x){}, alias _shift = {})
    if ( is( typeof( { _accept(); _reduce(size_t.init); _error(State.init); _shift(); } ) ) )
{
    
}
*/
