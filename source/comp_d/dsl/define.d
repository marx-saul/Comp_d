module comp_d.dsl.define;

import comp_d.dsl.parse;
import comp_d.data, comp_d.tool;
import std.stdio, std.ascii;
import std.array, std.range, std.algorithm, std.algorithm.comparison;
import std.meta, std.typecons;
import std.conv: to;

unittest {
    alias grammar = defineGrammar!(`
        S >
            @label1  A B a b |
            @label2_ B(_1) B(_2) a A |
            ;
        A : 
            a |
            empty |
            ;
        B :
            @_label3 b(_1) b(_2) B,
            b
            ;
    `);
    
    writeln(grammar.grammar_info.grammar);
    writeln(grammar.grammar_info.labelOf(1));
    writeln(grammar.grammar_info.nameOf(1));
    writeln(grammar.numberOf("S"));
    writeln("## define.d unittest 1");
}

Tuple!(GrammarInfo, string[]) generateGrammar(const string text) {
    auto dsl_grammar = parse(text);
    
    // all the symbols appeared in the grammar
    StringSet symbol_set = dsl_grammar.symbol_set;
    // their names
    string[] symbol_names = symbol_set.array;
    // 
    auto symbol_names_range = assumeSorted!(stringLess)(symbol_names);
    Symbol number_of_symbol(string s) {
        if (s == "empty") return empty_;
        return cast(Symbol) symbol_names_range.lowerBound!(SearchPolicy.binarySearch)(s).length;
    }
    
    Grammar grammar = [];
    string[] rule_labels = [];
    foreach (rule; dsl_grammar.rules) {
        rule_labels ~= rule.label;
        grammar ~= Rule(number_of_symbol(rule.lhs), rule.rhs.map!(number_of_symbol).array);
    }
    
    return tuple(new GrammarInfo(grammar, symbol_names, rule_labels), symbol_names);
}

template defineGrammar(alias string text) {
    static const temp = generateGrammar(text);
    static const grammar_info = temp[0];
    static const symbol_names = temp[1];
    
    Symbol numberOf(const string s) {
        //writeln(symbol_names);
        if (s == "empty") return empty_;
        auto symbol_names_range = assumeSorted!(stringLess)(symbol_names);
        return cast(Symbol) symbol_names_range.lowerBound!(SearchPolicy.binarySearch)(s).length;
    }
    
    string labelOf(const size_t index) {
        return grammar_info.labelOf(index);
    }
    /+string nameOf (const Symbol sym) {
        return grammar_info.nameOf(sym);
    }+/
    
    string tokenDeclarations() @property {
        string result = " ";
        foreach (i; 0 .. grammar_info.max_symbol_num + 1) {
            if (i in grammar_info.terminals) { result ~= symbol_names[i] ~ " = " ~ to!string(i) ~ ", "; }
        }
        return result[0 .. $-2];
    }
}
