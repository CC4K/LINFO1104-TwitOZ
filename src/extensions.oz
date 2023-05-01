functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
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
        PathHistoricFile = "user_historic/historic_part"
        Nber_HistoricFiles = 1 % Get the real one @TODO
    in
        try
            Name_File = {Function.append_List PathHistoricFile {Append {Int.toString Nber_HistoricFiles} ".txt"}}
            Historic_File = {New Open.file init(name:Name_File flags:[write create truncate])}
            Contents = {Variables.inputText get($)}
        in
            % Write the datas in the file to save them for the next usage
            {Historic_File write(vs:Contents)}
            {Historic_File close}
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
        catch _ then {Application.exit} end 
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
        catch _ then {Application.exit} end 
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% ====== 4eme EXTENSION ====== %%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%% DATABASE ADDER SENTENCES IMPLEMENTATION  %%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    proc {Send_NewTree_ToPort Name_File}
        local BefTree NewTree LineToParsed File_Parsed L P in
            thread _ =
                LineToParsed = {Reader.read Name_File}
                L=1
                {Wait L} 
                File_Parsed = {Parser.parses_AllLines LineToParsed}
                P=1
                {Wait P}
                % Send to the port the new update tree with the new datas
                BefTree = {Function.get_Tree}
                NewTree = {Create_Updated_Tree {Function.get_Tree} File_Parsed}
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


    fun {Update_SubTree SubTree Key NewValue}
        if SubTree == notfound then {Tree.insert leaf 1 [NewValue]}
        else {Get_List_Value SubTree Key} end
    end


    fun {Get_List_Value SubTree Value_Word}
        local
            fun {Get_List_Value_Aux SubTree Updated_SubTree}
                case SubTree
                of leaf then Updated_SubTree
                [] tree(key:Key value:Value_List t_left:TLeft t_right:TRight) then
                    local T1 New_List_Value in
                        if {IsInList Value_List Value_Word} == true then
                            New_List_Value = {RemoveElemOfList Value_List Value_Word}
                            {AddElemToList_InTree {Tree.insert SubTree Key New_List_Value} Key+1 Value_Word}
                        else
                            T1 = {Get_List_Value_Aux TLeft Updated_SubTree}
                            _ = {Get_List_Value_Aux TRight T1}
                        end
                    end
                end
            end
        in
            {Get_List_Value_Aux SubTree leaf}
        end
    end


    fun {AddElemToList_InTree SubTree Key Word_Value}
        local Value_List in
            Value_List = {Tree.lookingUp SubTree Key}
            if Value_List == notfound then {Tree.insert SubTree Key [Word_Value]}
            else {Tree.insert SubTree Key Word_Value|Value_List} end
        end
    end


    fun {IsInList List Value}
        case List
        of nil then false
        [] H|T then
            if H == Value then true
            else {IsInList T Value} end
        end
    end

    fun {RemoveElemOfList Value_List Value_Word}
        local
            fun {RemoveElemOfList_Aux Value_List New_Value_List}
                case Value_List
                of nil then New_Value_List
                [] H|T then
                    if H == Value_Word then {Function.append_List New_Value_List T}
                    else {RemoveElemOfList_Aux T Value_Word|New_Value_List} end
                end
            end
        in
            {RemoveElemOfList_Aux Value_List nil}
        end
    end
end