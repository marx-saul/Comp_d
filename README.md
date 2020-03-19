# Comp_d
An SLR(1), LALR(1), LR(1) parser generator that can be calculated at the compile time (CTFE).

[Usage](https://github.com/marx-saul/Comp_d/wiki)

## To do:
User-defined conflict resolving rules. (LRTable.d)

Make an interface for LRTable and implement LRTable by AATree(current one is 2-dim array). (LRTable.d)

Implement Pager's minimal LR(1) algorithm (strong-compatibility) (and IELR(1) if vigorous enough).

## Others
Any improvement suggests/advices/requests are welcome.

### History
v0.2.0 Pager's minimal LR(1) algorithm (weak-compatibility) implemented.

v0.1.0 First publish.
