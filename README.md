# TwitOZ

## Description

TwitOZ is a text predictor project developped in the Oz programming language as part of the course LINFO1104.
The principle is to predict the user's next word based on a database of tweets (N-grams algorithm).
The user can also try the prediction on their own database with the help of various extensions (Section #Extensions).

This project was completed in two weeks.

## Authors

Mathis Delsart and Cedric Kheirallah.

5 May 2023.

### Commands

To compile:
    make (automatically compile all the files .oz, including extension files)

To clean:
    - make clean (removes all binary files (.ozf files) from the ./bin folder)
    - make clean_historic (removes all historic user data from the ./historic_user folder)
    - make clean_all (removes both binary files and historic user data)

To run:
    make run [option] (see option below in section 'Running the app')

To have help:
    make help (provides information on how to compile and run the project)

### Running the app

The following commands are available to the user:

    #Optionnals arguments:
        - idx_n_grams=int [If lower than 1 => Error + Exit] (Default: 2)
        - corr_word=int [1 = extension activated] (Default: 0 => not activated)
        - files_database=int [1 = extension activated] (Default: 0 => not activated)
        - auto_predict=int [1 = extension activated] (Default: 0 => not activated)
    
    #Mandatory arguments:
        - folder=string (Default: "tweets") [Not really mandatory but, in this case, tou need to have the folder "tweets' present in your reposistory]

    #Special arguments:
        - ext=string [all = activate all the extensions] (Default none => do nothing)

#Examples 1:
    make run folder="my_folder" idx_n_grams=4 ext=all
    
#Examples 2:
    make run folder="my_folder corr_word=1
,...

## How to use

A detailed description of how each button works can be found in the "TwitOZ_Rapport.pdf" file.
Unfortunately, this file is only available in French, but we have provided a summary of the app's features in English below.

## Implementation

    Here are some things to know about the implementation of the project.
    If you are not a developer and just want to try the project, feel free to skip this section.

    Tree structure:

        The tree structure is created in two steps. First, we create the tree with lists of words and their frequencies (e.g., ['Word1'#Freq1 'Word2'#Freq2 ...]). Then, we traverse the tree and update the values to create a subtree with frequencies as keys and lists of words as values. This approach makes it easier to insert values and avoids the need to delete nodes from the subtrees, which would be more difficult with a single-step implementation.

    Auto-prediction:

        The automatic prediction is implemented using a thread as a background process. This is a recursive procedure that runs indefinitely, repeating itself every 0.5 seconds. When the user presses the button to correct a word, the thread is stopped for 4 seconds (to allow the result to be displayed on the screen). This is done using a Port structure.

    User's historic:

        The "user_history" folder contains:

            - The "user_files" folder
                => Folder that contains all the historic .txt files of the user.
                This allows for analyzing and parsing the data to use them for the next prediction.

            - The last_prediction.txt file
                => This allows for storing the last prediction to compare with the new one. It updates the prediction only if it is different, preventing a flash every 0.5 seconds. This is used for the auto-prediction extension.

            The nber_historic_files.txt file
                => This allows for storing the number of historic files. This is useful at the beginning of the program to know how many files there are to analyze and parse and to know their names "user_history/user_files/historic_partN.txt" where N is the number of the file.
    
    Extensions:

        The extensions are in a specified folder named "src/extensions". The reason for this is because, for our project, we need to easily distinguish the extension version from the basic one. If we didn't, we would probably put all the extension files into the other files, such as src/tree.oz, src/interface.oz, and src/function.oz.

        The functions in the extension files are very long and not well separated. Therefore, the code is harder to read than the rest of the code. The only reason is the lack of time to totally clean all the files.


## Problems

If you are on a Mac and you have some problems to compile, you need to remove the image at Line 54 in the src/extensions/interface_improved file.

In this case, you may not be able to see the colors of the buttons or the image, but we didn't find the source of the problem.