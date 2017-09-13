# This Makefile builds the project from almost scratch. The main aims of this
# repository are to reproducibly create the model files for running on the
# Argo cluster, and to reproducibly create the data files that will be shared
# with the website repository. There are also notebooks to experiment with the
# analysis.
#
# Tasks that involve downloading large amounts of data from Chronicling
# America have to be run deliberately. In general, these are the order that
# steps should be taken. Most of these will be run by creating the `all` task.
#
# Data download and extraction
# ----------------------------------------------------------------------
# 1. Download data from Chronicling America: run with `make download`
# 2. Transfer the data to Argo: run with `make argo-put-data`
# 3. Sync the Argo-specific scripts and jobs: `make argo-put-bin`
# 4. Run the `bin/convert-batches.sh` array job on Argo.
# 5. Move the results back from Argo with `make argo-get-results`
# 6. Run the `bin/wordcount-batches.sh` array job on Argo
# 7. Aggregate the word counts with `make data/chronam-wordcounts.feather`
# 8. Download the ChronAm metadata with `make
#
# Creating the predictive model
# ----------------------------------------------------------------------
# n. Create Bible DTM and other objects necessary for feature extraction
# n. Run feature extraction on sample data
# n. Sample the potential matches for labeling
# n. Label the sample data in Google Sheets
# n. Download labeled data and create the version for model training
# n. Train the model
# n. Download the newspaper metadata
# n. Count the words in the newspaper pages
#
# Most of these pieces are run from scripts as detailed below. R Markdown
# notebooks are not recompiled by this Makefile, because they are a snapshot
# of the project at a given moment, and not part of the reproducible workflow.

# Define variables
# ----------------------------------------------------------------------
# Variables for downloading Chronicling America
chronicling_url := http://chroniclingamerica.loc.gov/data/ocr/
chronicling_dir := /media/data/public-bible/chronicling-america
chronicling_batches := $(chronicling_dir)/chroniclingamerica.loc.gov/data/ocr
news19c_issues := /media/data/newspapers-19c/NCNP

# Define `all` task
# ----------------------------------------------------------------------
all : data/chronam-wordcounts.feather data/chronam-metadata.rds

# Also tasks to clean and clobber
clean :
	rm -f data/chronam-wordcounts.feather

clobber : clean
	rm -f data/chronam-metadata.rds

# Tasks relating to calculations on the data
# ----------------------------------------------------------------------
data/chronam-wordcounts.feather : $(wildcard /media/data/public-bible/argo-out/chronam-wordcounts/*.feather)
	Rscript --vanilla ./scripts/aggregate-wordcounts.R

# Download Chronicling America data
# ----------------------------------------------------------------------
download :
	wget --continue --mirror --no-parent -nv -b \
		--accept="*.tar.bz2" \
		--directory-prefix=$(chronicling_dir) $(chronicling_url) \
		--output-file=logs/download-chronam-batches-$(shell date --iso-8601=seconds).log

data/chronam-metadata.rds :
	Rscript --vanilla scripts/download-chronam-metadata.R

# Tasks to send files to Argo cluster
# ----------------------------------------------------------------------
argo-put : argo-put-chronam-data argo-put-news19c-data argo-put-bin

argo-get : argo-get-results

argo-put-chronam-data :
	rsync --archive -vv --delete \
	$(chronicling_batches)/ \
	argo:~/public-bible/chronam-batches \
	2>&1 | tee logs/argo-put-chronam-data-$(shell date --iso-8601=seconds).log

argo-put-news19c-data :
	rsync --archive -vv --delete \
	$(news19c_issues)/ \
	argo:~/public-bible/news19c-issues \
	2>&1 | tee logs/argo-put-news19c-data-$(shell date --iso-8601=seconds).log

argo-put-bin :
	# Make sure the list of batches is up to date
	ls $(chronicling_batches)/*.tar.bz2 -1 | \
		xargs -n 1 basename | \
		sed -e 's/.tar.bz2//' > \
		bin/chronam-batch-list.txt
	rsync --archive -vv --delete \
	./bin/ \
	argo:~/public-bible/bin \
	2>&1 | tee logs/argo-put-bin-$(shell date --iso-8601=seconds).log

argo-get-results :
	rsync --archive -vv --exclude 'logs' --delete \
	argo:~/public-bible/argo-out \
	/media/data/public-bible/ \
	2>&1 | tee logs/argo-get-results-$(shell date --iso-8601=seconds).log
