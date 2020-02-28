DC=dmd

DSCRIPTS := $(basename $(wildcard *.d))

all: $(DSCRIPTS)

clean:
	$(RM) *.o
	$(RM) $(DSCRIPTS)

%: %.d
	$(DC) $*.d -I=../source -L=-L../
