## Authors
Delsart Mathis and .??. Cedric.
5 May 2023.

## TwitOZ

TwitOZ is a text predictor project developped in the Oz programming language as part of the course LINFO1104.
The principle is to predict your next word thanks to a database of tweets (N-Grams algorithm).
You can also try on your database ! You can do a lot of things with the extensions (Section #Extensions).

### Compiling the project

You just need to do the command make and that will automatically compile all the files .oz, including extensions's files.

### Running the app

Les commandes que peut utiliser l'utilisateur :

    #Arguments optionnels :
        - idx_n_grams=int [Si inférieur à 1 => Message d'erreur + Exit] (par défaut 2)
        - corr_word=int [1 = extension activée] (par défaut 0 => pas activé)
        - files_database=int [1 = extension activée] (par défaut 0 => pas activé)
        - auto_predict=int [1 = extension activée] (par défaut 0 => pas activé)
    
    #Arguments obligatoire :
        - folder=string (par défaut "tweets") [Pas obligatoire en soit mais il faut alors impérativement avoir le fichier "tweets" présent dans son répértoire]

    #Spécial argument :
        - ext=all [active toutes les extensions] (par défaut none)

#Exemples :
    make run folder="my_folder" idx_n_grams=4 ext=all
    make run folder="my_folder corr_word=1
    ,...


## How to use

Here is a detailed description of how each button works.

    ### Predict

    The predict button is used to predict the next word based on a database.
    If there is no word, the programm will tell you.
    As same as if you try to predict a word after less than N words before.
    Example:
        If you asks a tri-grammes and you write "i have" => 'Predict button pressed'
        The programm will tell you that you need to write at least three words.

    ### Correct a word

    ### Load file from computer

    ### Save on computer (as a file)

    ### Load file into database

    ### Save in database (input text)

    ### Clean history