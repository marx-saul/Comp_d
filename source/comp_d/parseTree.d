module comp_d.parseTree;

import comp_d.SLR, comp_d.LALR, comp_d.LR;
import comp_d.data, comp_d.tool, comp_d.LRTable;

import std.range, std.array;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

unittest {
    writeln("## parseTree.d unittest 1");
}

enum bool IsSomeType(S, T) = is(S == T) || is(S == const T) || is(S == inout T) || is(S == inout const T);

template getParseTree(Tree, alias const GrammarInfo grammar_info, alias const LRTableInfo table_info)
    if (
        is(typeof(Tree) == struct) && is(typeof(Tree.symbol) == Symbol) &&
        is(typeof(Tree.children) == Tree[]) && is(typeof(Tree.successful) == bool)
    )
{
    Tree getParseTree(Range)(Range input)
        if (isInputRange!Range && IsSomeType!(typeof(input.front), Symbol))
    {
        auto grammar = grammar_info.grammar;
        auto table = table_info.table;
        
        Tree[] stack;
        
        void reduce(size_t rule_num) {
            auto rule = grammar[rule_num];
            
            Tree new_tree;
            new_tree.symbol = rule.lhs;
            foreach (tree; stack[$-rule.rhs.length .. $]) {
                new_tree ~= tree;
            }
            stack.length -= (rule.rhs.length-1);
            stack[$-1] = new_tree;
        }
        
        void shift() {
            Tree new_tree;
            new_tree.symbol = cast(Symbol) input.front;
            stack ~= new_tree;
        }
        
        auto parse_result = parse!({}, reduce, (x){}, shift, Range)(grammar, table, input);
        if (parse_result == 0) {
            stack[0].successful = true;
            return stack[0];
        }
        else {
            Tree t;
            t.successful = false;
            return t;
        }
    }
    
}
