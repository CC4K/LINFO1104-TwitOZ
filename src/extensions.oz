functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
    Variables at 'variables.ozf'
    Interface at 'interface.ozf'
    Function at 'function.ozf'
    Parser at 'parser.ozf'
    Tree at 'tree.ozf'
export
    ProposeAllTheWords
    N_Grams
    AddDatas_ToTree
    GetDescriptionGUI
    SaveText
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
            td( label(image:{QTk.newImage photo(url:"./twit.png")} borderwidth:0 width:290)
                td( button(text:"Predict" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:CallerPress)
                    button(text:"Save as .txt file" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:SaveText)
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
    %%%%%%%%%%%%% TODO (IMPLEMENTATION) %%%%%%%%%%%%%
    %%%%%%%%%%%%% TODO (IMPLEMENTATION) %%%%%%%%%%%%%
    proc {SaveText_Database}
        Name = {QTk.dialogbox save(   defaultextension:"txt"
                                    filetypes:q(q("Txt files" q(".txt")) q("All files" q("*"))) $)}
    in 
        try 
            DataBase_File = {New Open.file init(name:{Append {Append "tweets/" Name} ".txt"} flags:[write create truncate])}
            Contents = {Variables.inputText get($)}
            {Send Variables.port_Tree {AddDatas_ToTree {Function.get_Tree} Contents}}
        in 
            {DataBase_File write(vs:Contents)}
            {DataBase_File close}
        catch _ then {Application.exit} end 
    end


    %%%
    % Saves an input text from the app window as a text file on the computer.
    %
    % @param: /
    % @return: /
    %%%
    proc {SaveText}
        Name = {QTk.dialogbox save(   defaultextension:"txt"
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

    %%% DONT KNOW IF THIS SECTION OF FUNCTIONS WORKS => DONT TEST YET %%%
    %%% DONT KNOW IF THIS SECTION OF FUNCTIONS WORKS => DONT TEST YET %%%
    %%% DONT KNOW IF THIS SECTION OF FUNCTIONS WORKS => DONT TEST YET %%%


    %%%
    % Updates the value of one subtree of the main tree at the location of a specified key.
    %
    % @param Main_Tree: The main tree to update
    % @param Key: The key of the main tree to update
    % @param Value_to_Insert: The value to insert in the subtree of the main tree at the location of the key
    % @return: The new main tree updated with the new datas added in one subtree
    fun {UpdateSubTree Main_Tree Key Value_to_Insert}

        local
            Value
            fun {UpdateSubTreeValue Main_Tree Key Value}
                local
                    Old_Value
                    NewValue
                    fun {UpdateSubTreeValue Main_Tree Key Value NewValue}
                        case Value
                        of nil then NewValue
                        [] H|T then
                            if H == Value then NewValue
                            else {UpdateSubTreeValue Main_Tree Key T H|NewValue} end
                        end
                    end
                in
                    NewValue = {UpdateSubTreeValue Main_Tree Key Value nil}
                    if {Length NewValue} == {Length Value} then Main_Tree
                    else
                        {Tree.insert Main_Tree Key NewValue}
                        Old_Value = {Tree.lookingUp Main_Tree Key+1}
                        if Old_Value == notfound then {Tree.insert Main_Tree Key+1 Value}
                        else {Tree.insert Main_Tree Key+1 Value|Old_Value} end
                    end
                end
            end
        in
            Value = {Tree.lookingUp Main_Tree Key}
            if Value == notfound then {Tree.insert Main_Tree Key Value_to_Insert}
            else
                {Tree.updateAll_Tree Main_Tree fun {$ Tree Key Value}
                                                    {UpdateSubTreeValue Tree Key Value}
                                               end
                                               % The condition allows to applies the function only if the key at the node is the same as 'Key_To_Access'
                                               fun {$ Key_Tree Key_To_Access}
                                                    Key_To_Access == Key_Tree
                                               end
                                               Key}
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
    fun {AddDatas_ToTree Tree TextUserInput}

        local SplittedText SplittedText_Cleaned List_NGrams Updater_Value in

            % Clean the input user
            SplittedText = {Parser.cleaningUserInput {Function.tokens_String TextUserInput 32}}
            SplittedText_Cleaned = {Map SplittedText proc {$ Str_Line}
                                                         {Parser.removeEmptySpace
                                                         {Parser.parseLine
                                                         {Parser.removePartList Str_Line [226 128] 32 true}
                                                         false}}
                                                     end}

            List_NGrams = {N_Grams SplittedText_Cleaned}

            Updater_Value = fun {$ Tree Key List_Keys} {UpdateSubTree Tree Key {Function.get_Last_Nth_Word_List List_Keys.1 Variables.idx_N_Grams}} end

            % The new main_tree updated
            {Tree.updateElementsOfTree Tree Updater_Value List_NGrams}
        end
    end
end