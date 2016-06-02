DATADIR := /media/lmullen/data/chronicling-america/df
OUTDIR := /media/lmullen/data/chronicling-america/out
SCRIPTSDIR := .
LOGFILE := ./hecker-predictions2.log

PUBYEARS := $(shell find $(DATADIR) *.rds -type f | sort -t"-" -k4n,4)
PREDICTIONS := $(patsubst $(DATADIR)/%.rds, $(OUTDIR)/%.feather, $(PUBYEARS))

all : $(PREDICTIONS)

$(OUTDIR)/%.feather : $(DATADIR)/%.rds
	Rscript $(SCRIPTSDIR)/find-quotations.R \
	-i $^ -o $@ \
	-m $(SCRIPTSDIR)/prediction-model.rds -q $(SCRIPTSDIR)/bible.rda \
	-t 0.2 \
	-l $(LOGFILE) 


