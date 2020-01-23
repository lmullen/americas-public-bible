# Build website
website :
	Rscript -e "rmarkdown::render_site('website')"

# deploy : website
# 	rsync --dry-run --delete --omit-dir-times \
# 		--checksum -avz \
# 		--itemize-changes \
# 		website/_site/* reclaim:~/www/americaspublicbible.org/ | egrep -v '^\.'

# Cleaning
clean :
	Rscript -e "rmarkdown::clean_site('website')"

.PHONY : website clean
