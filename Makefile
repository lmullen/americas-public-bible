# Quotation finder | America's Public Bibleo

# This Makefile defines how to create the various pieces that go into the
# quotation finder.

# Define variables
# ----------------------------------------------------------------------
newspaper_batches := /media/data/newspaper-batches

# Local tasks
# ----------------------------------------------------------------------
all : bin/bible-payload.rda

# The vectorizer and Bible document-term matrix used for finding quotations
bin/bible-payload.rda :
	Rscript --vanilla ./scripts/bible-payload.R

# Cleaning
# ----------------------------------------------------------------------
clean :
	rm -f temp/*
	rm -f logs/*

clobber : clean
	rm -f bin/bible-payload.rda

# Tasks to move files back and forth to the Argo cluster
# ----------------------------------------------------------------------
argo-put : argo-put-data argo-put-bin

argo-get : argo-get-results

argo-put-data :
	rsync --archive -vv --delete \
	$(newspaper_batches)/*.csv \
	argo:/scratch/lmullen/newspaper-batches \
	2>&1 | tee logs/argo-put-data-$(shell date --iso-8601=seconds).log

argo-put-bin :
	ls $(newspaper_batches)/*.csv -1 | \
			xargs -n 1 basename | \
			sed -e 's/.csv//' > \
			./bin/newspaper-batches.txt
	rsync --archive -vv --delete \
		./bin/ \
		argo:~/public-bible/bin \
		2>&1 | tee logs/argo-put-bin-$(shell date --iso-8601=seconds).log

argo-get-results :
	rsync --archive -vv --delete \
	argo:/scratch/lmullen/argo-out \
	/media/data/ \
	2>&1 | tee logs/argo-get-results-$(shell date --iso-8601=seconds).log

# Tasks to test various scripts
# ----------------------------------------------------------------------
test-quotation-finder : temp/test-ncnp-quotations.fst temp/test-chronam-quotations.fst

temp/test-ncnp-quotations.fst : data/sample/ncnp-batch-00650.fst
	time Rscript bin/find-potential-quotations.R \
		--tokens=2 --tfidf=0.5 --verbose=2 --bible=bin/bible-payload.rda \
		$^ -o $@

temp/test-chronam-quotations.fst : data/sample/chronam-batch-000023.fst
	time Rscript bin/find-potential-quotations.R \
		--tokens=5 --tfidf=0.5 --verbose=2 --bible=bin/bible-payload.rda \
		$^ -o $@
