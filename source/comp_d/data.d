module comp_d.data;

import std.stdio : writeln;
import std.meta, std.typecons;
import std.algorithm, std.container.rbtree, std.array;

/******************************/
// Symbol
alias Symbol = ptrdiff_t;
enum bool isSymbol(T) = is(T : Symbol);

// empty symbol, end of file symbol (for LRs), virtual (for LALR algorithm)
enum Symbol empty_ = -1, end_of_file_ = -2, virtual = -3;
immutable special_tokens = 3;    // empty_, end_of_file, virtual. see data.d

/*******************************/
// Rule
alias Rule = Tuple!(Symbol, "lhs", Symbol[], "rhs");
enum bool isRule(T) = is(T : Rule);

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

/*******************************/
// Grammar
alias Grammar = Rule[];

/*
deprecated template    grammar() {
    Grammar grammar(Args...)(Args rules) {
        static assert ( Args.length > 0, "\033[1m\033[32mThere must be at least 1 rule in grammar(...) .\033[0m" );
        static assert ( allSatisfy!(isRule, Args), "\033[1m\033[32mThere is a parameter in grammar(...) which is not the Rule type.\033[0m" );
        
        auto result = new Rule[rules.length];
        foreach ( i, rule; rules ) result[i] = rule;
        
        return result;
    }
}
*/

/*******************************/
// for LR table (moved to LRTable.d)
//alias LREntry = Tuple!(Action, ulong);
//alias LRTable = LREntry[][Symbol];

