# Args
TWEETS_FOLDER="tweets"
IDX_N_GRAMS=2
CORR_WORD=false
FILES_DATABASE=false
AUTO_PREDICT=false

# Récupération des options spécifiées par l'utilisateur
ifdef folder
    TWEETS_FOLDER=$(folder)
endif

ifdef idx_n_grams
    IDX_N_GRAMS=$(idx_n_grams)
endif

ifdef corr_word
    CORR_WORD=$(corr_word)
endif

ifdef files_database
    FILES_DATABASE=$(files_database)
endif

ifdef auto_predict
    AUTO_PREDICT=$(auto_predict)
endif

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

	if [ ! -d "bin/extensions" ]; then mkdir bin/extensions; fi
	$(OZC) -c src/extensions/automatic_prediction.oz -o bin/extensions/automatic_prediction.ozf
	$(OZC) -c src/extensions/interface_improved.oz -o bin/extensions/interface_improved.ozf
	$(OZC) -c src/extensions/historic_user.oz -o bin/extensions/historic_user.ozf
	$(OZC) -c src/extensions/n_Grams.oz -o bin/extensions/n_grams.ozf
	$(OZC) -c src/extensions/predict_All.oz -o bin/extensions/predict_All.ozf
	$(OZC) -c src/extensions/correction_prediction.oz -o bin/extensions/correction_prediction.ozf

	$(OZC) -c main.oz -o bin/main.ozf

%.ozf: %.oz
	$(OZC) -c $< -o "$@"

run: bin/$(ENTRY_POINT) 
	$(OZENGINE) bin/$(ENTRY_POINT) --folder $(TWEETS_FOLDER) --idx_n_grams $(IDX_N_GRAMS) --corr_word $(CORR_WORD) --files_database $(FILES_DATABASE) --auto_predict $(AUTO_PREDICT)

clean_user_historic:
	rm -f user_historic/user_files/*.txt

clean:
	rm -f bin/*.ozf
	rm -f bin/extensions/*.ozf
	rm -rf bin/extensions
	rm -rf bin