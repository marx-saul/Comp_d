module comp_d.parseTree;

import comp_d.SLR, comp_d.LALR, comp_d.LR;
import comp_d.inject;
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
    static const table_info = SLRtableInfo(grammar_info);
    
    static const tree = getParseTree!(Tree, grammar_info, table_info)
        ([new Tree(digit, 30), new Tree(add, 0), new Tree(digit, 3), new Tree(mul, 0), new Tree(digit, 4)]);
    
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
        if ( isInputRange!Range && IsTreeType!(typeof(input.front())) )
    {
        auto grammar = grammar_info.grammar;
        auto table = table_info.table;
        
        Tree[]  tree_stack;
        State[] state_stack = [0];
        
        while (true) {
            auto current_symbol = input.empty() ? end_of_file_ : input.front().symbol;
            auto entry = table[state_stack[$-1], current_symbol];    
            
            switch (entry.action) {
                case Action.shift:
                    state_stack ~= entry.num;
                    tree_stack ~= input.front();
                    input.popFront();
                break;
                
                case Action.reduce:
                    auto rule = grammar[entry.num];
                    Tree new_tree = new Tree();
                    // A -> ε
                    if (!(rule.rhs.length == 1 && rule.rhs[0] == empty_)) {
                        state_stack.length -= rule.rhs.length;
                        foreach (tree; tree_stack[$-rule.rhs.length .. $]) {
                            new_tree.children ~= tree;
                        }
                        tree_stack .length -= rule.rhs.length;
                    }
                    
                    // push goto(state2, rule.lhs);
                    auto state2 = state_stack[$-1];
                    if (table[state2, rule.lhs].action == Action.goto_) { state_stack ~= table[state2, rule.lhs].num; }
                    else { assert(0); }
                    
                    // push new symbol
                    tree_stack ~= new_tree;
                break;
                
                case Action.accept:
                    return tree_stack[0];
                
                case Action.error:
                    return null;
                
                default:
                    assert(0);
            }
            
        }
        
        assert(0);
        /+
        Tree[] stack;
        
        void reduce(size_t rule_num) {
            auto rule = grammar[rule_num];
            // new_tree has rule.rhs as children
            Tree* new_tree;
            new_tree.symbol = rule.lhs;
            new_tree.rule = rule_num;
            foreach (tree; stack[$-rule.rhs.length .. $]) {
                new_tree.children ~= tree;
            }
            // reduction
            // not an empty rule
            if (!(rule.rhs.length == 1 && rule.rhs[0] == empty_)) 
                stack.length -= rule.rhs.length;
            stack ~= *new_tree;
        }
        
        void shift() {
            Tree* new_tree;
            *new_tree = input.front();
            stack ~= *new_tree;
        }
        
        // parse
        class SymbolRange {
            Symbol front() @property { return input.front().symbol; }
            bool empty() @property { return input.empty(); }
            void popFront() { input.popFront(); }
        }
        
        auto parse_result = parse!({}, (x){}/* reduce */, (x){}, {}/* shift */, Range)(grammar, table, new SymbolRange());
        if (parse_result == 0) {
            stack[0].successful = true;
            return stack[0];
        }
        else {
            Tree* t;
            t.successful = false;
            return *t;
        }
        +/
    }
    
}
