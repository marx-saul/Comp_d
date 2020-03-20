//Staticly generate 
module comp_d.inject;

import comp_d.data, comp_d.tool, comp_d.LRTable, comp_d.parser, comp_d.dsl;

import std.range, std.array;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

enum bool IsSomeType(S, T) = is(S == T) || is(S == const T) || is(S == inout T) || is(S == inout const T);

unittest {
    alias grammar = defineGrammar!(`
        Expr:   Term Expr_,
                ;
        Expr_:  add Term Expr_,
                empty,
                ;
        Term:   Factor Term_,
                ;
        Term_:  mul Factor Term_,
                empty,
                ;
        Factor: digit,
                lPar Expr rPar,
                ;
    `);
    mixin("enum : Symbol { " ~ grammar.tokenDeclarations ~ "}");
    
    alias parser = Parser!(grammar.grammar_info, "SLR");
    static assert ( parser([digit, add, digit, mul, lPar, digit, add, digit, rPar]) );
    static assert (!parser([lPar, lPar, digit, add, digit, rPar, add, digit]) );
    writeln("## inject.d unittest 1");
}


template Parser(
    alias const GrammarInfo grammar_info, string type = "LALR",
    string module_name = __MODULE__, string file_name = __FILE__, size_t line = __LINE__
)
{
    mixin(table_info_injection_declaration);
    bool Parser(Range)(Range input)
        if ( isSymbolInput!Range )
    {
        return parse(grammar_info.grammar, table_info.table, input);
    }
}

static immutable string table_info_injection_declaration = q{
    // generate table
    import comp_d.SLR, comp_d.LALR, comp_d.LR, comp_d.WeakMinLR;
    
    static if      (type == "SLR") {
        static const table_info = SLRtableInfo(grammar_info);
    }
    else static if (type == "LALR") {
        static const table_info = LALRtableInfo(grammar_info);
    }
    else static if (type == "LR") {
        pragma(msg, "Canonical LR(1) table generation can require enormous resources and the resulting states and table sizes could be super large. If you REALLY want to use canonical LR(1) algorithm, use \"canonical-LR\" parameter instead of \"LR\".");
    }
    else static if (type.among!("canonical-LR", "canonical LR")) {
        static const table_info = LRtableInfo(grammar_info);
    }
    else static if (type.among!("minimal-LR", "weak-minimal-LR", "minimal LR", "weak minimal LR")) {
        static const table_info = weakMinimalLRtableInfo(grammar_info);
    }
    else
        static assert(0, "No parser type " ~ type);
    
    static if (table_info.is_conflict) pragma(msg, "Conflict occurs. " ~ module_name ~ " / " ~ file_name ~ " : " ~ to!string(line));
};
