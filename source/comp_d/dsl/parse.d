// parse DSL
module comp_d.dsl.parse;

import comp_d.Set;
import std.stdio, std.ascii;
import std.array, std.range, std.algorithm, std.algorithm.comparison;
import std.meta;
import std.conv: to;

// dictionary order
bool stringLess(string a, string b) {
    if (a.length < b.length) return true;
    if (a.length > b.length) return true;
    foreach (i, c1; a) {
        auto c2 = b[i];
        if (c1 < c2) return true;
        if (c1 > c2) return false;
    }
    return false;
}
alias StringSet = Set!(string, stringLess);

struct DSLGrammar {
    DSLRule[] rules;
    StringSet symbol_set;
    string[] labels;
}

struct DSLRule {
    string label;   // label of the rule
    string lhs;     // lhs
    string[] rhs;   // rhs
    //string[] name;  /** 'name' */
}

static immutable special_tokens = ",:;@()";

unittest {
    //static const strset = new StringSet("sadfsdaf", "qwertyuiop", "09fjhgkve", "\n\n");
    //writeln(strset.array);
    
    //string text = "S : @_label_1 A B C  D, @label2 EF G X; X: @label_2 A B,;";
    //auto dsl_grammar = parse(text);
    /+
    foreach (rule; dsl_grammar.rules) {
        writeln("@", rule.label, ": ", rule.lhs, ":", rule.rhs);
    }
    +/
    
    //writeln("## dsl.parse.d unittest 1");
}

/////////////////////////////
/////////////////////////////
pure bool isIdentifier(string token) {
    return token.length > 0 && (isAlpha(token[0]) || token[0] == '_');
}

DSLGrammar parse(string text) {
    DSLGrammar result; result.symbol_set = new StringSet();
    size_t index;
    auto token = nextToken(text, index);
    
    StringSet label_set = new StringSet();
    
    while (token != "") {
        auto rules = parseRuleList(token, text, index);
        result.rules ~= rules;
        
        // collect all the appearing symbols
        foreach (rule; rules) {
            result.symbol_set.add(rule.lhs);
            foreach (symbol; rule.rhs) result.symbol_set.add(symbol);
        }
        
        // collet all the label
        foreach (rule; rules) {
            if (rule.label == "") continue;
            auto previous_cardinal = label_set.cardinal;
            label_set.add(rule.label);
            // already appeared
            if (label_set.cardinal == previous_cardinal)
                assert(0, "The label '@" ~ rule.label ~ "' already appeared. index="  ~ to!string(index) );
        }
    }
    
    result.symbol_set.remove("empty");
    return result;
}

// "A : rule, rule, rule,;"
DSLRule[] parseRuleList(ref string token, string text, ref size_t index)  {
    if (!isIdentifier(token)) { assert(0, "Identifier expected. index=" ~ to!string(index) ); }
    auto lhs = token;
    
    token = nextToken(text, index);
    if (token != ":") { assert(0, "':' is expected. index=" ~ to!string(index) ); }
    token = nextToken(text, index);
    
    DSLRule[] result;
    
    while (true) {
        auto rule = parseRhs(token, lhs, text, index);
        result ~= rule;
        
        if (token == ",") { token = nextToken(text, index); }
        
        if      (isIdentifier(token) || token == "@") continue;
        else if (token == ";") { token = nextToken(text, index); break; }
        else assert(0, "',', ';', '@' or an identifier expected. index=" ~ to!string(index) );
    }
    
    return result;
}

// parse "@label identifier1 identifier2(name2)"
DSLRule parseRhs(ref string token, string lhs, string text, ref size_t index) {
    DSLRule result; result.lhs = lhs;
    assert(token.length > 0);
    // label
    if      (token == "@") {
        token = nextToken(text, index);
        if (token == "") { assert(0); }
        if (!isIdentifier(token)) { assert(0, "Identifier must come after '@'. index=" ~ to!string(index) ); }
        result.label = token;
        token = nextToken(text, index);
    }
    else if (!isIdentifier(token)) { assert(0, "Identifier or an label is expected. index=" ~ to!string(index)); }
    
    while (isIdentifier(token)) {
        result.rhs ~= token;
        token = nextToken(text, index);
        
        /* * 'name'
        if (token == "(") {
            token = nextToken(text, index);
            if (!isIdentifier(token)) { assert(0, "Identifier must come after '('. index=" ~ to!string(index)); }
            result.name ~= token;
            token = nextToken(text, index);
            if (token != ")") { assert(0, "')' is expected. index = " ~ to!string(index)); }
            token = nextToken(text, index);
        }
        else { result.name ~= ""; }
        */
    }
    
    return result;
}

string nextToken(string text, ref size_t index) {
    string result;
    // skip spaces
    while (index < text.length && isWhite(text[index])) {
        index++;
    }
    if (index >= text.length) return result;
    
    // identifier
    if (index < text.length && (isAlpha(text[index]) || text[index] == '_') ) {
        while (index < text.length && (isAlphaNum(text[index]) || text[index] == '_') ) {
            result ~= text[index];
            index++;
        }
    }
    // other symbols
    else if (text[index].among!(aliasSeqOf!special_tokens)) {
        result ~= text[index];
        index++;
    }
    // invalid
    else { assert(0, "Invalid character: " ~ text[index]); }
    
    return result;
}

