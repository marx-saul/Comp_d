module expression;

import comp_d;
import std.stdio, std.ascii;
import std.array;
import std.conv: to;

// definition of grammar
alias grammar = defineGrammar!(`
    Expr:
        @add Expr add Term,
        @sub Expr sub Term,
             Term;
    
    Term:
        @mul Term mul Factor,
        @div Term div Factor,
             Factor;
    
    Factor:
        @_Expr_ lPar Expr rPar,
                id,
        @uadd   add id,
        @usub   sub id;
`);
// symbol declarations
mixin ("enum : Symbol {" ~ grammar.tokenDeclarations ~ "}");

static const table_info = SLRtableInfo(grammar.grammar_info);

// you can make a syntax tree using left and right
struct Node {
    Symbol symbol;
    Tree[] children;
    size_t rule;
    int value;
    this(Symbol s, int v) { value=v, symbol=s; }
    this(Symbol s) { symbol = s; }
}

// lexer
Node[] lex(string str) {
    Node[] tokens;
    
    // generate tokens.
    size_t index;
    while (index < str.length) {
        char c = str[index];
        // ignore space
        if (isWhite(c)) { index++; continue; }
        
        // digit
        if (isDigit(c)) {
            string d_str;
            while (index < str.length && isDigit(str[index])) {
                d_str ~= str[index];
                index++;
            }
            //writeln(d_str);
            tokens ~= new Node(id, to!int(d_str));
            continue;
        }
            
        // +-*/()
        auto sym =
            c == '+' ? add :
            c == '-' ? sub :
            c == '*' ? mul :
            c == '/' ? div :
            c == '(' ? lPar:
            c == ')' ? rPar:
            -1;
        if (sym != -1) tokens ~= new Node(sym);
        else writeln("Invalid token: " ~ c);
        
        index++;
    }
    
    return tokens;
}

int eval(string str) {
    auto tokens = lex(str);
    
    int[] stack;
    State[] state_stack = [0];
    while (true) {
        auto result = oneStep(grammar.grammar_info.grammar, table_info.table, tokens.empty ? end_of_file_ : tokens.front.symbol, state_stack);
        // SHIFT
        if      (result.action == Action.shift)  {
            stack ~= tokens.front.value;
            tokens.popFront();
        }
        // REDUCE
        else if (result.action == Action.reduce) {
            switch (grammar.labelOf(result.num)) {
                case "add":     // Expr -> Expr + Term
                    // pop 3 ints from the stack, and push 1 int on the top, while calculationg (first from top, i.e. Expr) + (third from top, i.e. Term)
                    stack[$-3] = stack[$-3] + stack[$-1];
                    stack.length -= 2;
                break;
                
                case "sub":     // Expr -> Expr - Term
                    stack[$-3] = stack[$-3] - stack[$-1];
                    stack.length -= 2;
                break;
                
                case "mul":     // Term -> Term * Factor
                    stack[$-3] = stack[$-3] * stack[$-1];
                    stack.length -= 2;
                break;
                
                case "div":     // Term -> Term / Factor
                    stack[$-3] = stack[$-3] / stack[$-1];
                    stack.length -= 2;
                break;
                
                case "_Expr_":  // Factor -> ( Expr )
                    // pop 3 ints and push 1 int, with (new int) = (second from top)
                    stack[$-3] = stack[$-2];
                    stack.length -= 2;
                break;
                
                case "uadd":    // Factor -> + 691
                    stack[$-2] = stack[$-1];
                    stack.length -= 1;
                break;
                
                case "usub":    // Factor -> - 691
                    stack[$-2] = -stack[$-1];
                    stack.length -= 1;
                break;
                
                default:
                break;
            }
        }
        else if (result.action == Action.accept) break;
        else if (result.action == Action.error)  { writeln("Invalid expression."); return 0; }
    }
    return stack[0];
}

