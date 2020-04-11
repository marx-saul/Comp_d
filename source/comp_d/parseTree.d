module comp_d.parseTree;

import comp_d.parser;
import comp_d.data, comp_d.tool, comp_d.LRTable;

import std.traits;
import std.range, std.array;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;
/*
class TreePrototype {
    Symbol symbol;
    TreePrototype[] children;
    size_t rule;
    this(){}
}
*/
version(unittest) class Tree {
    Symbol symbol;
    Tree[] children;
    size_t rule;
    int value;
    this(Symbol s, int v) { symbol = s; value = v; }
    this(){}
}

/+
unittest {
    template template_test(T, alias string str) {
        string func() {
            return T.stringof ~ str;
        }
    }
    string s = " is a type";
    alias test = template_test!(Tree, s);
    test.func().writeln();
}+/


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
    /*
    import comp_d.SLR;
    static const table_info = SLRtableInfo(grammar_info);
    static const tree = getParseTree!(Tree)(grammar_info, table_info, [new Tree(digit, 30), new Tree(add, 0), new Tree(digit, 3), new Tree(mul, 0), new Tree(digit, 4)]);
    */
    alias tree_getter = TreeGenerator!(Tree, grammar_info, "SLR");
    //static const tree = tree_getter([new Tree(digit, 30), new Tree(add, 0), new Tree(digit, 3), new Tree(mul, 0), new Tree(digit, 4)]);
    auto tree1 = tree_getter([new Tree(digit, 30), new Tree(add, 0), new Tree(digit, 3), new Tree(mul, 0), new Tree(digit, 4)]);
    auto tree2 = tree_getter([new Tree(lPar, 0), new Tree(digit, 30), new Tree(add, 0), new Tree(digit, 3), new Tree(rPar, 0), new Tree(mul, 0), new Tree(digit, 4)]);
    auto tree3 = tree_getter([new Tree(lPar, 0), new Tree(digit, 30), new Tree(add, 0), new Tree(digit, 3), new Tree(rPar, 0), new Tree(mul, 0), new Tree(digit, 4), new Tree(rPar, 0)], true);
    
    int eval(const Tree tree) {
        if (tree is null) return 0;
        import std.algorithm;
        //writeln(grammar_info.nameOf(tree.symbol), " ", tree.children.map!(x => grammar_info.nameOf(x.symbol)), " ", tree.rule, " ", tree.value);
        // digit
        if (tree.symbol == digit) return tree.value;
        // other
        switch (tree.rule) {
            case 0: // Expr -> Expr + Term
                return eval(tree.children[0]) + eval(tree.children[2]);
            case 1: // Expr -> Term
                return eval(tree.children[0]);
            case 2: // Term -> Term * Factor
                return eval(tree.children[0]) * eval(tree.children[2]);
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
    
    //static assert (eval(tree1) == 42);
    assert (eval(tree1) == 42 /* 30 + 3 * 4 */ );
    assert (eval(tree2) == 132 /* (30 + 3) * 4 */ );
    assert (eval(tree3) == 132);
    
    writeln("## parseTree.d unittest 1");
}

//enum bool IsTokenType(T) = is(T == struct) && is(ReturnType!((T t) => t.symbol) == Symbol);
enum bool IsTreeType(T) =
    is(T == class) &&
    is(ReturnType!((T t) => t.symbol)     == Symbol) &&
    is(ReturnType!((T t) => t.children)   == T[])    &&
    is(ReturnType!((T t) => t.rule)       == size_t) &&
    is( typeof( { auto t = new T; } ) );

template getParseTree(T)
    if (IsTreeType!T)
{
    // if longest is true, give back the longest parse tree that can be deduced from the input.
    T getParseTree(Range)(const Grammar grammar, const LRTable table, Range input, bool longest = false)
        if ( isInputRange!Range && is(typeof(input.front()) == T) )
    {
        T[]  tree_stack;
        State[] stack = [0];
        while (true) {
            auto result = oneStep(grammar, table, input.empty ? end_of_file_ : input.front.symbol, stack);
            if      (result.action == Action.shift)  {
                tree_stack ~= input.front;
                input.popFront();
            }
            else if (result.action == Action.reduce) {
                // new tree A -> X1 X2 .. Xn
                auto rule = grammar[result.num];
                auto new_tree = new T;
                new_tree.symbol = rule.lhs, new_tree.rule = result.num;
                if (!(rule.rhs.length == 1 && rule.rhs[0] == empty_)) {
                    foreach (tree; tree_stack[$-rule.rhs.length .. $]) {
                        new_tree.children ~= tree;
                    }
                    tree_stack.length -= rule.rhs.length;
                }
                tree_stack ~= new_tree;
            }
            else if (result.action == Action.accept) return tree_stack[0];
            else if (result.action == Action.error) {
                if (!longest) return null;
                result = oneStep(grammar, table, end_of_file_, stack);
                if (result.action == Action.accept) return tree_stack[0];
                else return null;
            }
            //else assert(0);
        }
        assert(0);
    }
    T getParseTree(Range)(const GrammarInfo grammar_info, const LRTable table,          Range input, bool longest = false)
        if ( isInputRange!Range && is(typeof(input.front()) == T) )
    {
        return getParseTree!(Range)(grammar_info.grammar, table,            input, longest);
    }
    T getParseTree(Range)(const Grammar grammar,          const LRTableInfo table_info, Range input, bool longest = false)
        if ( isInputRange!Range && is(typeof(input.front()) == T) )
    {
        return getParseTree!(Range)(grammar,              table_info.table, input, longest);
    }
    T getParseTree(Range)(const GrammarInfo grammar_info, const LRTableInfo table_info, Range input, bool longest = false)
        if ( isInputRange!Range && is(typeof(input.front()) == T) )
    {
        return getParseTree!(Range)(grammar_info.grammar, table_info.table, input, longest);
    }
}

template TreeGenerator(
    T, alias const GrammarInfo grammar_info, string type = "LALR",
    string module_name = __MODULE__, string file_name = __FILE__, size_t line = __LINE__
)
    if (IsTreeType!T)
{
    import comp_d.inject: table_info_injection_declaration;
    mixin(table_info_injection_declaration);
    
    T TreeGenerator(Range)(Range input, bool longest = false)
        if ( isInputRange!Range && is(typeof(input.front()) == T) )
    {
        return getParseTree!T(grammar_info.grammar, table_info.table, input, longest);
    }
}
