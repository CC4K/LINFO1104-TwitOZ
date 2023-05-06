# TwitOZ

## Description

TwitOZ is a text predictor project developped in the Oz programming language as part of the course LINFO1104.
The principle is to predict your next word thanks to a database of tweets (N-grams algorithm).
You can also try on your database ! You can do a lot of things with the extensions (Section #Extensions).

## Authors

Delsart Mathis and Kheirallah Cedric.

5 May 2023.

### Commands

To compile:
    make (automatically compile all the files .oz, including extensions's files.)

To clean:
    - make clean (clean the ./bin folder that contains all the binary files (.ozf files))
    - make clean_historic (clean the ./historic_user folder that contains all the historic of the user)
    - make clean_all (clean both)

To run:
    make run [option] (see option below in section 'Running the app')

To have help:
    make help (gives a message that contains all the information to compile and run the project)

### Running the app

Commands that the user can use:

    #Optionnals arguments:
        - idx_n_grams=int [If lower than 1 => Error + Exit] (Default: 2)
        - corr_word=int [1 = extension activated] (Default: 0 => not activated)
        - files_database=int [1 = extension activated] (Default: 0 => not activated)
        - auto_predict=int [1 = extension activated] (Default: 0 => not activated)
    
    #Obligatory arguments:
        - folder=string (Default: "tweets") [Not obligatory but, in this case, tou need to have the folder "tweets' present in your reposistory]

    #Special arguments:
        - ext=all [Activate all the extensions] (Default none => Do nothing)

#Examples :
    make run folder="my_folder" idx_n_grams=4 ext=all
    make run folder="my_folder corr_word=1
    ,...


## How to use

A detailed description of how each button works can be found in the "TwitOZ_Rapport.pdf" file.
There is a version in French and in English, so enjoy!

## Problems

If you are on Mac and you have some problems to compile, you need to remove the image at Line 54 in the src/extensions/interface_improved file.
In this case, you maybe can't see the colors of the buttons, or the image but we didn't find the source of the problem.