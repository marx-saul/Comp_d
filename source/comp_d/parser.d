// parser class
module comp_d.parser;

import comp_d.SLR, comp_d.LALR, comp_d.LR;
import comp_d.data, comp_d.tool, comp_d.LRTable;

import std.range, std.array;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

enum bool IsSomeType(S, T) = is(S == T) || is(S == const T) || is(S == inout T) || is(S == inout const T);

class Parser {
    private GrammarInfo grammar_info;
    private LRTableInfo table_info;    
    private SymbolSet end_of_parse_symbol;
    private string[] rule_label;
    
    this(inout GrammarInfo g_i, inout LRTableInfo t_i, Symbol[] eops = [], string[] rl = []) {
        grammar_info = cast(GrammarInfo) g_i;
        table_info   = cast(LRTableInfo) t_i;
        end_of_parse_symbol = new SymbolSet(g_i.max_symbol_num, eops);
        rule_label = rl;
    }
    
    // continue : -1, accept : 0, error : 1
    private int oneStep(Lexer input, ref State[] stack) {
        auto token = input.empty || input.front_symbol in end_of_parse_symbol ? end_of_file_ : input.front_symbol;
        auto table = table_info.table;
        auto grammar = grammar_info.grammar;
        auto entry = table[stack[$-1], token];
    
        switch (entry.action) {
            case Action.shift:
                stack ~= entry.num;
                shift();
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
                reduce(entry.num);
            return -1;
            
            case Action.accept:
                accept();
            return 0;
                
            case Action.error:
                error(stack[$-1]);
            return 1;
                
            default:
                assert(0);
        }
    }
    
    // accept : 0, error : 1
    public int parse(Lexer input) {
        State[] stack = [0];
        while (true) {
            auto result = oneStep(input, stack);
            if (result.among!(0, 1)) return result;
        }
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

class Lexer {
    abstract bool empty() @property;
    abstract Symbol front_symbol() @property;
    abstract void popFront();
}

class SyntaxNode {
    Symbol symbol;
    SyntaxNode[] children;
    SyntaxNode parent;
}
