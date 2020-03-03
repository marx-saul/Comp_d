module lang;

import comp_d;
import std.stdio, std.ascii;
import std.array;
import std.conv: to;

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

static const table_info = SLRtableInfo(grammar.grammar_info);

struct Token {
    Symbol symbol;
    int value;
    this(Symbol s, int v) { symbol = s; value = v; }
}

class Parser : comp_d.Parser {
    this() {
        super(grammar.grammar_info, table_info);
    }
    
    private int[] stack;
    override void reduce(size_t number_of_rule) {
        
        switch(grammar.labelOf(number_of_rule)) {
            case "add":
                stack[$-3] = stack[$-3] + stack[$-1];
                stack.length -= 2;
            break;
            
            case "sub":
                stack[$-3] = stack[$-3] - stack[$-1];
                stack.length -= 2;
            break;
            
            case "mul":
                stack[$-3] = stack[$-3] * stack[$-1];
                stack.length -= 2;
            break;
            
            case "div":
                stack[$-3] = stack[$-3] / stack[$-1];
                stack.length -= 2;
            break;
            
            case "_Expr_":
                stack[$-3] = stack[$-2];
                stack.length -= 2;
            break;
            
            case "uadd":
                stack[$-2] = +stack[$-1];
                stack.length -= 1;
            break;
            
            case "usub":
                stack[$-2] = -stack[$-1];
                stack.length -= 1;
            break;
            
            default:
            break;
        }
    }
    public int eval(string str) {
        auto tokens = lex(str);
        size_t tkn_ptr;
        while (true) {
            auto symbol = tkn_ptr >= tokens.length ? end_of_file_ : tokens[tkn_ptr].symbol;
            //writeln(symbol, " ", grammar.grammar_info.nameOf(symbol));
            auto code = pushToken(symbol);
            
            if      (code == 0)  { return stack[0]; }
            else if (code == 1)  { writeln("error."); return 0; }
            else if (code != -1) { assert(0); }
            
            stack ~= tokens[tkn_ptr].value;
            tkn_ptr++;
        }
    }
}

// lexer
Token[] lex(string str) {
    Token[] result;
    
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
            result ~= Token(grammar.numberOf("id"), to!int(d_str));
            continue;
        }
        
        // +-*/()
        auto sym_str =
            c == '+' ? "add" :
            c == '-' ? "sub" :
            c == '*' ? "mul" :
            c == '/' ? "div" :
            c == '(' ? "lPar":
            c == ')' ? "rPar":
            "__error";
        if (sym_str != "__error") result ~= Token(grammar.numberOf(sym_str), 0);
        else writeln("Invalid token: " ~ c);
        
        index++;
    }
    //writeln(result);
    return result;
}

int test_lang(string str) {
    auto parser = new Parser;
    return parser.eval(str);
}
