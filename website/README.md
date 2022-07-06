# Building and deploying the website

To build this website, you will need to install Hugo and NodeJS. (These are build-time dependencies; they are not required at run time.) You can install these on MacOS with [Homebrew](https://brew.sh) as follows:

```
brew install hugo
brew install node
```

For other platforms, consult the documentation for those projects.

To build the JavaScript on the site, you will need to install the dependencies specified in `package.json`.

```
npm install 
```

You can then build the site locally using the `Makefile`.

```
make preview
```

The site is deployed via rsync. 

```
make deploy
```

Modify the `deploy` task in the Makefile if necessary to point to the server and directory you wish to deploy the site to. Generally speaking, you will want to name the server as an alias in your SSH config.

