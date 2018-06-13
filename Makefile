# Quotation finder | America's Public Bibleo

# This Makefile defines how to create the various pieces that go into the
# quotation finder.

# Define variables
# ----------------------------------------------------------------------
newspaper_batches := /media/data/newspaper-batches

# Tasks to move files back and forth to the Argo cluster
# ----------------------------------------------------------------------
argo-put : argo-put-data argo-put-bin

argo-get : argo-get-results

argo-put-data :
	rsync --archive -vv --delete \
	$(newspaper_batches)/ \
	argo:~/newspaper-batches \
	2>&1 | tee logs/argo-put-data-$(shell date --iso-8601=seconds).log

argo-put-bin :
	ls $(newspaper_batches)/*.fst -1 | \
			xargs -n 1 basename | \
			sed -e 's/.fst//' > \
			bin/newspaper-batches.txt
	rsync --archive -vv --delete \
		./bin/ \
		argo:~/public-bible/bin \
		2>&1 | tee logs/argo-put-bin-$(shell date --iso-8601=seconds).log

argo-get-results :
	rsync --archive -vv --exclude 'logs' --delete \
	argo:~/public-bible/argo-out \
	/media/data/argo-out/ \
	2>&1 | tee logs/argo-get-results-$(shell date --iso-8601=seconds).log
