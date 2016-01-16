chronicling_dir := /Volumes/RESEARCH/chronicling-america
chronicling_ocr := http://chroniclingamerica.loc.gov/data/ocr/

download :
	wget --continue --progress=bar --mirror --no-parent --background \
		--directory-prefix=$(chronicling_dir) $(chronicling_ocr)



