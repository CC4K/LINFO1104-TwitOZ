functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
    OS
    System
    
    Variables at 'variables.ozf'
    Interface at 'interface.ozf'
    Function at 'function.ozf'
    Reader at 'reader.ozf'
    Parser at 'parser.ozf'
    Tree at 'tree.ozf'
export
    ProposeAllTheWords
    N_Grams
    Create_Updated_Tree
    GetDescriptionGUI
    SaveText_UserFinder
    LoadText
    SaveText_Database
    LaunchThreads_HistoricUser
    Get_Nber_HistoricFile
    Automatic_Prediction
define

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% ====== FIRST EXTENSION ====== %%%%%%%%%%%%%%%%%%%%%%
    %%% PROPOSE ALL THE MOST PROBABLE WORDS + FREQUENCE + PROBABILITY %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%
    % Display the most probable word(s) in the output window
    % And display the frequency + probability of the word(s)
    % See example usage in the docstring of 'DisplayFreq_And_Probability'
    %
    % Example usage:
    % In: ['the' 'most' 'probable' 'word'] 19 0.54321
    % Out: The most probable word(s) : [the most probable word] + Output of 'DisplayFreq_And_Probability'
    %
    % @param List_MostProbableWords: The list of the most probable word(s)
    % @param Frequency: The frequency of the word(s)
    % @param Probability: The probability of the word(s)
    % @return: /
    proc {ProposeAllTheWords List_MostProbableWords Frequency Probability}
        local
            proc {ProposeAllTheWords_Aux List_MostProbableWords LastPos}
                case List_MostProbableWords
                of nil then {Interface.insertText_Window Variables.outputText 1 LastPos none " ]\n"}
                [] H|T then
                    {Interface.insertText_Window Variables.outputText 1 LastPos none 32|{Atom.toString H}}
                    {ProposeAllTheWords_Aux T LastPos+1+{Length {Atom.toString H}}}
                end
            end
        in
            {Interface.setText_Window Variables.outputText "The most probable word(s) : ["}
            {ProposeAllTheWords_Aux List_MostProbableWords 30}
            {DisplayFreq_And_Probability 2 Frequency Probability}
        end
    end

    %%%
    % Display the frequency and the probability of the word(s) in the output window
    %
    % Example usage:
    % In: 1 19 0.54321
    % Out: The frequency of the/these word(s) is : 19
    %      The probability of the/these word(s) is : 0.54321
    %
    % @param Row: The row where the text will be displayed
    % @param Frequency: The frequency of the word(s)
    % @param Probability: The probability of the word(s)
    % @return: /
    proc {DisplayFreq_And_Probability Row Frequency Probability}
        local Str_Frequency Str_Probability in

            if {Float.is Frequency} == true then Str_Frequency = {Float.toString Frequency}
            else Str_Frequency = {Int.toString Frequency} end

            if {Float.is Probability} == true then Str_Probability = {Float.toString Probability}
            else Str_Probability = {Int.toString Probability} end

            {Interface.insertText_Window Variables.outputText Row 0 none {Append "The frequency of the/these word(s) is : " {Append Str_Frequency "\n"}}}
            {Interface.insertText_Window Variables.outputText Row+1 0 none {Append "The probability of the/these word(s) is : " Str_Probability}}
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% ====== SECOND EXTENSION ====== %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%% N-GRAMME IMPLEMENTATION (GENERAL => FOR ALL N) %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%
    % Return the list of all the n-grams of the text.
    % The text is a list of words.
    %
    % Example usage:
    % In1: ['the' 'most' 'probable' 'word'] 2
    % Out1: [['the' 'most'] ['most' 'probable'] ['probable' 'word']]
    % In2: ['the' 'most' 'probable' 'word' 'yes'] 3
    % Out2: [['the' 'most' 'probable'] ['most' 'probable' 'word'] ['probable' 'word' 'yes']]
    %
    % @param List_Words: The list of words (text)
    % @param N: a positive integer representing the prefixe of N-gramme
    %           (= size of each element of the n-grams list)
    % @return: The list of all the n-grams of the text.
    fun {N_Grams List_N_Grams}
        local
            fun {N_Grams_Aux List_N_Grams NewList}
                case List_N_Grams
                of nil then {Reverse NewList}
                [] H|T then
                    local SplittedList = {Function.splitList_AtIdx T Variables.idx_N_Grams-1} in
                        if SplittedList == none then {Reverse NewList}
                        else {N_Grams_Aux T {Function.concatenateElemOfList H|SplittedList.1 32}|NewList} end
                    end
                end
            end
        in
            {N_Grams_Aux List_N_Grams nil}
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% ====== THIRD EXTENSION ====== %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%% ============= IMPROVE GUI  ============= %%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fun {GetDescriptionGUI CallerPress}
        lr( title: "TwitOZ"
            background:c(27 157 240)
            td( text(handle:Variables.inputText height:15 font:{QTk.newFont font(family:"Verdana")} background:white foreground:black wrap:word)
                text(handle:Variables.outputText height:15 font:{QTk.newFont font(family:"Verdana")} background:black foreground:white wrap:word)
                )
            td( %label(image:{QTk.newImage photo(url:"./twit.png")} borderwidth:0 width:290)
                td( button(text:"Predict" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:CallerPress)
                    button(text:"Save as .txt file" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:SaveText_UserFinder)
                    button(text:"Save file in database" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:SaveText_Database)
                    button(text:"Clean user historic" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:Clean_UserHistoric)
                    button(text:"Load file as input" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:LoadText)
                    button(text:"Quit" height:2 width:20 background:c(29 125 242) relief:sunken borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:proc{$} {Application.exit 0} end)
                    )
                )
            action:proc{$} {Application.exit 0} end
            )
    end


    %%%
    % Saves an input text from the app window as a text file into the database.
    % The datas will be therefore be used for the next prediction.
    % @param: /
    % @return: /
    %%%
    proc {SaveText_Database}

        % Name folder to stock the historic of user
        PathHistoricFile = "user_historic/user_files/historic_part"
    in
        try
            % Open the file where the number of historic files is stored
            Historic_NberFiles_File_Reading = {New Open.file init(name:"user_historic/nber_historic_files.txt" flags:[read])}

            % Read this file to get the number of historic files incremented of 1
            Nber_HistoricFiles = {String.toInt {Historic_NberFiles_File_Reading read(list:$ size:all)}} + 1

            {Historic_NberFiles_File_Reading close}

            Historic_NberFiles_File_Writing = {New Open.file init(name:"user_historic/nber_historic_files.txt" flags:[write create truncate])}

            % Write the new number of historic files in the file
            {Historic_NberFiles_File_Writing write(vs:{Int.toString Nber_HistoricFiles})}

            % Get the name of the new file to create
            Name_File = {Function.append_List PathHistoricFile {Function.append_List {Int.toString Nber_HistoricFiles} ".txt"}}

            % Open the file
            Historic_File = {New Open.file init(name:Name_File flags:[write create truncate])}

            % Get the contents of the user
            Contents = {Variables.inputText get($)}
        in
            % Close the file where the number of historic files is stored
            {Historic_NberFiles_File_Writing close}

            % Write the datas in the file to save them for the next usage
            {Historic_File write(vs:Contents)}

            % Close the file where the user historic datas are stored
            {Historic_File close}

            % Send the new tree to the port
            {Send_NewTree_ToPort Name_File}
        catch _ then {System.show 'Error when saving the file into the database'} {Application.exit 0} end
    end


    %%%
    % Saves an input text from the app window as a text file on the user's computer.
    %
    % @param: /
    % @return: /
    %%%
    proc {SaveText_UserFinder}
        Name = {QTk.dialogbox save( defaultextension:"txt"
                                    filetypes:q(q("Txt files" q(".txt")) q("All files" q("*"))) $)}
    in 
        try 
            User_File = {New Open.file init(name:Name flags:[write create truncate])}
            Contents = {Variables.inputText get($)}
        in 
            {User_File write(vs:Contents)}
            {User_File close}
        catch _ then {System.show 'Error when saving the file into the user specified file'} {Application.exit} end 
    end


    %%%
    % Loads a text file in the input section in the app window.
    %
    % @param: /
    % @return: /
    %%%
    proc {LoadText}
        Name = {QTk.dialogbox load(defaultextension:"txt"
                                 filetypes:q(q("Txt files" q(".txt")) q("All files" q("*"))) $)}
        Contents = {Variables.inputText get($)}
    in 
        try
            File = {New Open.file init(name:Name)}
            Contents = {File read(list:$ size:all)}
        in 
            {Variables.inputText set(Contents)}
            {File close}
        catch _ then {System.show 'Error when loading the file into the window'} {Application.exit} end 
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% ====== 4eme EXTENSION ====== %%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%% DATABASE ADDER SENTENCES IMPLEMENTATION  %%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

     %%%% TODO %%%%
    proc {Send_NewTree_ToPort Name_File}
        local NewTree LineToParsed File_Parsed L P in
            thread _ =
                LineToParsed = {Reader.read Name_File}
                L=1
                {Wait L} 
                File_Parsed = {Parser.parses_AllLines LineToParsed}
                P=1
                {Wait P}
                NewTree = {Create_Updated_Tree {Function.get_Tree} File_Parsed}
                % Send to the port the new update tree with the new datas
                {Send Variables.port_Tree NewTree}
            end
        end
    end

    
    %%%
    % Adds the datas of a text to the main tree.
    %
    % @param Tree: The tree to which we want to add the datas
    % @param TextUserInput: The user text from which we want to add the datas
    % @return: The new main tree updated with the new datas added
    %%%
    fun {Create_Updated_Tree Main_Tree List_UserInput} 
        case List_UserInput
        of nil then Main_Tree
        [] H|T then
            {Create_Updated_Tree {Create_Updated_Tree_Aux Main_Tree {N_Grams {Function.tokens_String H 32}}} T}
        end
    end


     %%%% TODO %%%%
    fun {Create_Updated_Tree_Aux New_Tree List_Keys}
        local
            %%%
            % Changes the value with a new specified one at the location of a specified key in a binary tree
            %%%
            fun {Update_Value New_Tree Key List_Keys}
                local Value_to_Insert Tree_Value New_Tree_Value in
                    Value_to_Insert = {String.toAtom {Reverse {Function.tokens_String List_Keys.1 32}}.1}
                    Tree_Value = {Tree.lookingUp New_Tree Key}
                    New_Tree_Value = {Update_SubTree Tree_Value Key Value_to_Insert}
                    {Tree.insert New_Tree Key New_Tree_Value}
                end
            end
        in
            case List_Keys
            of nil then New_Tree
            [] _|nil then New_Tree
            [] H|T then
                {Create_Updated_Tree_Aux {Update_Value New_Tree {String.toAtom H} T} T}
            end
        end
    end


    %%%% TODO %%%%
    fun {Update_SubTree SubTree Key NewValue}
        if SubTree == notfound then {Tree.insert leaf 1 [NewValue]}
        else
            local Updated_SubTree List_Value in
                Updated_SubTree = {Get_List_Value SubTree NewValue}
                if SubTree == Updated_SubTree then
                    List_Value = {Tree.lookingUp SubTree 1}
                    if List_Value == notfound then {Tree.insert SubTree 1 [NewValue]}
                    else {Tree.insert SubTree 1 NewValue|List_Value} end
                else
                    Updated_SubTree
                end
            end
        end
    end


     %%%% TODO %%%%
    fun {Get_List_Value SubTree Value_Word}
        local
            fun {Get_List_Value_Aux SubTree Updated_SubTree}
                case SubTree
                of leaf then Updated_SubTree
                [] tree(key:Key value:Value_List t_left:TLeft t_right:TRight) then
                    local T1 New_List_Value Length_Value_List in
                        if {IsInList Value_List Value_Word} == true then
                            Length_Value_List = {Length Value_List}
                            if Length_Value_List == 1 then {Tree.insert_Key Updated_SubTree Key Key+1}
                            else
                                New_List_Value = {RemoveElemOfList Value_List Value_Word}
                                if Length_Value_List == {Length New_List_Value} then {AddElemToList_InTree Updated_SubTree Key+1 Value_Word}
                                else {AddElemToList_InTree {Tree.insert Updated_SubTree Key New_List_Value} Key+1 Value_Word} end
                            end
                        else
                            T1 = {Get_List_Value_Aux TLeft Updated_SubTree}
                            _ = {Get_List_Value_Aux TRight T1}
                        end
                    end
                end
            end
        in
            {Get_List_Value_Aux SubTree SubTree}
        end
    end


     %%%% TODO %%%%
    fun {AddElemToList_InTree SubTree Key Word_Value}
        local Value_List in
            Value_List = {Tree.lookingUp SubTree Key}
            if Value_List == notfound then {Tree.insert SubTree Key [Word_Value]}
            else {Tree.insert SubTree Key Word_Value|Value_List} end
        end
    end


     %%%% TODO %%%%
    fun {IsInList List Value}
        case List
        of nil then false
        [] H|T then
            if H == Value then true
            else {IsInList T Value} end
        end
    end


     %%%% TODO %%%%
    fun {RemoveElemOfList Value_List Value_Word}
        local
            fun {RemoveElemOfList_Aux Value_List New_Value_List}
                case Value_List
                of nil then New_Value_List
                [] H|T then
                    if H == Value_Word then {Function.append_List New_Value_List T}
                    else {RemoveElemOfList_Aux T H|New_Value_List} end
                end
            end
        in
            {RemoveElemOfList_Aux Value_List nil}
        end
    end


     %%%% TODO %%%%
    proc {Clean_UserHistoric}
        local Historic_NberFiles_File in
            % Open the file where the number of historic files is stored and reset it to 0
            Historic_NberFiles_File = {New Open.file init(name:"user_historic/nber_historic_files.txt" flags:[write])}
            {Historic_NberFiles_File write(vs:{Int.toString 0})}
            {Historic_NberFiles_File close}

            % Delete all the historic files
            {Delete_HistoricFiles}
        end
    end


    %%%% TODO %%%%
    proc {Delete_HistoricFiles}
        {OS.pipe make "clean_user_historic"|nil _ _}
    end



     %%%% TODO %%%%
    fun {Get_Nber_HistoricFile}
        local Historic_NberFiles_File Nber_HistoricFiles in
            Historic_NberFiles_File = {New Open.file init(name:"user_historic/nber_historic_files.txt" flags:[read])}
            Nber_HistoricFiles = {String.toInt {Historic_NberFiles_File read(list:$ size:all)}}
            {Historic_NberFiles_File close}
            Nber_HistoricFiles
        end
    end

     
    %%%% TODO %%%%
    fun {LaunchThreads_HistoricUser}
        local
            fun {LaunchThreads_HistoricUser_Aux Id_Thread List_Waiting_Threads}
                if Id_Thread == Variables.nber_HistoricFiles + 1 then List_Waiting_Threads
                else
                    local File_Parsed File LineToParsed L P in
                        thread _ =
                            File = {Function.append_List "user_historic/user_files/historic_part" {Function.append_List {Int.toString Id_Thread} ".txt"}}
                            LineToParsed = {Reader.read File}
                            L=1
                            {Wait L} 
                            File_Parsed = {Parser.parses_AllLines LineToParsed}
                            P=1
                            {Send Variables.separatedWordsPort File_Parsed}
                        end
                        
                        {LaunchThreads_HistoricUser_Aux Id_Thread+1 P|List_Waiting_Threads}
                    end
                end
            end
        in
            {LaunchThreads_HistoricUser_Aux 1 nil}
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% PREDICTION AUTOMATIQUE %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    proc {Automatic_Prediction}
        local User_Input List_Words Splitted_Words First_Key Second_Key Value_Tree Value_Tree2 ResultPress ProbableWords Probability Frequency in
            User_Input = {Variables.inputText getText(p(1 0) 'end' $)}
            List_Words = {Function.get_Last_Nth_Word_List User_Input Variables.idx_N_Grams+1}
            Splitted_Words = {Function.tokens_String List_Words 32}
            First_Key = {Function.concatenateElemOfList [Splitted_Words.1 Splitted_Words.2.1] 32}
            Second_Key = {Function.concatenateElemOfList [Splitted_Words.2.1 Splitted_Words.2.2.1] 32}
            Value_Tree = {Tree.lookingUp {Function.get_Tree} {String.toAtom Second_Key}}
            if Value_Tree == notfound then
                Value_Tree2 = {Tree.lookingUp {Function.get_Tree} {String.toAtom First_Key}}
                if Value_Tree2 == notfound then
                    {Interface.insert Variables.outputText 1 0 none "Words not found."}
                    %%TODO
                    %% Need to search with the letters
                    %%TODO
                else
                    ResultPress = {Tree.get_Result_Prediction Value_Tree2}
                    ProbableWords = ResultPress.1
                    Probability = ResultPress.2.1
                    Frequency = ResultPress.2.2.1

                    if ProbableWords == [nil] then {Interface.insert Variables.outputText 1 0 none "Words not found."}
                    else {ProposeAllTheWords ProbableWords Frequency Probability} end
                end
            else
                ResultPress = {Tree.get_Result_Prediction Value_Tree}
                ProbableWords = ResultPress.1
                Probability = ResultPress.2.1
                Frequency = ResultPress.2.2.1

                if ProbableWords == [nil] then {Interface.insert Variables.outputText }
                else {ProposeAllTheWords ProbableWords Frequency Probability} end
            end
        end
    end

end