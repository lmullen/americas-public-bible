#!/usr/bin/env bash

set -x
Rscript -e "packrat::snapshot()"
Rscript -e "packrat::bundle(file = 'packrat/bundles/verse-explorer-deploy.tar.gz', overwrite = TRUE)"
scp packrat/bundles/verse-explorer-deploy.tar.gz wat:/srv/shiny-server/
