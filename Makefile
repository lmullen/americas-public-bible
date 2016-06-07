# Build and deploy
build : data
	Rscript -e "rmarkdown::render_site()"

deploy : build
	rsync --progress --archive --checksum _site/* reclaim:~/public_html/americaspublicbible.org/

# Data
data : _data/quotations-clean.csv public-bible-quotations.csv.gz _data/labeled-features.feather _data/bible-verses.csv _data/wordcounts-by-year.csv

_data/wordcounts-by-year.csv :
	cp ../public-bible/data/$(@F) $@

_data/bible-verses.csv :
	cp ../public-bible/data/$(@F) $@

_data/quotations.csv :
	cp ../public-bible/data/$(@F) $@

_data/quotations-clean.csv : _data/quotations.csv
	Rscript _scripts/clean-data.R

public-bible-quotations.csv.gz : _data/quotations-clean.csv
	Rscript _scripts/data-export.R
	gzip public-bible-quotations.csv

_data/labeled-features.feather :
	cp ../public-bible/data/$(@F) $@

# Cleaning
clean :
	Rscript -e "rmarkdown::clean_site()"

clobber : clean
	rm -rf _data/*
	rm -rf public-bible-quotations.csv.gz

.PHONY : build deploy data clean clobber

