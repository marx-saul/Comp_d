import comp_d;
import std.stdio, std.ascii;

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
), ["Expr", "Term", "Factor", "id", "+", "-", "*", "/"]);

struct Node {
    int value;
    Symbol symbol;
    Node* left, right;
    this(Symbol s, int v) { value=v, symbol=s; }
    this(Symbol s) { symbol = s; }
}

Node[] getInput() {
    return [Node(id, 12), Node(add), Node(id, 23), Node(mul), Node(id, 2)];
}

void main(string[] args) {
    
}



