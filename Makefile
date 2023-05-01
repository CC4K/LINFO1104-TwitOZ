TWEETS_FOLDER="tweets"
UNAME_S := $(shell uname -s)
ENTRY_POINT=main.ozf

ifeq ($(UNAME_S),Darwin)
	OZC = /Applications/Mozart2.app/Contents/Resources/bin/ozc
	OZENGINE = /Applications/Mozart2.app/Contents/Resources/bin/ozengine
else
	OZC = ozc
	OZENGINE = ozengine
endif

all : $(ENTRY_POINT)

main.ozf :
	if [ ! -d "bin" ]; then mkdir bin; fi
	$(OZC) -c src/variables.oz -o bin/variables.ozf
	$(OZC) -c src/function.oz -o bin/function.ozf
	$(OZC) -c src/interface.oz -o bin/interface.ozf
	$(OZC) -c src/parser.oz -o bin/parser.ozf
	$(OZC) -c src/tree.oz -o bin/tree.ozf
	$(OZC) -c src/reader.oz -o bin/reader.ozf
	$(OZC) -c src/extensions.oz -o bin/extensions.ozf

	$(OZC) -c main.oz -o bin/main.ozf

%.ozf: %.oz
	$(OZC) -c $< -o "$@"

run: bin/$(ENTRY_POINT) 
	$(OZENGINE) bin/$(ENTRY_POINT) --folder $(TWEETS_FOLDER)

clean :
	rm -f bin/*.ozf
	rm -rf bin