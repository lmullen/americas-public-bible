preview :
	@echo "Serving the preview site ..."
	hugo serve --buildDrafts --buildFuture --disableFastRender --port=52643

build : 
	@echo "\nBuilding the website ..."
	hugo --cleanDestinationDir --minify
	@echo "Website finished building."

deploy : build
	@echo "\nDeploying the website ..."
	rsync --delete --omit-dir-times \
	  --exclude '.well-known/' \
	  --exclude '.htaccess' \
		--checksum -avz \
		--itemize-changes \
		public/ reclaim:~/dev.americaspublicbible.org/ | egrep -v '^\.'
