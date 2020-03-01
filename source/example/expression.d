module example.expression;

import comp_d;
import std.stdio, std.ascii;
import std.array;
import std.conv: to;

// definition of the grammar
enum : Symbol {
    Expr, Term, Factor,
    id, add, sub, mul, div, lPar, rPar
}
static const grammar_info = new GrammarInfo(grammar(
    rule(Expr, Expr, add, Term),
    rule(Expr, Expr, sub, Term),
    rule(Expr, Term),
    rule(Term, Term, mul, Factor),
    rule(Term, Term, div, Factor),
    rule(Term, Factor),
    rule(Factor, lPar, Expr, rPar),
    rule(Factor, id),
    rule(Factor, add, id),
    rule(Factor, sub, id),
), ["Expr", "Term", "Factor", "id", "+", "-", "*", "/"]);

// you can make a syntax tree using left and right
struct Node {
    int value;
    Symbol symbol;
    Node* left, right;
    this(Symbol s, int v) { value=v, symbol=s; }
    this(Symbol s) { symbol = s; }
}

class Lexer {
    public Node[] tokens;
    this() {
        tokens = [Node(id, 12), Node(add), Node(id, 23), Node(mul), Node(id, 2), Node(sub), Node(id, 16)];
    }
    // lexer
    this(string str) {
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
                tokens ~= Node(id, to!int(d_str));
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
            if (sym != -1) tokens ~= Node(sym);
            else writeln("Invalid token: " ~ c);
            
            index++;
        }
    }
    
    
    // InputRange
    bool empty() @property {
        return tokens.empty;
    }
    // return Symbol type
    Symbol front() @property {
        return tokens.front.symbol;
    }
    void popFront() {
        tokens.popFront();
    }
    
    Node top_node() @property {
        return tokens.front;
    }
}

/+ //get input from stdin and get tokens.
Lexer getInput() {
    return [Node(id, 12), Node(add), Node(id, 23), Node(mul), Node(id, 2)];
}
+/

int eval(Lexer lex) {
    int[] stack;
    bool error_flag = false;
    
    alias parser = injectParser!(grammar_info, "SLR",
        { /* accept */ },
        (x) { /* reduce */
            switch (x) {
                case 0:     // Expr -> Expr + Term
                    // pop 3 ints from the stack, and push 1 int on the top, while calculationg (first from top, i.e. Expr) + (third from top, i.e. Term)
                    stack[$-3] = stack[$-3] + stack[$-1];
                    stack.length -= 2;
                break;
                
                case 1:     // Expr -> Expr - Term
                    stack[$-3] = stack[$-3] - stack[$-1];
                    stack.length -= 2;
                break;
                
                case 2:     // Expr -> Term
                    // pop 1 node, push 1 node, without modifying value.
                break;
                
                case 3:     // Term -> Term * Factor
                    stack[$-3] = stack[$-3] * stack[$-1];
                    stack.length -= 2;
                break;
                
                case 4:     // Term -> Term / Factor
                    stack[$-3] = stack[$-3] / stack[$-1];
                    stack.length -= 2;
                break;
                
                case 5:     // Term -> Factor
                break;
                
                case 6:     // Factor -> ( Expr )
                    // pop 3 ints and push 1 int, with (new int) = (second from top)
                    stack[$-3] = stack[$-2];
                    stack.length -= 2;
                break;
                
                case 7:     // Factor -> 123
                    //stack[$-1] = stack[$-1];
                break;
                
                case 8:     // Factor -> +691
                    stack[$-2] = stack[$-1];
                    stack.length -= 1;
                break;
                
                case 9:     // Factor -> -691
                    stack[$-2] = -stack[$-1];
                    stack.length -= 1;
                break;
                
                default:
                assert(0);
            }
        },
        (x) { error_flag = true; },           // error
        { stack ~= lex.top_node.value; }      // shift
    );
    
    parser.parse(lex);
    
    if (stack.length != 1 || error_flag) { writeln("Invalid expression."); return 0; }
    return stack[0];
}

int eval(string str) {
    return eval(new Lexer(str));
}
