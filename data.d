import std.stdio : writeln;
import std.meta, std.typecons;
import std.algorithm, std.container.rbtree, std.array;

/*
alias Symbol = int;						// start with 0
// *** rule[1].length > 0 *** MUST BE SATISFIED
alias Rule = Tuple!(Symbol, Symbol[]);		// (A, [s, t, u, ... v ])   means   A -> stu...v
alias Grammar = Rule[];
// Like A -> ε ε, the succession of epsilon is not supposed to be in the grammar

enum empty_ = -1, end_of_file = -2, virtual = -3;

// LR table
enum Action : byte { error = 0, accept = 1, shift = 2, reduce = 3, goto_ = 4 }

alias LREntry = Tuple!(Action, ulong);
alias LRTable = LREntry[][Symbol];
*/

// Symbol
//  start symbol is 0.
alias Symbol = int;
enum bool isSymbol(T) = is(T == Symbol);

// Rule
alias Rule = Tuple!(Symbol, "lhs", Symbol[], "rhs");
enum bool isRule(T) = is(T == Rule);

// see the example template 'test' below.
template rule() {
    Rule rule(Args...)(Args symbols) {
        // Args must be the nonempty sequence of Symbol's.
        static assert ( Args.length > 0, "\033[1m\033[32mThere must be at least 1 symbol in rule(...) .\033[0m" );
        static assert ( allSatisfy!(isSymbol, Args), "\033[1m\033[32mThere is a parameter in rule(...) which is not the Symbol type.\033[0m" );
        
        auto rhs = new Symbol[symbols.length-1];
        foreach ( i, sym; symbols[1..$] ) rhs[i] = sym;
        
        //Rule result;
        //result.lhs = symbols[0], result.rhs = rhs;
        //return result;
        return Rule(symbols[0], rhs);
    }
}

// Grammar
alias Grammar = Rule[];

template    grammar() {
    Grammar grammar(Args...)(Args rules) {
        static assert ( Args.length > 0, "\033[1m\033[32mThere must be at least 1 rule in grammar(...) .\033[0m" );
        static assert ( allSatisfy!(isRule, Args), "\033[1m\033[32mThere is a parameter in grammar(...) which is not the Rule type.\033[0m" );
        
        auto result = new Rule[rules.length];
        foreach ( i, rule; rules ) result[i] = rule;
        
        return result;
    }
}


/+
template test(Args1...) {
    void test(Args2...)(Args2 args) {
        import std.stdio : writeln;
        writeln(typeid(Args1));
        writeln(typeid(Args2));
        writeln(args);
    }
}

test(9, " qaws ", 3.14);
// the result is:
=====
()
(int,immutable(char)[],double)
9 qaws 3.14
=====
+/

// for LR table
enum Action : byte { error = 0, accept = 1, shift = 2, reduce = 3, goto_ = 4 }

// empty symbol, end of file symbol (for LRs), virtual (for LALR algorithm)
enum Symbol empty_ = -1, end_of_file_ = -2, virtual = -3;
immutable special_tokens = 3;    // empty_, end_of_file, virtual. see data.d

