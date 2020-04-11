module comp_d.tool;

import comp_d.data;
import std.typecons;
import std.array, std.container;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln, write;
import std.conv: to;

unittest {
    /*
    static const set1 = new SymbolSet(4, [2,3,-1]);
    SymbolSet Test1() {
        auto result = new SymbolSet(4, [2,3,1]);
        result.add(-2,-1);
        return result;
    }
    static const set2 = Test1();
    static assert (1 !in set1);
    static assert (set1 in set2);
    static const set3 = new SymbolSet(4, [-2, 1]);
    static assert (set1 + set3 == set2);
    
    static assert (new SymbolSet(4, [-3, -2, -1, 0, 1, 2, 3]) - new SymbolSet(4, [-3, -1, 0, 2, 3]) == set3);
    
    static assert ( equal((set1 & set2).array, [-1, 2, 3]) );
    static assert ( equal((new SymbolSet(4, [-2, 2, 3]) & set2).array, [-2, 2, 3]) );
    */
    
    auto set1 = new SymbolSet(4, [2,3,-1]);
    SymbolSet Test1() {
        auto result = new SymbolSet(4, [2,3,1]);
        result.add(-2,-1);
        return result;
    }
    auto set2 = Test1();
    assert (1 !in set1);
    assert (set1 in set2);
    auto set3 = new SymbolSet(4, [-2, 1]);
    assert (set1 + set3 == set2);
    
    assert (new SymbolSet(4, [-3, -2, -1, 0, 1, 2, 3]) - new SymbolSet(4, [-3, -1, 0, 2, 3]) == set3);
    
    assert ( equal((set1 & set2).array, [-1, 2, 3]) );
    assert ( equal((new SymbolSet(4, [-2, 2, 3]) & set2).array, [-2, 2, 3]) );
    
    writeln("## tool.d unittest 1");
}

unittest {
    enum : Symbol {
        Expr, Term, Factor,
        digit, add, mul, lPar, rPar
    }
    /*
    static const grammar_info = new GrammarInfo([
        rule(Expr, Expr, add, Term),
        rule(Expr, Term),
        rule(Term, Term, mul, Factor),
        rule(Term, Factor),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar)
    ]);
    // FIRST(Expr) = FIRST(Term) = FIRST(Factor) = {digit, lPar}
    static const first_table  = grammar_info.first_test();
    static const follow_table = grammar_info.follow_test();
    
    //writeln(first_table[Expr].array);
    static assert ( equal(first_table[Expr]  .array, [digit, lPar]) );
    static assert ( equal(first_table[Term]  .array, [digit, lPar]) );
    static assert ( equal(first_table[Factor].array, [digit, lPar]) );
    
    static assert ( equal(follow_table[Expr]  .array, [end_of_file_, add, rPar]) );
    static assert ( equal(follow_table[Term]  .array, [end_of_file_, add, mul, rPar]) );
    static assert ( equal(follow_table[Factor].array, [end_of_file_, add, mul, rPar]) );
    */
    
    auto grammar_info = new GrammarInfo([
        rule(Expr, Expr, add, Term),
        rule(Expr, Term),
        rule(Term, Term, mul, Factor),
        rule(Term, Factor),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar)
    ]);
    // FIRST(Expr) = FIRST(Term) = FIRST(Factor) = {digit, lPar}
    auto first_table  = grammar_info.first_test();
    auto follow_table = grammar_info.follow_test();
    
    //writeln(first_table[Expr].array);
    assert ( equal(first_table[Expr]  .array, [digit, lPar]) );
    assert ( equal(first_table[Term]  .array, [digit, lPar]) );
    assert ( equal(first_table[Factor].array, [digit, lPar]) );
    
    assert ( equal(follow_table[Expr]  .array, [end_of_file_, add, rPar]) );
    assert ( equal(follow_table[Term]  .array, [end_of_file_, add, mul, rPar]) );
    assert ( equal(follow_table[Factor].array, [end_of_file_, add, mul, rPar]) );
    writeln("## tool.d unittest 2");
}

unittest {
    enum : Symbol {
        Expr, Expr_, Term, Term_, Factor,
        digit, add, mul, lPar, rPar
    }
    /*
    static const grammar_info = new GrammarInfo([
        rule(Expr, Term, Expr_),
        rule(Expr_, add, Term, Expr_),
        rule(Expr_, empty_),
        rule(Term, Factor, Term_),
        rule(Term_, mul, Factor, Term_),
        rule(Term_, empty_),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar)
    ]);
    
    static const first_table  = grammar_info.first_test();
    static const follow_table = grammar_info.follow_test();
    
    static assert ( equal(first_table[Expr]  .array, [digit, lPar]) );
    static assert ( equal(first_table[Expr_] .array, [empty_, add]) );
    static assert ( equal(first_table[Term]  .array, [digit, lPar]) );
    static assert ( equal(first_table[Term_] .array, [empty_, mul]) );
    static assert ( equal(first_table[Factor].array, [digit, lPar]) );
    
    static assert ( equal(follow_table[Expr]  .array, [end_of_file_, rPar]) );
    static assert ( equal(follow_table[Expr_] .array, [end_of_file_, rPar]) );
    static assert ( equal(follow_table[Term]  .array, [end_of_file_, add, rPar]) );
    static assert ( equal(follow_table[Term_] .array, [end_of_file_, add, rPar]) );
    static assert ( equal(follow_table[Factor].array, [end_of_file_, add, mul, rPar]) );
    static assert ( follow_table[Factor].cardinal ==  follow_table[Factor].array.length);
    */
    
    auto grammar_info = new GrammarInfo([
        rule(Expr, Term, Expr_),
        rule(Expr_, add, Term, Expr_),
        rule(Expr_, empty_),
        rule(Term, Factor, Term_),
        rule(Term_, mul, Factor, Term_),
        rule(Term_, empty_),
        rule(Factor, digit),
        rule(Factor, lPar, Expr, rPar)
    ]);
    
    auto first_table  = grammar_info.first_test();
    auto follow_table = grammar_info.follow_test();
    
    assert ( equal(first_table[Expr]  .array, [digit, lPar]) );
    assert ( equal(first_table[Expr_] .array, [empty_, add]) );
    assert ( equal(first_table[Term]  .array, [digit, lPar]) );
    assert ( equal(first_table[Term_] .array, [empty_, mul]) );
    assert ( equal(first_table[Factor].array, [digit, lPar]) );
    
    assert ( equal(follow_table[Expr]  .array, [end_of_file_, rPar]) );
    assert ( equal(follow_table[Expr_] .array, [end_of_file_, rPar]) );
    assert ( equal(follow_table[Term]  .array, [end_of_file_, add, rPar]) );
    assert ( equal(follow_table[Term_] .array, [end_of_file_, add, rPar]) );
    assert ( equal(follow_table[Factor].array, [end_of_file_, add, mul, rPar]) );
    assert ( follow_table[Factor].cardinal ==  follow_table[Factor].array.length);
    
    writeln("## tool.d unittest 3");
}

class GrammarInfo {
    public Grammar grammar;
    private bool augment_flag;
    private string[] symbol_name_dictionary;
    public  string nameOf(inout const Symbol sym) inout {
        if      (sym == virtual)      return "#";
        else if (sym == end_of_file_) return "$";
        else if (sym == empty_)       return "ε";
        else if (0 <= sym && sym < symbol_name_dictionary.length) return symbol_name_dictionary[sym];
        else if (sym == max_symbol_number && augment_flag) return "S'";
        else return to!string(sym);
    }
    /*public  Symbol symbolOf(inout const string name) inout {
        import std.algorithm.searching : countUntil;
        return countUntil(name, symbol_name_dictionary);
    }*/
    private string[] rule_label;
    public pure string labelOf(inout const size_t index) inout {
        if (index >= rule_label.length) return to!string(index);
        else if (rule_label[index].length > 0) return rule_label[index];
        else return to!string(index);
    }
    private Symbol start_symbol;
    public pure Symbol start_sym() @property inout {
        return start_symbol;
    }
    private Symbol max_symbol_number;
    public pure Symbol max_symbol_num() @property inout {
        return max_symbol_number;
    }
    private SymbolSet appearing_symbols;
    public pure immutable(SymbolSet) appearings() @property inout {
        return cast(immutable SymbolSet) appearing_symbols;
    }
    private Symbol[]  appearing_symbols_array;
    private SymbolSet nonterminal_symbols;
    public pure immutable(SymbolSet) nonterminals() @property inout {
        return cast(immutable SymbolSet) nonterminal_symbols;
    }
    private Symbol[]  nonterminal_symbols_array;
    private SymbolSet terminal_symbols;
    public pure immutable(SymbolSet) terminals() @property inout {
        return cast(immutable SymbolSet) terminal_symbols;
    }
    private Symbol[]  terminal_symbols_array;
    private SymbolSet[] first_table;
    private SymbolSet[] follow_table;
    // ///////////////////////////////////////////////////////////////////////////////////////////
    this (Grammar g, string[] snd = [], string[] rl = [], bool augment = true) {
        assert(g.length > 0, "\033[1m\033[32mthe length of the grammar must be > 0.\033[0m");
        symbol_name_dictionary = snd;
        rule_label = rl;
        
        // the maximum of the symbol number in the grammar.
        max_symbol_number = g.map!((Rule rule) => maxSymbolNumber(rule)).reduce!((a,b) => max(a,b));
        
        augment_flag = augment;
        if (augment) {
            grammar = g ~ [rule(max_symbol_num+1, g[0].lhs)];
            ++max_symbol_number;
            start_symbol = max_symbol_number;
        }
        else {
            grammar = g;
            start_symbol = g[0].lhs;
        }
        // cut empty
        foreach (ref rule; grammar) {
            if (rule.rhs.length == 0 || rule.rhs.all!(a => a == empty_)) rule.rhs = [empty_];
            else rule.rhs = rule.rhs.filter!(a => a != empty_).array;
        }
        
        // set of symbols that appear in the grammar
        appearing_symbols = appearingSymbolSet(grammar);
        appearing_symbols_array = appearing_symbols.array;
        // nonterminal symbols
        nonterminal_symbols = nonterminalSet(grammar);
        nonterminal_symbols_array = appearing_symbols.array;
        terminal_symbols = appearing_symbols - nonterminal_symbols;
        terminal_symbols_array = terminal_symbols.array;
        // first table
        first_table = calcFirstTable(grammar, max_symbol_number, appearing_symbols, nonterminal_symbols);
        // follow table
        follow_table = calcFollowTable(grammar, nonterminal_symbols);
        
    }
    
    private pure Symbol maxSymbolNumber(Rule rule) inout {
        return max( rule.lhs, rule.rhs.reduce!((a,b) => max(a,b)) );
    }
    
    // for symbol set
    public pure SymbolSet symbolSet(Symbol[] args...) inout {
        return new SymbolSet(max_symbol_number, args);
    }
    
    // nonterminal, appearing
    private pure SymbolSet appearingSymbolSet(Grammar grammar) {
        auto result = symbolSet();
        foreach (rule; grammar) {
            result.add(rule.lhs);
            result.add(rule.rhs);
        }
        // these cannot appear
        if (end_of_file_ in result || virtual in result) {
            assert(0, "\033[1m\033[32mend_of_file_ or virtual cannot be in the grammar.\033[0m");
        }
        result.remove(empty_);
        return result;
    }
    
    private pure SymbolSet nonterminalSet(Grammar grammar) {
        auto result = symbolSet();
        foreach (rule; grammar)
            result.add(rule.lhs);
        return result;
    }
    // ///////////////////////////////////////////////////////////////////////////////////////////
    // first set
    private pure SymbolSet[] calcFirstTable(Grammar grammar, Symbol max_symbol_number, const SymbolSet appearing_symbols, const SymbolSet nonterminal_symbols) {
        auto result = new SymbolSet[max_symbol_number+1];
        foreach (i; 0 .. max_symbol_number+1) result[i] = symbolSet();
        
        // cut and add empty 
        foreach (ref rule; grammar) {
            auto new_rule = rule.rhs.filter!(symbol => symbol != empty_).array;
            //writeln(rule.rhs);
            if (new_rule.empty) result[rule.lhs].add(empty_);
        }
        // cut empty generating rules
        auto grammar2 = grammar.filter!( rule => !rule.rhs.filter!(symbol => symbol != empty_).empty );
        
        // if X is a terminal symbol, FIRST(X) = {X}
        foreach (sym; appearing_symbols_array) {
            if (sym in terminal_symbols) result[sym].add(sym);
        }
        
        // if there is a rule X -> Y0 Y1 ... Yn, add FIRST(Y0) to FIRST(X)
        // if ε ∈ FIRST(Y0), ... FIRST(Yk-1), add FIRST(Yk) to FIRST(X) (k = 1, ..., n)
        // if ε ∈ FIRST(Y0), ... FIRST(Yn), add ε to FIRST(X)
        // X = rule.lhs, Yk = rule.rhs[k], FIRST(X) = result[X];
        
        while (true) {
            bool nothing_to_add = true;
            
            foreach (rule; grammar2) {
                auto previous_num = result[rule.lhs].cardinal;
                
                // already empty_ is in the rule
                auto empty_in = empty_ in result[rule.lhs];
                
                bool all_empty_flag = true;
                foreach (k; 0 .. rule.rhs.length) {
                    // add FIRST(Yk) to FIRST(X)
                    result[rule.lhs] += result[rule.rhs[k]];
                    
                    // if empty_ not in FIRST(Yk)
                    if (empty_ !in result[rule.rhs[k]]) {
                        all_empty_flag = false;
                        break;
                    }
                }
                if (!all_empty_flag && !empty_in) result[rule.lhs].remove(empty_);
            
                // FIRST(X) was updated
                if (result[rule.lhs].cardinal > previous_num) nothing_to_add = false;
            }
            if (nothing_to_add) break;
        }
        
        return result;
    }
    
    // FIRST(Y)
    private pure SymbolSet first(inout Symbol symbol) inout {
        if (symbol.among!(empty_, end_of_file_, virtual)) return symbolSet(symbol);
        else return cast(SymbolSet) first_table[symbol];
    }
    
    // FIRST(Y0 Y1 ... Yn)
    public pure SymbolSet first(inout(Symbol)[] symbols) inout const {
        auto result = symbolSet();
        if (symbols.length == 0) {
            result.add(empty_);
            return result;
        }
        
        bool all_empty_flag = true;
        foreach (k; 0 .. symbols.length) {
            // add FIRST(Yk) to FIRST(X)
            result += first(symbols[k]);
            // if empty_ not in FIRST(Yk)
            if (empty_ !in first(symbols[k])) {
                all_empty_flag = false;
                break;
            }
        }
        if (!all_empty_flag) result.remove(empty_);
        
        return result;
    }
    // ///////////////////////////////////////////////////////////////////////////////////////////
    // follow set
    public pure SymbolSet[] calcFollowTable(Grammar grammar, const SymbolSet nonterminals) {
        auto result = new SymbolSet[max_symbol_number+1];
        foreach (i; 0 .. max_symbol_number+1) result[i] = symbolSet();
        // add end_of_file to FOLLOW(start_symbol)
        result[start_symbol].add(end_of_file_);
        
        // for rule "A -> sBt" with s, t any sequence (including empty) and B a nonterminal symbol,
        // add elements in FIRST(t) except empty to FOLLOW(B)
        // if empty is in FIRST(t) (or the length of t is 0), add all elements of FOLLOW(A) to FOLLOW(B).
        while (true) {
            bool nothing_to_add = true;
            foreach (rule; grammar) {
                foreach (i, symbol; rule.rhs) {
                    // ignore empty
                    if (symbol < 0) continue;
                    auto previous_num = result[symbol].cardinal;
                    
                    if (symbol !in nonterminals) continue;
                    auto first_t = first(rule.rhs[i+1 .. $]);
                    result[symbol] += first_t;
                    if (empty_ in first_t) result[symbol] += result[rule.lhs];
                    
                    // FOLLOW(symbol) was updated
                    if (result[symbol].cardinal > previous_num) nothing_to_add = false;
                }
            }
            if (nothing_to_add) break;
        }
        
        foreach (set; result) set.remove(empty_);
        
        return result;
    }
    
    // FOLLOW(A)
    public pure SymbolSet follow(Symbol symbol) inout {
        if (symbol.among!(empty_, end_of_file_, virtual)) assert(0, "follow cannot take parameter, " ~ to!string(symbol));
        else return cast(SymbolSet) follow_table[symbol];
    }
    /////////////////////////////////////////////////////////////////////////////////////////////
    version (unittest) {
        public void test() inout {
            writeln("\033[1m\033[32mFIRST SET\033[0m");
            foreach (sym, set; first_table) {
                if (sym in nonterminal_symbols) writeln(sym, " : ", set.array);
            }
            writeln("\033[1m\033[32mFOLLOW SET\033[0m");
            foreach (sym, set; follow_table) {
                if (sym in nonterminal_symbols) writeln(sym, " : ", set.array);
            }
        }
        public inout(SymbolSet)[] first_test() inout {
            return cast(inout) first_table;
        }
        public inout(SymbolSet)[] follow_test() inout {
            return cast(inout) follow_table;
        }
        
    }
}

// ///////////////////////////////////////////////////////////////////////////////////////////

// show first tables
void showFirstTable(const GrammarInfo grammar_info) {
    foreach (sym; grammar_info.nonterminals.array) {
        write("First(", grammar_info.nameOf(sym), ")\t= {");
        foreach (sym2; grammar_info.first(sym).array) write(grammar_info.nameOf(sym2), ", ");
        writeln("},");
    }
}

// show first tables
void showFollowTable(const GrammarInfo grammar_info) {
    foreach (sym; grammar_info.nonterminals.array) {
        write("Follow(", grammar_info.nameOf(sym), ")\t= {");
        foreach (sym2; grammar_info.follow(sym).array) write(grammar_info.nameOf(sym2), ", ");
        writeln("},");
    }
}

/****************************
 * CONSTRUCTOR MUST BE CALLED
 ***************************/ 
package class SymbolSet {
    // data[symbol+special_tokens] is true iff symbol is in the set.
    private bool[] data;
    private Symbol max_symbol_number;
    
    public pure @property Symbol[] array() inout {
        Symbol[] result;
        foreach (i, flag; data) {
            if (flag) result ~= cast(Symbol)i-special_tokens;
        }
        return result;
    }
    private size_t cardinal_;
    public pure @property size_t cardinal() inout {
        return cardinal_;
        /+ulong result;
        foreach(flag; data) if (flag) ++result;
        return result;+/
    }
    
    pure this(Symbol msn, Symbol[] args) {
        this(msn);
        add(args);
    }
    pure this(Symbol msn) {
        Symbol max_symbol_number = msn;
        data.length = max_symbol_number + special_tokens+1;
    }
    
    public pure void add(Symbol[] args...) {
        foreach (arg; args) {
            if (0 <= arg+special_tokens && arg+special_tokens <= data.length) {
                if (!data[arg+special_tokens]) {
                    cardinal_++;
                    data[arg+special_tokens] = true;
                }
            }
            else
                assert(0, "\033[1m\033[32mSymbolSet.add got a parameter out of range.\033[0m");
        }
    }
    public pure void remove(Symbol[] args...) {
        
        foreach (arg; args) {
            if (0 <= arg+special_tokens && arg+special_tokens <= data.length) {
                if (data[arg+special_tokens]) {
                    cardinal_--;
                    data[arg+special_tokens] = false;
                }
            }
            else
                assert(0, "\033[1m\033[32mSymbolSet.add got a parameter out of range.\033[0m");
            
        }
    }
    
    // in the operator overloadings, it is assumed that max_symbol_number are equal.
    
    // "in" overload (element)
    public pure bool opBinaryRight(string op)(inout Symbol elem) inout
        if (op == "in")
    {
        return data[elem+special_tokens];
    }
    
    // "in" overload (containment)
    public pure bool opBinary(string op)(inout SymbolSet rhs) inout
        if (op == "in")
    {
        foreach (i, flag; data) {
            if (flag && !rhs.data[i]) return false;
        }
        return true;
    }
    
    // "==" overload
    override public pure bool opEquals(Object o) {
        auto rhs = cast(SymbolSet) o;
        return (this in rhs) && (rhs in this);
    }
    
    // "+", "-" overload: cup, sub
    public pure SymbolSet opBinary(string op)(inout SymbolSet rhs) inout
        if (op == "+" || op == "-")
    {
        auto result = new SymbolSet(max_symbol_number);
        result.data = this.data.dup;
        foreach (i, flag; rhs.data) if (flag) result.data[i] = (op == "+");
        result.cardinal_ = result.array.length;
        return result;
    }
    
    public pure SymbolSet opOpAssign(string op)(inout SymbolSet rhs) {
        // operator "+=" overload
        static if (op == "+" || op == "-") {
            foreach (i, flag; rhs.data) if (flag) this.data[i] = (op == "+");
            this.cardinal_ = this.array.length;
            return this;
        }
        else assert(0, "\033[1m\033[32m" ~ op ~ "= for Set is not implemented.\033[0m");
    }
    
    // operator "&" overload
    // cap
    public pure SymbolSet opBinary(string op)(inout SymbolSet set2) inout
        if (op == "&")
    {
        auto result = new SymbolSet(max_symbol_number);
        result.data.length = this.data.length;
        foreach (i; 0 .. result.data.length) result.data[i] = (this.data[i] && set2.data[i]);
        result.cardinal_ = result.array.length;
        return result;
    }
}
/+
// compare two symbol sets (which are assumed to have same max_symbol_number)
bool SymbolSetLess(SymbolSet a, SymbolSet b) {
    if      (a.cardinal < b.cardinal) return true;
    else if (a.cardinal > b.cardinal) return false;
    
    if      (a.max_symbol_number < b.max_symbol_number) return true;
    else if (a.max_symbol_number > b.max_symbol_number) return false;
    
    foreach (i; 0 .. a.data.length) {
        if      (a.data[i] && !b.data[i]) return true;
        else if (!a.data[i] && b.data[i]) return false;
    }
    
    return false;
}
+/
