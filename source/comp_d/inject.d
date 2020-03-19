//Staticly generate 
module comp_d.inject;

import comp_d.data, comp_d.tool, comp_d.LRTable;

import std.range, std.array;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

enum bool IsSomeType(S, T) = is(S == T) || is(S == const T) || is(S == inout T) || is(S == inout const T);

unittest {
    enum : Symbol {
        Expr, Expr_, Term, Term_, Factor,
        digit, add, mul, lPar, rPar
    }
    static const grammar_info = new GrammarInfo([
        rule(Expr, Term, Expr_),
        rule(Expr_, add, Term, Expr_),
        rule(Expr_, empty_),
        rule(Term, Factor, Term_),
        rule(Term_, mul, Factor, Term_),
        rule(Term_, empty_),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar),
    ], ["Expr", "Expr'", "Term", "Term'", "Factor", "id", "+", "*", "(", ")"]);
    import comp_d.SLR: SLRtableInfo;
    static const table_info = SLRtableInfo(grammar_info);
    
    const Symbol[] inputs1 = [digit, add, lPar, digit, add, digit, mul, digit, rPar];
    const Symbol[] inputs2 = [lPar, digit, rPar, rPar];
    
    alias parser2 = generateParser!(grammar_info, table_info);
    static assert (parser2.parse(inputs2) == 1);     // error
    
    alias parser1 = injectParser!(grammar_info, "weak minimal LR", {writeln("accept");}, (x){/*reduce*/}, (x){writeln("error");});
    assert ( parser1.parse(inputs1) == 0 );
    writeln("## parse.d unittest 1");
}

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

// static-parser
template generateParser(
    alias const GrammarInfo g_i, alias const LRTableInfo t_i,
    alias _accept = {}, alias _reduce = (x){}, alias _error = (x){}, alias _shift = {}
)
    if ( is( typeof( { _accept(); _reduce(size_t.init); _error(State.init); _shift(); } ) ) )
{
    int parse(Range)(Range input) {
        return comp_d.inject.parse!(_accept, _reduce, _error, _shift, Range)(g_i.grammar, t_i.table, input);
    }
}

template injectParser(
    alias const GrammarInfo grammar_info, string type = "LALR",
    alias _accept = {}, alias _reduce = (x){}, alias _error = (x){}, alias _shift = {},
    string module_name = __MODULE__, string file_name = __FILE__, size_t line = __LINE__
)
    if ( is( typeof( { _accept(); _reduce(size_t.init); _error(State.init); _shift(); } ) ) )
{
    // generate table
    import comp_d.SLR, comp_d.LALR, comp_d.LR, comp_d.WeakMinLR;
    
    static if      (type == "SLR") {
        static const table_info = SLRtableInfo(grammar_info);
    }
    else static if (type == "LALR") {
        static const table_info = LALRtableInfo(grammar_info);
    }
    else static if (type == "LR") {
        pragma(msg, "Canonical LR(1) table generation can require enormous resources and the resulting states and table sizes could be super large. If you REALLY want to use canonical LR(1) algorithm, use \"canonical-LR\" parameter instead of \"LR\".");
    }
    else static if (type.among!("canonical-LR", "canonical LR")) {
        static const table_info = LRtableInfo(grammar_info);
    }
    else static if (type.among!("minimal-LR", "weak-minimal-LR", "minimal LR", "weak minimal LR")) {
        static const table_info = weakMinimalLRtableInfo(grammar_info);
    }
    else
        static assert(0, "No parser type " ~ type);
    
    static if (table_info.is_conflict) pragma(msg, "Conflict occurs. " ~ module_name ~ " / " ~ file_name ~ " : " ~ to!string(line));
    
    alias injectParser = generateParser!(grammar_info, table_info, _accept, _reduce, _error, _shift);
}
