# Build and deploy
build : data
	Rscript -e "rmarkdown::render_site()"

deploy : build
	rsync --progress --archive --checksum _site/* reclaim:~/public_html/americaspublicbible.org/

# Data
data : _data/quotations-clean.csv public-bible-quotations.csv.gz _data/labeled-features.feather

_data/quotations-raw.csv :
	cp ../public-bible/data/quotations.csv $@

_data/quotations-clean.csv : _data/quotations-raw.csv
	cp $^ $@

public-bible-quotations.csv.gz : _data/quotations-clean.csv
	Rscript _scripts/data-export.R
	gzip public-bible-quotations.csv

_data/labeled-features.feather :
	cp ../public-bible/data/labeled-features.feather $@

# Cleaning
clean :
	Rscript -e "rmarkdown::clean_site()"

clobber : clean
	rm -rf quotations-clean.csv
	rm -rf quotations-raw.csv
	rm -rf public-bible-quotations.csv.gz

.PHONY : build deploy data clean clobber

