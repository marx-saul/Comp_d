module comp_d.parser;

import comp_d.data, comp_d.tool, comp_d.LRTable;

import std.traits;
import std.range, std.array;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

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
    
    static assert ( !table_info.is_conflict );
    static assert ( parse(grammar_info.grammar, table_info.table, inputs1) );
    static assert (!parse(grammar_info.grammar, table_info.table, inputs2) );
    static assert ( parse(grammar_info.grammar, table_info.table, [digit, add, digit, mul, lPar, digit, add, digit, rPar]) );
    
    writeln("## parser.d unittest 1");
}

enum bool isSymbolInput(T) = 
    isInputRange!T &&
    (
        is(ReturnType!((T t) => t.front()) == Symbol) ||
        is(ReturnType!((T t) => t.front()) == const Symbol) ||
        is(ReturnType!((T t) => t.front()) == inout Symbol) ||
        is(ReturnType!((T t) => t.front()) == inout const Symbol)
    );

// one step of LR parser routine
// you have to push end_of_file_.
LREntry oneStep(inout const Grammar grammar, inout const LRTable table, Symbol token, ref State[] stack) {
    auto entry = table[stack[$-1], token];

    switch (entry.action) {
        case Action.shift:
            stack ~= entry.num;
        return entry;
    
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
        break;
        
        case Action.accept:
        break;
            
        case Action.error:
        break;
            
        default:
            assert(0);
    }
        
    return entry;
}

bool parse(Range)(inout const Grammar grammar, inout const LRTable table, Range input)
    if ( isSymbolInput!Range )
{
    State[] stack = [0];
    while (true) {
        auto result = oneStep(grammar, table, input.empty ? end_of_file_ : input.front, stack);
        if      (result.action == Action.shift)  input.popFront();
        else if (result.action == Action.reduce) {}
        else if (result.action == Action.accept) return true;
        else if (result.action == Action.error)  return false;
    }
    
}
