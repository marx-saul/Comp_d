module comp_d.AST;

import comp_d.data, comp_d.tool, comp_d.LRTable;
import comp_d.parseTree : IsTreeType;

import std.range, std.array;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

/* 
   Consider a rule X0 -> X1 X2 X3 ... Xn.
   Let an integer i refers to Xi.
   If i = ast_rule.root, then the top of the tree is Xi.
   If children[i] = [j_1, ... j_m], then i has children Xj_1, ... Xj_m.
*/
struct ASTRule {
    Symbol root;
    Symbol[] children;
}

template getAST(Tree, alias const GrammarInfo grammar_info, alias const LRTableInfo table_info, alias const ASTRule[] ASTrules)
    if (IsTreeType!(Tree))
{
    Tree getAST(Range)(Range input)
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
                    // push symbol (leaf)
                    tree_stack ~= input.front();
                    input.popFront();
                break;
                
                case Action.reduce:
                    auto rule = grammar[entry.num];
                    Tree new_tree = new Tree();
                    // A -> ε
                    if (!(rule.rhs.length == 1 && rule.rhs[0] == empty_)) {
                        state_stack.length -= rule.rhs.length;
                        
                        // tree
                        foreach (tree; tree_stack[$-rule.rhs.length .. $]) {
                            new_tree.children ~= tree;
                        }
                        tree_stack .length -= rule.rhs.length;
                    }
                    
                    // push goto(state2, rule.lhs);
                    auto state2 = state_stack[$-1];
                    if (table[state2, rule.lhs].action == Action.goto_) { state_stack ~= table[state2, rule.lhs].num; }
                    else { assert(0); }
                    
                    // push new tree
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
    }
}

template getAST(Tree, alias const GrammarInfo grammar_info, string type = "LALR", string module_name = __MODULE__, string file_name = __FILE__, size_t line = __LINE__) {
    import comp_d.inject;
    mixin(table_info_injection_declaration);
    
    alias getAST = getAST!(Tree, grammar_info, table_info);
}
