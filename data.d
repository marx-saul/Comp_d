import std.typecons;
import std.algorithm;

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

