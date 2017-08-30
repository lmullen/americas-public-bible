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
# 1. Download data from Chronicling America (not part of `make all`)
# 2. Extract data
# 3. Generate sample from the data and copy to local directory
# 4. Create Bible DTM and other objects necessary for feature extraction
# 5. Run feature extraction on sample data
# 6. Sample the potential matches for labeling
# 7. Label the sample data in Google Sheets
# 8. Download labeled data and create the version for model training
# 9. Train the model
# 10. Download the newspaper metadata
# 11. Count the words in the newspaper pages
#
# Most of these pieces are run from scripts as detailed below. R Markdown
# notebooks are not recompiled by this Makefile, because they are a snapshot
# of the project at a given moment, and not part of the reproducible workflow.

# Define variables
# -----------------------------------------------------------------------------
# Variables for downloading Chronicling America
chronicling_url := http://chroniclingamerica.loc.gov/data/ocr/
chronicling_dir := /media/data/chronicling-america
chronicling_batches := $(chronicling_dir)/chroniclingamerica.loc.gov/data/ocr
# chronicling_ocr := $(chronicling_dir)/ocr
# chronicling_tars = $(wildcard $(chronicling_dir)/chroniclingamerica.loc.gov/data/ocr/*.tar.bz2)
# chronicling_untars = $(addsuffix .EXTRACTED, $(chronicling_tars))


# Define `all` task
# -----------------------------------------------------------------------------
all : data/labeled-features.feather data/newspaper-metadata.rda data/newspaper-wordcounts.csv bin/prediction-model.rds

# Also tasks to clean and clobber
clobber-all : clobber-metadata clobber-features clobber-wordcounts

# Tasks to download newspaper metadata
# -----------------------------------------------------------------------------
LCCN := $(shell cat data/all-lccn.txt)
LCCN := $(addsuffix .json, $(LCCN))
LCCN := $(addprefix data/newspapers/, $(LCCN))

data/newspaper-metadata.rda : data/all-lccn.txt $(LCCN)
	./scripts/gather-newspaper-metadata.R

data/all-lccn.txt :
	./scripts/download-newspaper-list.R

data/newspapers/%.json : data/all-lccn.txt
	curl http://chroniclingamerica.loc.gov/lccn/$*.json > $@ && sleep 0.5

clobber-metadata :
	rm -rf data/newspaper-metadata.rda
	rm -rf data/all-lccn.txt

# Tasks related to feature extraction
# -----------------------------------------------------------------------------
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

# Tasks to create word counts of each page
# ----------------------------------------------------------------------------
PUBLICATION_MONTHS := $(shell find $(chronicling_ocr) -mindepth 3 -maxdepth 3 -type d)
WORDCOUNTS := $(addsuffix /wordcounts.csv, $(PUBLICATION_MONTHS))

data/newspaper-wordcounts.csv : # $(WORDCOUNTS)
	echo "wordcount,page" > $@
	find $(chronicling_ocr) -iname *wordcounts.csv -type f -exec cat {} >> $@ \;

%/wordcounts.csv : %
	./scripts/wordcounter.sh $^

clobber-wordcounts :
	rm -rf data/newspaper-wordcounts.csv
	rm -rf $(WORDCOUNTS)

# Tasks to create a sample dataset
# ----------------------------------------------------------------------------
sample-data : temp/sample-files.txt
	./scripts/copy-sample-files.sh

temp/sample-files.txt : temp/pub-years.txt
	Rscript --vanilla ./scripts/generate-sample-pages.R

temp/pub-years.txt :
	./scripts/generate-publication-years.sh > $@

# Download Chronicling America data
# -----------------------------------------------------------------------------
download :
	wget --continue --mirror --no-parent \
		--directory-prefix=$(chronicling_dir) $(chronicling_url) \
		--output-file=logs/download-chronam-batches-$(shell date --iso-8601=seconds).log

# Tasks to send files to Argo cluster
# -----------------------------------------------------------------------------
argo-put-data :
	rsync --archive -vv --delete $(chronicling_batches)/ argo:~/chronam-batches 2>&1 > logs/argo-put-$(shell date --iso-8601=seconds).log &

# get-argo :
# 	rsync --archive -P --ignore-exisiting vrc:/data/chronicling-america/out/* /media/lmullen/data/chronicling-america/out

.PHONY : clean clobber-metadata clobber-features clobber-wordcounts clobber-all extract download argo-put-data argo-get-results
