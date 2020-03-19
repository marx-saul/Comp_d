module comp_d.parseTree;

import comp_d.parser;
import comp_d.data, comp_d.tool, comp_d.LRTable;

import std.traits;
import std.range, std.array;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

class Tree {
    Symbol symbol;
    int value;
    this(Symbol s, int v) { symbol = s; value = v; }
    this(){}
    
    Tree[] children;
    size_t rule;
}
    
unittest {
    
    enum : Symbol {
        Expr, Term, Factor,
        digit, add, mul, lPar, rPar
    }
    static const grammar_info = new GrammarInfo([
        rule(Expr, Expr, add, Term),
        rule(Expr, Term),
        rule(Term, Term, mul, Factor),
        rule(Term, Factor),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar),
    ], ["Expr", "Term", "Factor", "digit", "+", "*", "(", ")"]);
    //static const table_info = SLRtableInfo(grammar_info);
    alias tree_generator = getParseTree!(Tree, grammar_info, "SLR");
    static const tree = getParseTree!(Tree, grammar_info, "SLR")([new Tree(digit, 30), new Tree(add, 0), new Tree(digit, 3), new Tree(mul, 0), new Tree(digit, 4)]);
    
    int eval(inout Tree tree) {
        // digit
        if (tree.symbol == digit) return tree.value;
        // other
        switch (tree.rule) {
            case 0: // Expr -> Expr + Term
                return eval(tree.children[0]) + eval(tree.children[2]);
            case 1: // Expr -> Term
                return eval(tree.children[0]);
            case 2: // Term -> Term * Factor
                return eval(tree.children[0]) * eval(tree);
            case 3: // Term -> Factor
                return eval(tree.children[0]);
            case 4: // Factor -> digit
                return eval(tree.children[0]);
            case 5: // Factor -> ( Expr )
                return eval(tree.children[1]);
            default:
                assert(0);
        }
    }
    
    //static assert (eval(tree) == 42);
    
    writeln("## parseTree.d unittest 1");
}

//enum bool IsTokenType(T) = is(T == struct) && is(ReturnType!((T t) => t.symbol) == Symbol);
enum bool IsTreeType(T) =
    is(T == class) &&
    is(ReturnType!((T t) => t.symbol)     == Symbol) &&
    is(ReturnType!((T t) => t.children)   == T[])    &&
    is(ReturnType!((T t) => t.rule)       == size_t);

template getParseTree(Tree, alias const GrammarInfo grammar_info, alias const LRTableInfo table_info)
    if (IsTreeType!(Tree))
{
    Tree getParseTree(Range)(Range input)
        if ( isInputRange!Range && is(typeof(input.front()) == Tree) )
    {
        auto grammar = grammar_info.grammar, table = table_info.table;
        Tree[]  tree_stack;
        State[] stack = [0];
        while (true) {
            auto result = oneStep(grammar, table, input.empty ? end_of_file_ : input.front.symbol, stack);
            if      (result.action == Action.shift)  {
                tree_stack ~= input.front;
                input.popFront();
            }
            else if (result.action == Action.reduce) {
                auto rule = grammar[result.num];
                auto new_tree = new Tree;
                new_tree.symbol = rule.lhs;
                if (!(rule.rhs.length == 1 && rule.rhs[0] == empty_)) {
                    foreach (tree; tree_stack[$-rule.rhs.length .. $]) {
                        new_tree.children ~= tree;
                    }
                    tree_stack.length -= rule.rhs.length;
                }
                tree_stack ~= new_tree;
            }
            else if (result.action == Action.accept) return tree_stack[0];
            else if (result.action == Action.error)  return null;
            //else assert(0);
        }
        assert(0);
    }
}

template getParseTree(Tree, alias const GrammarInfo grammar_info, string type = "LALR", string module_name = __MODULE__, string file_name = __FILE__, size_t line = __LINE__) {
    import comp_d.inject: table_info_injection_declaration;
    mixin(table_info_injection_declaration);
    
    alias getParseTree = getParseTree!(Tree, grammar_info, table_info);
}
