# Build and deploy
build : data
	Rscript -e "rmarkdown::render_site()"

# Data
data : quotations-clean.csv public-bible-quotations.csv.gz

quotations-raw.csv :
	cp ../public-bible/data/quotations.csv quotations-raw.csv

quotations-clean.csv : quotations-raw.csv
	cp $^ $@

public-bible-quotations.csv.gz : quotations-clean.csv
	Rscript _scripts/data-export.R
	gzip public-bible-quotations.csv

# Cleaning
clean :
	Rscript -e "rmarkdown::clean_site()"

clobber : clean
	rm -rf quotations-clean.csv
	rm -rf quotations-raw.csv
	rm -rf public-bible-quotations.csv.gz
