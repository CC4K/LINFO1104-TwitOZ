# Args default values.
TWEETS_FOLDER="tweets"
IDX_N_GRAMS=2
CORR_WORD=0
FILES_DATABASE=0
AUTO_PREDICT=0
EXT=none

# Get the options specified by the user.
ifdef ext
    EXT=$(ext)
endif

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

# The entry point of the program.
ENTRY_POINT=main.ozf

ifeq ($(UNAME_S),Darwin)
	OZC = /Applications/Mozart2.app/Contents/Resources/bin/ozc
	OZENGINE = /Applications/Mozart2.app/Contents/Resources/bin/ozengine
else
	OZC = ozc
	OZENGINE = ozengine
endif

all : $(ENTRY_POINT)

# Compile all the files.
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


# Run the program with the specified arguments.
run: bin/$(ENTRY_POINT) 
	$(OZENGINE) bin/$(ENTRY_POINT) --folder $(TWEETS_FOLDER) --idx_n_grams $(IDX_N_GRAMS) --ext $(EXT) --corr_word $(CORR_WORD) --files_database $(FILES_DATABASE) --auto_predict $(AUTO_PREDICT)

# Clean the user historic.
clean_user_historic:
	rm -f user_historic/user_files/*.txt

# Help command
help:
	@echo \> 'make' : \ \ \ \ to compile all project files
	@echo \> 'make run' : to run the project with simple prediction function and no extension activated
	@echo \> The extension options are the following and must always be used as such : 'make run [options]':
	@echo \> 'idx_n_grams=[int]' : specifies the n-gram algorithm the program will use for predictions [must be >= 1]
	@echo \> 'corr_word=[int]' : \ \ \ \ \ activates word correction [1 = on \| 0 = off]
	@echo \> 'files_database=[int]' : activates the ability to add samples in database [1 = on \| 0 = off]
	@echo \> 'auto_predict=[int]' : \ \ activates auto-prediction and deactivates manual Predict button [1 = on \| 0 = off]
	@echo \> 'folder=[string]' : \ \ \ \ \ specifies database folder [default folder is "tweets"]
	@echo \> 'ext=all' : \ \ \ \ \ \ \ \ \ \ \ \ \ activates all extensions at once

# Clean the ./bin folder and all its content.
clean:
	rm -f bin/*.ozf
	rm -f bin/extensions/*.ozf
	rm -rf bin/extensions
	rm -rf bin