SHELL=/usr/bin/bash

DATADIR := /data/chronicling-america/df
OUTDIR := /data/chronicling-america/out
SCRIPTSDIR := /data/chronicling-america/scripts
LOGFILE := /data/chronicling-america/logs/vrc-predictions.log

PUBYEARS := $(shell find $(DATADIR) *.rds -type f | sort -t"-" -k3n,3)
PREDICTIONS := $(patsubst $(DATADIR)/%.rds, $(OUTDIR)/%.feather, $(PUBYEARS))

all : $(PREDICTIONS)

$(OUTDIR)/%.feather : $(DATADIR)/%.rds
	Rscript --vanilla $(SCRIPTSDIR)/find-quotations.R \
	-i $^ -o $@ \
	-m $(SCRIPTSDIR)/prediction-model.rds -q $(SCRIPTSDIR)/bible.rda \
	-t 0.2 \
	-l $(LOGFILE)


