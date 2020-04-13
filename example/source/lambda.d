module lambda;

import comp_d;
import std.stdio, std.ascii;
import std.array;
import std.conv: conv_to = to;

// definition of grammar
alias grammar = defineGrammar!(`
    Expr:
        @lam      lam Args dot Expr,
        @lam_app  Apply,
    ;
    Apply:
        @app       Apply Atom,
        @app_atom  Atom,
    ;
    Atom:
        @var  var,
        @par  lPar Expr rPar,
    ;
    Args:
        @list      Args var,
        @list_end  var,
    ;
`);
// symbol declarations
mixin ("enum : Symbol {" ~ grammar.tokenDeclarations ~ "}");

// generate SLR table
static const table_info = SLRtableInfo(grammar.grammar_info);

bool isLambda(Symbol[] input) {
    return parse(grammar.grammar_info, table_info, input);
}

struct Token {
    Symbol type;
    string name;
    this(Symbol t, string n) { type = t; name = n; }
}

Token nextToken(ref size_t index, string text) {
    while (index < text.length && isWhite(text[index])) { index++; }
    
    if (index >= text.length) return Token(end_of_file_, "$");
    
    switch (text[index]) {
        case '(':
            index++;
            return Token(lPar, "(");
        case ')':
            index++;
            return Token(rPar, ")");
        case '.':
            index++;
            return Token(dot,  ".");
        case '\\':
            index++;
            return Token(lam,  "\\");
        default:
            break;
    }
    
    string name;
    if (isAlpha(text[index]) || text[index] == '_') {
        do {
            name ~= text[index];
            index++;
        }
        while (index < text.length && (isAlphaNum(text[index]) || text[index] == '_') );
        return Token(var, name);
    }
    else {
        writeln("Unknown symbol ", text[index], " at index ", index);
        index++;
        return nextToken(index, text);
    }
}

// Lambda Expression Tree
enum Type : byte { lam, app, var }
class Tree {
    Type type;
    bool[string] free_vars;
    bool[string] bound_vars;
    Tree dup() @property {
        auto result = new Tree;
        result.type = type;
        result.free_vars  = free_vars.dup;
        result.bound_vars = bound_vars.dup;
        return result;
    }
}

class Variable : Tree {
    string name;
    this (string n) { name = n; type = Type.var; free_vars[n] = false; }
    override Variable dup() @property {
        auto result = new Variable(name);
        result.free_vars  = free_vars.dup;
        result.bound_vars = bound_vars.dup;
        return result;
    }
}
class LambdaTree : Tree {
    string[] args;
    Tree     expr;
    this () { type = Type.lam; }
    override LambdaTree dup() @property {
        auto result = new LambdaTree;
        result.free_vars  = free_vars.dup;
        result.bound_vars = bound_vars.dup;
        result.args = args.dup;
        result.expr = expr.dup;
        return result;
    }
}
class ApplyTree : Tree {
    Tree left;
    Tree right;
    this () { type = Type.app; }
    override ApplyTree dup() @property {
        auto result = new ApplyTree;
        result.free_vars  = free_vars.dup;
        result.bound_vars = bound_vars.dup;
        result.left = left.dup;
        result.right = right.dup;
        return result;
    }
}

Tree lambdaTree(string text) {
    Token[] tokens;
    size_t index; 
    Token token = nextToken(index, text);
    while (token.type != end_of_file_) {
        //writeln(token.type, " ", token.name);
        tokens ~= token;
        token = nextToken(index, text);
    }
    
    return lambdaTree(tokens ~ [Token(end_of_file_, "$")]);
}
// construct AST of lambda tree
Tree lambdaTree(Token[] tokens) {
    State[]  state_stack = [0];
    Tree[] tree_stack;
    while (true) {
        auto result = oneStep(grammar.grammar_info.grammar, table_info.table, tokens.front.type, state_stack);
        if      (result.action == Action.shift) {
            if (tokens.front.type == var) tree_stack ~= new Variable(tokens.front.name);
            else                          tree_stack ~= null;
            tokens.popFront();
        }
        else if (result.action == Action.reduce) {
            switch (grammar.labelOf(result.num)) {
                case "lam":
                    auto lambda_tree = cast(LambdaTree) tree_stack[$-3];
                    lambda_tree.expr = tree_stack[$-1];
                    
                    // An argument is bounded.
                    bool[string] args_appeared; // check if the same argument appeared
                    foreach (arg; lambda_tree.args) {
                        lambda_tree.bound_vars[arg] = false;
                        if (arg in lambda_tree.expr.bound_vars || arg in args_appeared) {
                            writeln("Argument '", arg,"' has already appeared in the return value." );
                            return null;
                        }
                        args_appeared[arg] = false;
                    }
                    foreach (var; lambda_tree.expr.bound_vars.byKey)
                        lambda_tree.bound_vars[var] = false;
                    foreach (var; lambda_tree.expr.free_vars. byKey) if (var !in args_appeared)
                        lambda_tree.free_vars[var] = false;
                    
                    tree_stack.length -= (4-1);
                    tree_stack[$-1] = lambda_tree;
                break;
                
                case "lam_app":
                break;
                
                case "app":
                    auto apply_tree = tree_stack[$-2];
                    auto atom_tree  = tree_stack[$-1];
                    
                    auto new_tree   = new ApplyTree;
                    new_tree.left = apply_tree,
                    new_tree.right = atom_tree;
                    
                    // set variables
                    foreach (var; apply_tree.free_vars. byKey)
                        new_tree.free_vars[var]  = false;
                    foreach (var; apply_tree.bound_vars.byKey)
                        new_tree.bound_vars[var] = false;
                    foreach (var; atom_tree. free_vars. byKey)
                        new_tree.free_vars[var]  = false;
                    foreach (var; atom_tree. bound_vars.byKey)
                        new_tree.bound_vars[var] = false;
                    
                    tree_stack.length -= (2-1);
                    tree_stack[$-1] = new_tree;
                break;
                
                case "app_atom":
                break;
                
                case "var":
                break;
                
                case "par":
                    tree_stack[$-3] = tree_stack[$-2];
                    tree_stack.length -= (3-1);
                break;
                
                case "list":
                    // add the variable to the arguments of lambda tree
                    auto lam_tree = cast(LambdaTree) tree_stack[$-2];
                    auto variable  = cast(Variable)   tree_stack[$-1];
                    
                    lam_tree.args ~= variable.name;
                    
                    tree_stack.length -= (2-1);
                break;
                
                case "list_end":
                    // new lambda tree
                    auto variable = cast(Variable) tree_stack[$-1];
                    auto new_tree = new LambdaTree;
                    
                    new_tree.args ~= variable.name;
                    
                    tree_stack[$-1] = new_tree;
                break;
                
                default:
                assert(0);
            }
        }
        else if (result.action == Action.accept) return tree_stack[0];
        else if (result.action == Action.error)  { writeln("Syntax error"); return null; }
    }
    assert(0);
}

void set_FBvars(Tree tree) {
    if (tree is null) return;
    
    tree.free_vars.clear();
    tree.bound_vars.clear();
    
    // variable
    if (tree.type == Type.var) {
        auto var_tree = cast(Variable) tree;
        var_tree.free_vars = [var_tree.name : false];
    }
    // (M N)
    else if (tree.type == Type.app) {
        auto app_tree = cast(ApplyTree) tree;
        set_FBvars(app_tree.left);
        set_FBvars(app_tree.right);
        
        // set variables
        foreach (var; app_tree.left. free_vars. byKey)
            app_tree.free_vars[var]  = false;
        foreach (var; app_tree.left. bound_vars.byKey)
            app_tree.bound_vars[var] = false;
        foreach (var; app_tree.right.free_vars. byKey)
            app_tree.free_vars[var]  = false;
        foreach (var; app_tree.right.bound_vars.byKey)
            app_tree.bound_vars[var] = false;
        
    }
    // \xyz.M
    else if (tree.type == Type.lam) {
        auto lam_tree = cast(LambdaTree) tree;
        
        set_FBvars(lam_tree.expr);
        
        // set variables
        bool[string] args_appeared; // check if the same argument appeared
        foreach (arg; lam_tree.args) {
            lam_tree.bound_vars[arg] = false;
            assert(!(arg in lam_tree.expr.bound_vars || arg in args_appeared));
            args_appeared[arg] = false;
        }
        foreach (var; lam_tree.expr.bound_vars.byKey)
            lam_tree.bound_vars[var] = false;
        foreach (var; lam_tree.expr.free_vars. byKey) if (var !in args_appeared)
            lam_tree.free_vars[var] = false;
        
    }
    else assert(0);
}

// alpha-conversion of lambda tree
void replace_variable(Tree tree, string to, string from) {
    // variable
    if (tree.type == Type.var) {
        auto var_tree = cast(Variable) tree;
        if (var_tree.name == from) var_tree.name = to;
    }
    // (M N)
    else if (tree.type == Type.app) {
        auto app_tree = cast(ApplyTree) tree;
        replace_variable(app_tree.left,  to, from);
        replace_variable(app_tree.right, to, from);
    }
    // \xyz.M
    else if (tree.type == Type.lam) {
        auto lam_tree = cast(LambdaTree) tree;
        // if there is an argument that coincides with 'from'
        foreach (arg; lam_tree.args) {
            if (arg == from) return;
        }
        // there is no such an argument
        replace_variable(lam_tree.expr, to, from);
    }
    else assert(0);
    
    set_FBvars(tree);
}

void assign_lambda(ref Tree tree, Tree term, string ass_var) {
    // variable
    if (tree.type == Type.var) {
        auto var_tree = cast(Variable) tree;
        if (ass_var == var_tree.name) tree = term.dup;
    }
    // (M N)
    else if (tree.type == Type.app) {
        auto app_tree = cast(ApplyTree) tree;
        app_tree.free_vars.remove(ass_var);
        
        assign_lambda(app_tree.left,  term, ass_var);
        assign_lambda(app_tree.right, term, ass_var);
    }
    // \xyz.M
    else if (tree.type == Type.lam) {
        auto lam_tree = cast(LambdaTree) tree;
        lam_tree.free_vars.remove(ass_var);
        
        // replace the variables
        foreach (i, arg; lam_tree.args) {
            // assignment end
            if (arg == ass_var) { set_FBvars(tree); return; }
            
            // change the argument variable to a new one
            if (arg in term.free_vars || arg in term.bound_vars) {
                // get the head number (possibly empty)
                string head_number_str = "";
                foreach (ch; arg) {
                    if (!isDigit(ch)) break;
                    else head_number_str ~= ch;
                }
                size_t head_number = (head_number_str.length > 0) ? 
                    conv_to!size_t(head_number_str) :
                    0 ;
                // cut the head number
                auto arg_body = arg[head_number_str.length .. $];
                // new argument
                string new_arg = conv_to!string(head_number) ~ arg;
                // find new variable
                while (true) {
                    if (new_arg !in term.free_vars && new_arg !in lam_tree.bound_vars) break;
                    head_number++;
                    new_arg = conv_to!string(head_number) ~ arg;
                }
                
                //(\y.M)[x:=N] = (\z.M[z/y][x:=N]) (z not in FV(N))
                lam_tree.args[i] = new_arg;
                replace_variable(lam_tree.expr, new_arg, arg);
                assign_lambda(lam_tree.expr, term, ass_var);
            }
        }
        assign_lambda(lam_tree.expr, term, ass_var);
    }
    else assert(0);
    
    set_FBvars(tree);
}


// normal reduction of lambda tree
void normal_reduce(ref Tree tree) {
    Tree* outer_left = null;
    
    // find the most outer left app tree.
    // depth-first search
    Tree*[] tree_stack = [&tree];
    byte[] visit_stack = [1];
    
    while (!tree_stack.empty) {
        auto top_tree = tree_stack[$-1];
        
        // apply tree found
        if (top_tree.type == Type.app) {
            auto app_tree = cast(ApplyTree) *top_tree;
            // redex
            if (app_tree.left.type == Type.lam) {
                outer_left = top_tree;
                break;
            }
            // go left
            else if (visit_stack[$-1] == 1) {
                visit_stack[$-1] = 2;
                tree_stack ~= &(app_tree.left);
                visit_stack ~= 1;
            }
            // go right
            else if (visit_stack[$-1] == 2) {
                visit_stack[$-1] = 3;
                tree_stack ~= &(app_tree.right);
                visit_stack ~= 1;
            }
            // go up
            else if (visit_stack[$-1] == 3) {
                tree_stack.length  -= 1;
                visit_stack.length -= 1;
            }
            else assert(0);
        }
        // lambda tree
        else if (top_tree.type == Type.lam) {
            // already visited this node
            if (visit_stack[$-1] == 2) {
                tree_stack.length  -= 1;
                visit_stack.length -= 1;
            }
            // first time visit
            else {
                visit_stack[$-1] = 2;
                auto lambda_tree = cast(LambdaTree) *top_tree;
                tree_stack ~= &(lambda_tree.expr);
                visit_stack ~= 1;
            }
        }
        // variable
        else if (top_tree.type == Type.var) {
            tree_stack.length  -= 1;
            visit_stack.length -= 1;
        }
    }
    
    if (outer_left is null) return;
    /*
    writeln("beta-redex");
    showLambdaTree(*outer_left);
    writeln();
    showLambdaTree(*outer_left, false);
    writeln("\n#################\n");
    */
    auto app_tree = cast(ApplyTree) *outer_left;
    
    auto lambda_func = cast(LambdaTree) app_tree.left;
    auto term = app_tree.right;
    auto ass_var = lambda_func.args[0];
    // assign
    if (lambda_func.args.length == 1) {
        assign_lambda(lambda_func.expr, term, ass_var);
        // replace
        *outer_left = lambda_func.expr;
    }
    else {
        // first argument
        lambda_func.args = lambda_func.args[1 .. $];
        // set free/bound variables
        lambda_func.bound_vars.remove(ass_var);
        lambda_func.free_vars[ass_var] = false;
        
        assign_lambda(app_tree.left /* = lambda_func */, term, ass_var);
        // replace
        *outer_left = app_tree.left;
    }
    
    set_FBvars(tree);
}

// show the lambda tree
void showLambdaTree(Tree tree, bool show_fb = true) {
    import std.stdio: write;
    
    if (tree is null) return;
    
    // show free variables | bound variables
    if (tree.type != Type.var && show_fb) {
        write("[");
        foreach(var; tree.free_vars. byKey) write(var, " ");
        write("|");
        foreach(var; tree.bound_vars.byKey) write(var, " ");
        write("]");
    }
    
    // lambda tree
    if (tree.type == Type.lam) {
        auto lam_tree = cast(LambdaTree) tree;
        write("(\\ ");
        // show arguments
        foreach (arg; lam_tree.args) { write(arg, " "); }
        write(". ");
        // show the expression binded to the lambda function
        showLambdaTree(lam_tree.expr, show_fb);
        write(")");
    }
    // (E E')
    else if (tree.type == Type.app) {
        auto app_tree = cast(ApplyTree) tree;
        
                    /*if (app_tree.right.type == Type.app)*/ write("(");
        scope(exit) /*if (app_tree.right.type == Type.app)*/ write(")");
        
        showLambdaTree(app_tree.left, show_fb);
        write(" ");
        showLambdaTree(app_tree.right, show_fb);
    }
    // variable
    else if (tree.type == Type.var) {
        auto var_tree = cast(Variable) tree;
        write(var_tree.name);
    }
}
