// parse DSL
module comp_d.dsl.parse;

import comp_d.Set;
import std.stdio, std.ascii;
import std.array, std.range, std.algorithm, std.algorithm.comparison;
import std.meta;
import std.conv: to;

// dictionary order
pure bool stringLess(string a, string b) {
    if (a.length < b.length) return true;
    if (a.length > b.length) return false;
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
    string[] name;  /** 'name' */
}

static immutable special_tokens = ",|>:;@()";

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
    size_t index, line_num;
    auto token = nextToken(text, index, line_num);
    
    StringSet label_set = new StringSet();
    
    while (token != "") {
        auto rules = parseRuleList(token, text, index, line_num);
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
                assert(0, "The label '@" ~ rule.label ~ "' already appeared. Line Number=" ~ to!string(line_num) );
        }
    }
    
    result.symbol_set.remove("empty");
    return result;
}

// "A : rule, rule, rule,;"
DSLRule[] parseRuleList(ref string token, string text, ref size_t index, ref size_t line_num)  {
    if (!isIdentifier(token)) { assert(0, "Identifier expected. Line Number=" ~ to!string(line_num) ); }
    auto lhs = token;
    
    token = nextToken(text, index, line_num);
    if (token != ":" && token != ">") { assert(0, "':' or '>' is expected. Line Number=" ~ to!string(line_num) ); }
    token = nextToken(text, index, line_num);
    
    DSLRule[] result;
    
    while (true) {
        auto rule = parseRhs(token, lhs, text, index, line_num);
        result ~= rule;
        
        if (token == "," || token == "|") { token = nextToken(text, index, line_num); }
        
        if      (isIdentifier(token) || token == "@") continue;
        else if (token == ";") { token = nextToken(text, index, line_num); break; }
        else assert(0, "',', '|', ';', '@' or an identifier expected. Did you forget ';' at the last of some rule? Line Number=" ~ to!string(line_num) );
    }
    
    return result;
}

// parse "@label identifier1 identifier2(name2)"
DSLRule parseRhs(ref string token, string lhs, string text, ref size_t index, ref size_t line_num) {
    DSLRule result; result.lhs = lhs;
    assert(token.length > 0, "Parsing error. END_OF_FILE is not expected.");
    // label
    if      (token == "@") {
        token = nextToken(text, index, line_num);
        if (token == "") { assert(0); }
        if (!isIdentifier(token)) { assert(0, "Identifier must come after '@'. Line Number=" ~ to!string(line_num) ); }
        result.label = token;
        token = nextToken(text, index, line_num);
    }
    else if (!isIdentifier(token)) { assert(0, "Identifier or an label is expected. Line Number=" ~ to!string(line_num) ); }
    
    while (isIdentifier(token)) {
        result.rhs ~= token;
        auto previous_line_num = line_num;
        token = nextToken(text, index, line_num);
        if (previous_line_num < line_num && isIdentifier(token)) {
            assert(0, "Line breaks in a single sequence before" ~ token ~ ". Did you forget ',' or '|' at the end? Line Number=" ~ to!string(line_num) );
        }
        
        // 'name'
        if (token == "(") {
            token = nextToken(text, index, line_num);
            if (!isIdentifier(token)) { assert(0, "Identifier must come after '('. index=" ~ to!string(index)); }
            result.name ~= token;
            token = nextToken(text, index, line_num);
            if (token != ")") { assert(0, "')' is expected. index = " ~ to!string(index)); }
            token = nextToken(text, index, line_num);
        }
        else { result.name ~= ""; }
    }
    
    return result;
}

string nextToken(string text, ref size_t index, ref size_t line_num) {
    string result;
    // skip spaces
    while (index < text.length && isWhite(text[index])) {
        if (text[index] == '\n') line_num++;
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

