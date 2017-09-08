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

# Define `all` task
# ----------------------------------------------------------------------
all : data/labeled-features.feather data/newspaper-metadata.rda bin/prediction-model.rds

# Also tasks to clean and clobber
clobber-all : clobber-metadata clobber-features

# Tasks related to feature extraction
# ----------------------------------------------------------------------
# Run the feature extraction script on each publication in the sample
PUBLICATIONS := $(shell find ./data/sample -mindepth 1 -maxdepth 1 -type d)
FEATURES := $(addsuffix /features.feather, $(PUBLICATIONS))

bin/bible.rda :
	Rscript --vanilla ./scripts/create-bible-dtm.R

data/sample/%.feather : bin/bible.rda
	./scripts/extract-features.R $(patsubst %/features.feather,%, $@) $@

data/all-features.feather : $(FEATURES)
	./scripts/collect-features.R

data/matches-for-model-training.csv : data/all-features.feather
	./scripts/create-supervised-learning-data.R

data/labeled-features.feather : data/matches-for-model-training.csv
	./scripts/download-labeled-data.R

bin/prediction-model.rds : bin/bible.rda data/labeled-features.feather
	./scripts/train-model.R

clobber-features :
	rm -rf $(FEATURES)
	rm -rf data/all-features.feather
	rm -rf data/labeled-data.csv
	rm -rf bin/bible.rda
	rm -rf data/labeled-features.feather
	rm -rf data/matches-for-model-training.csv
	rm -rf bin/prediction-model.rds

# Download Chronicling America data
# ----------------------------------------------------------------------
download :
	wget --continue --mirror --no-parent -nv -b \
		--accept="*.tar.bz2" \
		--directory-prefix=$(chronicling_dir) $(chronicling_url) \
		--output-file=logs/download-chronam-batches-$(shell date --iso-8601=seconds).log

# Tasks to send files to Argo cluster
# ----------------------------------------------------------------------
argo-put : argo-put-data argo-put-bin

argo-get : argo-get-results

argo-put-data :
	rsync --archive -vv --delete \
	$(chronicling_batches)/ \
	argo:~/public-bible/chronam-batches \
	2>&1 | tee logs/argo-put-data-$(shell date --iso-8601=seconds).log

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
	rsync --archive -vv --delete \
	argo:~/public-bible/argo-out \
	/media/data/public-bible/ \
	2>&1 | tee logs/argo-get-results-$(shell date --iso-8601=seconds).log
