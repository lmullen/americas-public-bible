
NOTEBOOKS := $(patsubst %.Rmd, %.md, $(wildcard *.Rmd))
NOTEBOOK_DIR := ~/acad/notebook2

# Variables for downloading Chronicling America
chronicling_dir := /Volumes/RESEARCH/chronicling-america
chronicling_ocr := $(chronicling_dir)/ocr
chronicling_url := http://chroniclingamerica.loc.gov/data/ocr/
chronicling_tars = $(wildcard $(chronicling_dir)/chroniclingamerica.loc.gov/data/ocr/*.tar.bz2)
chronicling_untars = $(addsuffix .EXTRACTED, $(chronicling_tars))

# Tasks to build notebooks
all : $(NOTEBOOKS) temp/pub-years.txt

%.md : %.Rmd $(INCLUDES)
	R --slave -e "set.seed(100); rmarkdown::render('$(<F)')"

clean :
	rm -rf $(NOTEBOOKS)
	rm -rf *_files

# Tasks to put notebooks in wiki
wiki : $(NOTEBOOKS)
	cp $(NOTEBOOKS) $(NOTEBOOK_DIR)/_note/
	mkdir -p $(NOTEBOOK_DIR)/figures/$*/
	cp -r *_files $(NOTEBOOK_DIR)/figures/

# Tasks to extract features
temp/bible.rda :
	Rscript --vanilla ./scripts/create-bible-dtm.R

# Tasks to create a sample dataset
sample-data : temp/sample-files.txt
	./scripts/copy-sample-files.sh

temp/sample-files.txt : temp/pub-years.txt
	Rscript --vanilla ./scripts/generate-sample-pages.R

temp/pub-years.txt :
	./scripts/generate-publication-years.sh > $@

# Tasks to download and extract Chronicling America data
# These are not run automatically
extract : $(chronicling_untars)

%.tar.bz2.EXTRACTED : %.tar.bz2
	tar --overwrite -xf $^ -C $(chronicling_ocr) --wildcards '*.txt' \
		&& touch $@

download :
	wget --continue --progress=bar --mirror --no-parent \
		--directory-prefix=$(chronicling_dir) $(chronicling_url)

.PHONY : clean clobber extract download
