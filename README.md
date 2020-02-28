# Comp_d
An SLR(1), LALR(1), LR(1) parser generator that can be calculated at the compile time (CTFE).

## To do:
DSL for defining a grammar and the reduce action.

User-defined conflict resolving rules.

Parser class for directly writing reduce actions. (comp_d.parser.Parser template is for small grammars)

Allow various symbols to be regarded as end_ of _ file_ to make it easy to break a parser into small pieces when parsing a large grammar.

Make an interface for LRTable.

Implement minimal LR(1) algorithm (IELR(1) if vigorous enough).

### Others
Any improvement advices are welcome.
