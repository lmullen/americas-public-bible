chronicling_dir := /Volumes/RESEARCH/chronicling-america
chronicling_ocr := $(chronicling_dir)/ocr
chronicling_url := http://chroniclingamerica.loc.gov/data/ocr/

chronicling_tars = $(wildcard $(chronicling_dir)/chroniclingamerica.loc.gov/data/ocr/*.tar.bz2)
chronicling_untars = $(addsuffix .EXTRACTED, $(chronicling_tars))

all : extract

download :
	wget --continue --progress=bar --mirror --no-parent --background \
		--directory-prefix=$(chronicling_dir) $(chronicling_url)

%.tar.bz2.EXTRACTED : %.tar.bz2
	tar --overwrite -xf $^ -C $(chronicling_ocr) --wildcards '*.txt' \
		&& touch $@

.PHONY : extract
extract : $(chronicling_untars)
