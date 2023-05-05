functor
import
    Variables at '../variables.ozf'
    Function at '../function.ozf'
    Interface at '../interface.ozf'
    Parser at '../parser.ozf'
    Tree at '../tree.ozf'
    Predict_All at 'predict_All.ozf'
export
    CorrectionSentences % Correct the word writed by the user in the input text.
define

    
    %%%
    % Correct the word writed by the user in the input text.
    % Give the best prediction instead the word writed by the user.
    %
    % @param: /
    % @return: /
    %%%
    proc {CorrectionSentences}
        if Variables.tree_Over == true then
            local Word_User Word_User_Parsed List_Keys in
                Word_User = {Variables.correctText get($)}
                Word_User_Parsed = {Parser.cleaningUserInput Word_User}
                if {Length Word_User_Parsed} \= 1 then
                    {Interface.setText_Window Variables.outputText ""}
                    {Interface.insertText_Window Variables.outputText 0 0 'end' "Please enter only one word.\n"}
                else
                    List_Keys = {Get_List_All_N_Words_Before Word_User_Parsed.1}
                    {DisplayResults List_Keys {String.toAtom Word_User_Parsed.1}}
                end
            end
        else skip end
    end


    %%%
    % Split a list with a delimiter.
    %
    % Example usage:
    % In: "Hello, my name is John"    " "
    % Out: ["Hello," "my" "name" "is" "John"]
    %
    % @param: List: list to split
    % @param: Delimiter: delimiter to split the list
    % @return: the list splitted into lists
    %%%
    fun {Split_List_Delimiter List Delimiter}
        local
            Length_Delimiter = {Length Delimiter}
            fun {Split_List_Delimiter_Aux List SubList NewList}
                case List
                of nil then
                    if SubList == nil then NewList
                    else {Reverse SubList}|NewList end
                [] H|T then
                    if {Function.findPrefix_InList T Delimiter} == true then
                        if SubList == nil then {Split_List_Delimiter_Aux {Function.remove_List_FirstNthElements T Length_Delimiter} nil NewList}
                        else
                            {Split_List_Delimiter_Aux {Function.remove_List_FirstNthElements T Length_Delimiter} nil {Parser.cleaning_UnNecessary_Spaces {Reverse SubList}}|NewList}
                        end
                    else
                        {Split_List_Delimiter_Aux T H|SubList NewList}
                    end
                end
            end
        in
            {Reverse {Split_List_Delimiter_Aux List nil nil}}
        end
    end 
     

    %%%
    % Get all the N words before the word writed by the user.
    % The result is a list because the user can write a sentence with the word writed multiple times.
    %
    % Example usage:
    % In: "i have been there yeah. we all have been."    "been"
    % Out: ["i have" "all have"]
    %
    % @param: Word_User: word writed by the user.
    % @return: the list of all the N words before the word writed by the user.
    %%%
    fun {Get_List_All_N_Words_Before Word_User}

        local
            Contents
            List_Without_Words_User
            Length_List
            fun {Get_List_All_N_Words_Before_Aux List Last_Word Before_Last_Word NewList}
                case List
                of nil then NewList
                [] H|nil then
                    if H == Word_User then {Reverse {Function.append_List Before_Last_Word 32|Last_Word}|NewList}
                    else {Reverse NewList} end
                [] H|T then
                    if H == Word_User then {Get_List_All_N_Words_Before_Aux T H Last_Word {Function.append_List Before_Last_Word 32|Last_Word}|NewList}
                    else {Get_List_All_N_Words_Before_Aux T H Last_Word NewList} end
                end
            end
        in
            Contents = {Variables.inputText get($)}
            List_Without_Words_User = {Split_List_Delimiter {Parser.cleaningUserInput Contents} Word_User}
            if List_Without_Words_User == nil then nil
            else
                Length_List = {Length List_Without_Words_User.1}
                if Length_List == 1 then nil
                else {Get_List_All_N_Words_Before_Aux List_Without_Words_User.1 nil nil nil} end
            end
        end
    end


    %%%
    % Display the results of the correction.
    %
    % @param: List_Keys: list of all the N words before the word writed by the user.
    % @param: Word_To_Correct: word writed by the user.
    % @return: /
    %%%
    proc {DisplayResults List_Keys Word_To_Correct}
        local
            proc {DisplayResults_Aux List_Keys Idx}
                case List_Keys
                of nil then skip
                [] H|T then
                    local Tree_Value Prediction_Result BestWords Probability Frequency Str_Line_Not_Cleaned Str_Line Second_Str Third_Str Total_Str in
                        Tree_Value = {Tree.lookingUp {Function.get_Last_Elem_Stream Variables.stream_Tree} {String.toAtom H}}
                        if Tree_Value == notfound then
                            {Interface.insertText_Window Variables.outputText Idx 0 'end' {Function.append_List {Function.append_List "Correction " {Int.toString Idx+1}} ": No words found.\n"}}
                            {DisplayResults_Aux T Idx+1}
                        else
                            Prediction_Result = {Tree.get_Result_Prediction Tree_Value none}
                            BestWords = Prediction_Result.1
                            Probability = Prediction_Result.2.1
                            Frequency = Prediction_Result.2.2.1

                            if {Length BestWords} > 1 then
                                Str_Line_Not_Cleaned = {Predict_All.proposeAllTheWords BestWords _ _ false}
                                Str_Line = {Function.splitList_AtIdx Str_Line_Not_Cleaned {Length Str_Line_Not_Cleaned}-1}.1
                                Second_Str = {Function.append_List " (frequency : " {Int.toString Frequency}}
                                Third_Str = {Function.append_List {Function.append_List " and probability : " {Float.toString Probability}} ")\n"}
                                Total_Str = {Function.append_List Str_Line {Function.append_List Second_Str Third_Str}}
                                {Interface.insertText_Window Variables.outputText Idx 0 'end' {Function.append_List {Function.append_List "Correction " {Int.toString Idx+1}} {Function.append_List " : " Total_Str}}}
                            else
                                if BestWords.1 == Word_To_Correct then
                                    {Interface.insertText_Window Variables.outputText Idx 0 'end' {Function.append_List {Function.append_List "Correction " {Int.toString Idx+1}} ": your word is correct.\n"}}
                                else
                                    Str_Line = {Atom.toString BestWords.1}
                                    Second_Str = {Function.append_List " (frequency : " {Int.toString Frequency}}
                                    Third_Str = {Function.append_List {Function.append_List " and probability : " {Float.toString Probability}} ")\n"}
                                    Total_Str = {Function.append_List Str_Line {Function.append_List Second_Str Third_Str}}
                                    {Interface.insertText_Window Variables.outputText Idx 0 'end' {Function.append_List {Function.append_List "Correction " {Int.toString Idx+1}} {Function.append_List " : " Total_Str}}}
                                end
                            end
                            {DisplayResults_Aux T Idx+1}
                        end
                    end
                end
            end
        in
            {Interface.setText_Window Variables.outputText ""}
            if List_Keys == nil then {Interface.insertText_Window Variables.outputText 0 0 none "Correction : No words found."}
            else {DisplayResults_Aux List_Keys 0} end
        end
    end

end