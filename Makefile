# Build and deploy
build :
	Rscript -e "rmarkdown::render_site()"

# Cleaning
clean :
	Rscript -e "rmarkdown::clean_site()"

clobber : clean
	rm -rf _data/*
	rm -rf *_files/*
	rm -rf *_cache/*

.PHONY : build clean clobber
