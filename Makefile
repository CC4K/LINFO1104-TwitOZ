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

# J'ai ajouté cette partie
main.ozf : main.oz reader.oz parser.oz tree.oz
	$(OZC) -c parser.oz -o parser.ozf
	$(OZC) -c tree.oz -o tree.ozf
	$(OZC) -c reader.oz -o reader.ozf
	$(OZC) -c main.oz -o main.ozf

%.ozf: %.oz
	$(OZC) -c $< -o "$@"

run: $(ENTRY_POINT) 
	$(OZENGINE) $(ENTRY_POINT) --folder $(TWEETS_FOLDER)

clean :
	rm -f *.ozf
