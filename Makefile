HERE := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
there := .
GENERATED := $(there)/manifest.json $(there)/mktitle.sh.js 

.PHONY: mktitle
mktitle: $(GENERATED)
$(GENERATED) : $(HERE)/mktitle.sh
	$(HERE)/mktitle.sh

