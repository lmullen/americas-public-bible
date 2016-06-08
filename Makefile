# Build and deploy
build : data
	Rscript -e "rmarkdown::render_site()"

deploy : build
	rsync --progress --archive --checksum _site/* reclaim:~/public_html/americaspublicbible.org/

# Data
data : _data/quotations-clean.rds _data/bible.rda public-bible-quotations.csv.gz _data/labeled-features.feather _data/bible-verses.csv _data/wordcounts-by-year.csv _data/verses-by-year.rds

_data/wordcounts-by-year.csv :
	cp ../public-bible/data/$(@F) $@

_data/bible-verses.csv :
	cp ../public-bible/data/$(@F) $@

_data/quotations.csv :
	cp ../public-bible/data/$(@F) $@

_data/bible.rda :
	cp ../public-bible/bin/$(@F) $@

_data/quotations-clean.rds : _data/quotations.csv
	Rscript _scripts/clean-data.R

public-bible-quotations.csv.gz : _data/quotations-clean.rds
	Rscript _scripts/data-export.R
	gzip public-bible-quotations.csv

_data/labeled-features.feather :
	cp ../public-bible/data/$(@F) $@

_data/verses-by-year.rds : _data/quotations-clean.rds _data/wordcounts-by-year.csv
	Rscript _scripts/aggregate-data.R

# Cleaning
clean :
	Rscript -e "rmarkdown::clean_site()"

clobber : clean
	rm -rf _data/*
	rm -rf public-bible-quotations.csv.gz

.PHONY : build deploy data clean clobber
