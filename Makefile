OBJS = tool.o SLR.o LR.o LALR.o
DFLAGS  = -wi -unittest

comp: $(OBJS) main.d data.d
	dmd -of="comp" $(OBJS) main.d data.d $(DFLAGS)

tool.o: tool.d
	dmd -c tool.d $(DFLAGS)

SLR.o: SLR.d
	dmd -c SLR.d $(DFLAGS)

LR.o: LR.d
	dmd -c LR.d $(DFLAGS)
	
LALR.o: LALR.d
	dmd -c LALR.d $(DFLAGS)

BNF.o: BNF.d
	dmd -c BNF.d $(DFLAGS)
	
