# Quotation Finder | America's Public Bible


## Overview

[America's Public Bible](http://americaspublicbible.org) is a project to detect the biblical quotations in the [Chronicling America](http://chroniclingamerica.loc.gov/) and [19th Century U.S. Newspapers](https://www.gale.com/c/19th-century-us-newspapers) datasets of historical newspapers, then to interpret and visualize the patterns.  

This repository contains the code that extracts the features, trains the models, and finds the quotations. 

- The `bin` directory contains R scripts that are intended to be run on newspaper batches, as well as the shell scripts to run them on the HPC cluster.
- The `model` directory contains code and data to train the prediction model.

## Repository history

This repository has undergone a number of changes. The initial code for the prototype version of the site was created in 2016. That code can be found in [this tag](https://github.com/public-bible/quotation-finder/releases/tag/initial-doi-version) on the repository. Much of that code has been superseded, and what remains in the `master` branch is located in the `prototype/` directory. 
