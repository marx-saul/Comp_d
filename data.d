import std.stdio : writeln;
import std.meta, std.typecons;
import std.algorithm;
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

class Set(T) {
    private bool[T] _arr;
    public immutable(bool)[T] arr() @property {
        return cast(immutable(bool)[T]) _arr;
    }
    public this(T[] elems...) {
        add(elems);
    }
    
    public T[] toList() @property {
        return _arr.keys;
    }
    
    public void add(T[] elems...) {
        foreach (t; elems) _arr[t] = true;
    }
    public void remove(T[] elems...) {
        foreach (t; elems) _arr.remove(t);
    }
    
    // operator "in" overload (element)
    public bool opBinaryRight(string op)(T t)
        if (op == "in")
    {
        return (t in _arr) !is null;
    }
    
    // operator "in" overload (containment)
    public bool opBinary(string op)(Set!T set2)
        if (op == "in")
    {
        foreach (t; _arr.byKey)
            if (t !in set2) return false;
        return true;
    }
    
    // operator "==" overload
    public override bool opEquals(Object o) {
        auto a = cast(Set!T) o;
        return ( a in this ) && ( this in a ) ;
    }
    
    // operator "+" overload
    // cup
    public Set!T opBinary(string op)(Set!T set2)
        if (op == "+")
    {
        auto result = new Set!T();
        foreach (t; this._arr.byKey) result.add(t);
        foreach (t; set2._arr.byKey) result.add(t);
        return result;
    }
    
    // operator "-" overload
    // subtract
    public Set!T opBinary(string op)(Set!T set2)
        if (op == "-")
    {
        auto result = new Set!T();
        foreach (t; this._arr.byKey) result.add(t);
        foreach (t; set2._arr.byKey) result.remove(t);
        return result;
    }
    
    public Set!T opOpAssign(string op)(Set!T set2) {
        // operator "+=" overload
        static if (op == "+") {
            foreach (t; set2._arr.byKey) this.add(t);
            return this;
        }
        // operator "-=" overload
        else if (op == "-") {
            foreach (t; set2._arr.byKey) this.remove(t);
            return this;
        }
        else assert(0, op ~ " for Set is not implemented.");
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

