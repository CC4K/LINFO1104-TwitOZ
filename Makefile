TWEETS_FOLDER="tweets"
UNAME_S := $(shell uname -s)
ENTRY_POINT=bin/main.ozf

ifeq ($(UNAME_S),Darwin)
	OZC = /Applications/Mozart2.app/Contents/Resources/bin/ozc
	OZENGINE = /Applications/Mozart2.app/Contents/Resources/bin/ozengine
else
	OZC = ozc
	OZENGINE = ozengine
endif

all : $(ENTRY_POINT)

main :
	if [ ! -d "bin" ]; then mkdir bin; fi
	$(OZC) -c src/Variables.oz -o bin/Variables.ozf
	$(OZC) -c src/Function.oz -o bin/function.ozf
	$(OZC) -c src/Interface.oz -o bin/interface.ozf
	$(OZC) -c src/Parser.oz -o bin/parser.ozf
	$(OZC) -c src/Tree.oz -o bin/tree.ozf
	$(OZC) -c src/Reader.oz -o bin/reader.ozf
	$(OZC) -c src/Extensions.oz -o bin/extensions.ozf

	$(OZC) -c main.oz -o bin/main.ozf

%.ozf: %.oz
	$(OZC) -c $< -o "$@"

run: $(ENTRY_POINT) 
	$(OZENGINE) $(ENTRY_POINT) --folder $(TWEETS_FOLDER)

clean :
	rm -f bin/*.ozf
	rm -rf bin