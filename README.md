# TwitOZ

## Description

TwitOZ is a text predictor project developped in the Oz programming language as part of the course LINFO1104.
The principle is to predict your next word thanks to a database of tweets (N-Grams algorithm).
You can also try on your database ! You can do a lot of things with the extensions (Section #Extensions).

## Authors

Delsart Mathis and Kheirallah Cedric.

5 May 2023.

### Compiling the project

You just need to do the command make and that will automatically compile all the files .oz, including extensions's files.

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
The pdf has been written in French but you can easily translate it if you need.