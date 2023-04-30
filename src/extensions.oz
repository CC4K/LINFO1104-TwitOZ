functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
    System
    Function at 'function.ozf'
    Interface at 'interface.ozf'
    Parser at 'parser.ozf'
    Tree at 'tree.ozf'
    Main at 'main.ozf'
export
    ProposeAllTheWords
    N_Grams
    AddDatas_ToTree
    SaveText
    LoadText
define

    %%% PROPOSE ALL THE MOST PROBABLE WORDS + FREQUENCE + PROBABILITY %%%

    proc {ProposeAllTheWords List_MostProbableWords Frequency Probability}
        local
            proc {ProposeAllTheWords_Aux List_MostProbableWords LastPos}
                case List_MostProbableWords
                of nil then {Interface.insertText_Window Main.outputText 1 LastPos none " ]\n"}
                [] H|T then
                    {Interface.insertText_Window Main.outputText 1 LastPos none 32|{Atom.toString H}}
                    {ProposeAllTheWords_Aux T LastPos+1+{Length {Atom.toString H}}}
                end
            end
        in
            {Interface.setText_Window Main.outputText "The most probable word(s) : ["}
            {ProposeAllTheWords_Aux List_MostProbableWords 30}
            {DisplayFreq_And_Probability 2 Frequency Probability}
        end
    end

    proc {DisplayFreq_And_Probability Row Frequency Probability}
        local Str_Frequency Str_Probability in

            if {Float.is Frequency} == true then
                Str_Frequency = {Float.toString Frequency}
            else
                Str_Frequency = {Int.toString Frequency}
            end

            if {Float.is Probability} == true then
                Str_Probability = {Float.toString Probability}
            else
                Str_Probability = {Int.toString Probability}
            end

            {Interface.insertText_Window Main.outputText Row 0 none {Append "The frequency of the/these word(s) is : " {Append Str_Frequency "\n"}}}
            {Interface.insertText_Window Main.outputText Row+1 0 none {Append "The probability of the/these word(s) is : " Str_Probability}}
        end
    end



    %%% N-GRAMME IMPLEMENTATION %%%

    fun {N_Grams List_N_Grams}
        local
            fun {N_Grams_Aux List_N_Grams NewList}
                {System.show List_N_Grams}
                case List_N_Grams
                of nil then NewList
                [] H|T then
                    local SplittedList in
                        {System.show T}
                        {System.show 'hello'}
                        SplittedList = {Function.splitList_AtIdx T Main.n_of_NGram-1}
                        {System.show 'okkkkk'}
                        if SplittedList == none then NewList
                        else
                            {N_Grams_Aux T {Function.concatenateElemOfList H|SplittedList.1 32}|NewList}
                        end
                    end
                end
            end
        in
            {Reverse {N_Grams_Aux List_N_Grams nil}}
        end
    end


    %%% DATABASE ADDER SENTENCES IMPLEMENTATION %%%

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

    fun {UpdateSubTree Main_Tree Key List_Keys}

        local Value in
            Value = {Tree.lookingUp Main_Tree Key}
            if Value == notfound then {Tree.insert Main_Tree Key {Function.get_Last_Nth_Word_List List_Keys.1 Main.n_Of_N_Grams}}
            else
                {Tree.traverseAndChange Main_Tree fun {$ Tree Key Value} {UpdateSubTreeValue Tree Key Value} end}
            end
        end
    end

    fun {AddDatas_ToTree Tree TextUserInput}

        local SplittedText SplittedText_Cleaned List_NGrams Updater_Value in

            % Clean the input user
            SplittedText = {Parser.cleaningUserInput {Function.tokens_String TextUserInput 32}}
            SplittedText_Cleaned = {Map SplittedText proc {$ Str_Line}
                                    {Parser.removeEmptySpace
                                        {Parser.parseLine
                                            {Parser.cleanUp Str_Line
                                                fun {$ Line_Str} {Parser.removePartList Line_Str [226 128] 32 true} end
                                            }
                                        false}
                                    }
                                end}

            List_NGrams = {N_Grams SplittedText_Cleaned}

            Updater_Value = fun {$ Tree Key List_Keys} {UpdateSubTree Tree Key List_Keys} end

            % The new main_tree updated
            {Tree.updateElementsOfTree Tree Updater_Value List_NGrams}
        end
    end





    %%% IMPROVE GUI %%% %%% IMPROVE GUI %%% %%% IMPROVE GUI %%% %%% IMPROVE GUI %%%


    %%%
    % Saves an input text from the app window as a text file on the computer
    %
    % @param: /
    % @return: /
    %%%
    proc {SaveText}
        local File Name_File Contents in
            Name_File = {QTk.dialogbox save(defaultextension:"txt"
                                       filetypes:q(q("Txt files" q(".txt")) q("All files" q("*"))) $)}
            
            try 
                File = {New Open.file init(name:Name)}
                Contents = {File read(list:$ size:all)}
                _={AddDatas_ToTree Main.main_Tree Contents}
            in 
                {Main.inputText set(Contents)}
                {File close}
            catch _ then {Application.exit} end
        end
    end

    %%%
    % Loads a text file as prediction input in the app window
    %
    % @param: /
    % @return: /
    %%%
    proc {LoadText}
        Name = {QTk.dialogbox load(defaultextension:"txt"
                                 filetypes:q(q("Txt files" q(".txt")) q("All files" q("*"))) $)}
        Contents = {Main.inputText get($)}
    in 
        try 
            File = {New Open.file init(name:Name)}
            Contents = {File read(list:$ size:all)}
        in 
            {Main.inputText set(Contents)}
            {File close}
        catch _ then {Application.exit} end 
    end

end