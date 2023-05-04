functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
    OS
    System
    
    Variables at '../variables.ozf'
    Function at '../function.ozf'
    Interface at '../interface.ozf'
    Parser at '../parser.ozf'
    Tree at '../tree.ozf'
    Predict_All at 'predict_All.ozf'
export
    CorrectionSentences
define

    %% WORD USER DONT KNOW HOW TO Have it with the window %%
    %% Il faudra aussi stoper le Thread qui predis automatiquement! %%
    proc {CorrectionSentences Word_User}
        local List_Keys in
            List_Keys = {Get_List_All_N_Words_Before Word_User}
            {DisplayResults List_Keys}
        end
    end

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
     

    fun {Get_List_All_N_Words_Before Word_User}

        local
            fun {Get_List_All_N_Words_Before_Aux List NewList}
                case List
                of nil then nil
                [] _|nil then nil
                [] H|T then
                    if T.2 == nil then
                        {Reverse {Get_Last_Nth_Word_List List_Words Nth}|NewList}
                    else
                        {Get_List_All_N_Words_Before_Aux T {Get_Last_Nth_Word_List List_Words Nth}|NewList}
                    end
                end
            end
        in
            Contents = {Variables.inputText get($)}
            List_Without_Words_User = {Split_List_Delimiter Contents Word_User}
            Length_List = {Length List_Without_Words_User}

            if Length_List == 1 then nil
            else {Get_List_All_N_Words_Before_Aux List_Without_Words_User nil} end
        end
    end

    proc {DisplayResults List_Keys}
        local
            proc {DisplayResults_Aux List_Keys Idx}
                case List_Keys
                of nil then skip
                [] H|T then
                    local Tree_Value Prediction_Result BestWords Probability Frequency Str_Line_Not_Cleaned Str_Line Second_Str Third_Str Total_Str in
                        Tree_Value = {Tree.lookingUp {String.toAtom H}}
                        if Tree_Value == notfound then {Interface.insertText_Window Variables.outputText Idx 0 none {Function.append_List {Function.append_List "Correction " {Int.toString Idx}} ": No words found."}}
                        else
                            Prediction_Result = {Tree.get_Result_Prediction Tree_Value}
                            BestWords = Prediction_Result.1
                            Probability = Prediction_Result.2.1
                            Frequency = Prediction_Result.2.2.1

                            if {Length BestWords} > 1 then
                                Str_Line_Not_Cleaned = {ProposeAllTheWords_Aux BestWords 12+{Length {Int.toString Idx}} _ _ true}
                                Str_Line = {SplitList_AtIdx Str_Line_Not_Cleaned {Length Str_Line_Not_Cleaned}-2}.1
                            else
                                Str_Line = {Atom.toString BestWords}
                            end

                            Second_Str = {Function.append_List " (frequency : " {Int.toString Frequency}}
                            Third_Str = {Function.append_List {Function.append_List "and probability : " {Float.toString Probability}} ")\n"}

                            Total_Str = {List.append_List Str_Line {List.append_List Second_Str Third_Str}}
                            {Interface.setText_Window Variables.outputText ""}
                            {Interface.insertText_Window Variables.outputText Idx 0 none {Function.append_List {Function.append_List "Correction " {Int.toString Idx}} {Function.append_List " : " Total_Str}}}
                        end
                    end
                end
            end
        in
            {DisplayResults_Aux List_Keys 0}
        end
    end

end