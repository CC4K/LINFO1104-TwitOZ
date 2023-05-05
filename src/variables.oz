functor
export
    InputText
    OutputText
    CorrectText
    Idx_N_Grams
    TweetsFolder_Name
    List_PathName_Tweets
    Tree_Over
    NberFiles
    NbThreads
    SeparatedWordsPort
    SeparatedWordsStream
    Window
    Description
    Port_Tree
    Stream_Tree
    Nber_HistoricFiles
define

    % Global variables that will not be modify during the execution
    % of the program (except 'Stream_Tree' to store the future updated tree).

	InputText % The input text of the window
    OutputText % The output text of the window
    CorrectText % The correct text of the window

    Idx_N_Grams % The n-grams index

    NberFiles % The number of files in the tweets folder
    NbThreads % The number of threads to use
    Nber_HistoricFiles % The number of historic files to parses

    TweetsFolder_Name % The name of the folder containing the tweets
    List_PathName_Tweets % The list of the relatives pathnames of the tweets

    Tree_Over % To know when the first main_tree is over and ready to be used

    Port_Tree % The port used to send to 'Stream_Tree' the updated tree
    Stream_Tree % The stream used to get the last updated tree
    SeparatedWordsPort % The port used to send to 'SeparatedWordsStream' the text parsed (from the tweets)
    SeparatedWordsStream % The stream used to get the text parsed (from the tweets)

    Window % The window to display graphics and informations
    Description % The description of the window

end