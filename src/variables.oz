functor
export
    InputText
    OutputText
    CorrectText

    NberFiles
    NbThreads
    Nber_HistoricFiles

    List_PathName_Tweets

    Tree_Over

    Port_Tree
    Stream_Tree
    SeparatedWordsPort
    SeparatedWordsStream
    Port_Auto_Corr_Threads
    Stream_Auto_Corr_Threads

    Window
    Description

    Folder_Name
    Idx_N_grams
    Correction_Words
    Files_Database 
    Auto_Prediction

define

    % Global variables that will not be modify during the execution
    % of the program (except some Stream to store informations).

	InputText % The input text of the window
    OutputText % The output text of the window
    CorrectText % The correct text of the window

    NberFiles % The number of files in the tweets folder
    NbThreads % The number of threads to use
    Nber_HistoricFiles % The number of historic files to parses

    List_PathName_Tweets % The list of the relatives pathnames of the tweets

    Tree_Over % To know when the first main_tree is over and ready to be used

    Port_Tree % The port used to send to 'Stream_Tree' the updated tree
    Stream_Tree % The stream used to get the last updated tree
    SeparatedWordsPort % The port used to send to 'SeparatedWordsStream' the text parsed (from the tweets)
    SeparatedWordsStream % The stream used to get the text parsed (from the tweets)
    Port_Auto_Corr_Threads % The port used to send to 'Stream_Auto_Corr_Threads' the time of delay for the thread that do the automatic_prediction
    Stream_Auto_Corr_Threads % The stream used to get the time of delay for the thread that do the automatic_prediction

    Window % The window to display graphics and informations
    Description % The description of the window

    % Arguments specified by the user
    Folder_Name % The name of the folder where the tweets are stored
    Idx_N_grams % The n-grams index
    Correction_Words % integer to know if the user want to use the extension to correct the words or not
    Files_Database % integer to know if the user want to use the extension to store the input's user in a database or not
    Auto_Prediction % integer to know if the user want to use the extension to do the automatic prediction or not

end