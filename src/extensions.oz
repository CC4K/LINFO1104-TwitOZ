functor
import
    Function at 'function.ozf'
    Interface at 'interface.ozf'
    Parser at 'parser.ozf'
    Tree at 'tree.ozf'
export
    ProposeAllTheWords
    N_Grams
define



    %%% PROPOSE ALL THE MOST PROBABLE WORDS + FREQUENCE + PROBABILITY %%%

    proc {ProposeAllTheWords List_MostProbableWords Frequency Probability LocationText}
        local
            proc {ProposeAllTheWords_Aux List_MostProbableWords LastPos}
                case List_MostProbableWords
                of nil then {Interface.insertText_Window LocationText 1 LastPos none " ]\n"}
                [] H|T then
                    {Interface.insertText_Window LocationText 1 LastPos none 32|{Atom.toString H}}
                    {ProposeAllTheWords_Aux T LastPos+1+{Length {Atom.toString H}}}
                end
            end
        in
            {Interface.setText_Window LocationText "The most probable word(s) : ["}
            {ProposeAllTheWords_Aux List_MostProbableWords 30}
            {DisplayFreq_And_Probability LocationText 2 Frequency Probability}
        end
    end

    proc {DisplayFreq_And_Probability LocationText Row Frequency Probability}
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

            {Interface.insertText_Window LocationText Row 0 none {Append "The frequency of the/these word(s) is : " {Append Str_Frequency "\n"}}}
            {Interface.insertText_Window LocationText Row+1 0 none {Append "The probability of the/these word(s) is : " Str_Probability}}
        end
    end



    %%% N-GRAMME IMPLEMENTATION %%%

    fun {N_Grams List_N_Grams N}
        local
            fun {N_Grams_Aux List_N_Grams NewList}
                case List_N_Grams
                of nil then NewList
                [] H|T then
                    local SplittedList in
                        SplittedList = {Function.splitList_AtIdx List_N_Grams N}
                        if SplittedList == none then NewList
                        else
                            {N_Grams_Aux T {Function.concatenateElemOfList SplittedList.1 32}|NewList}
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

    fun {UpdateSubTree Main_Tree Key List_Keys N_Of_N_Grams}

        local Value in
            Value = {Tree.lookingUp Main_Tree Key}
            if Value == notfound then {Tree.insert Main_Tree Key {Function.get_Last_Nth_Word_List List_Keys.1 N_Of_N_Grams}}
            else
                {Tree.traverseAndChange Main_Tree fun {$ Main_Tree Key Value} {UpdateSubTreeValue Main_Tree Key Value} end}
            end
        end
    end

    fun {AddDatas_ToTree Main_Tree N_Of_N_Grams LocationText}

        local SplittedText SplittedText_Cleaned List_NGrams New_Main_Tree Updater_Value in

            % Clean the input user
            SplittedText = {Parser.cleaningUserInput {Function.tokens_String {LocationText getText(p(1 0) 'end' $)} 32}}
            SplittedText_Cleaned = {Map SplittedText proc {$ Str_Line}
                                    {Parser.removeEmptySpace
                                        {Parser.parseLine
                                            {Parser.cleanUp Str_Line
                                                fun {$ Line_Str} {Parser.removePartList Line_Str [226 128] 32 true} end
                                            }
                                        false}
                                    }
                                end}

            List_NGrams = {N_Grams SplittedText_Cleaned N_Of_N_Grams}

            Updater_Value = fun {$ Tree Key List_Keys} {UpdateSubTree Tree Key List_Keys N_Of_N_Grams} end
            New_Main_Tree = {Tree.updateElementsOfTree Main_Tree Updater_Value List_NGrams N_Of_N_Grams}
            New_Main_Tree
        end
    end

end