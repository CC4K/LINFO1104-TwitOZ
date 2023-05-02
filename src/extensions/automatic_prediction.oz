functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
    OS
    System
    
    Variables at 'variables.ozf'
    Function at 'function.ozf'
    Interface at 'interface.ozf'
    Parser at 'parser.ozf'
    Tree at 'tree.ozf'
    Predict_All at 'predict_All.ozf'
export
    Automatic_Prediction
define

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% PREDICTION AUTOMATIQUE %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    proc {Automatic_Prediction Time_Delay}
        local
            User_Input Splitted_Text List_Words Length_Splitted_Text First_Key Second_Key Value_Tree Value_Tree2 ResultPress ProbableWords Probability Frequency
            proc {Automatic_Prediction_Aux}
                User_Input = {Variables.inputText getText(p(1 0) 'end' $)}
                Splitted_Text = {Parser.cleaningUserInput User_Input}
                Length_Splitted_Text = {Length Splitted_Text}

                if Length_Splitted_Text == Variables.idx_N_Grams then
                    List_Words = Splitted_Text
                else
                    List_Words = {Function.get_Last_Nth_Word_List Splitted_Text Variables.idx_N_Grams+1}
                end

                if Length_Splitted_Text < Variables.idx_N_Grams then {Interface.insertText_Window Variables.outputText 1 0 none {Append "Need at least " {Append {Int.toString Variables.idx_N_Grams} " words to predict the next one."}}}
                else
                    if Length_Splitted_Text == Variables.idx_N_Grams then
                        First_Key = {Function.concatenateElemOfList List_Words 32}
                        Value_Tree = {Tree.lookingUp {Function.get_Tree} {String.toAtom First_Key} none}
                        if Value_Tree == notfound then {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                        else
                            ResultPress = {Tree.get_Result_Prediction Value_Tree}
                            ProbableWords = ResultPress.1
                            Probability = ResultPress.2.1
                            Frequency = ResultPress.2.2.1

                            if ProbableWords == nil then {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                            else {Predict_All.proposeAllTheWords ProbableWords Frequency Probability} end
                        end           
                    else
                        First_Key = {Function.concatenateElemOfList List_Words.2 32}
                        Second_Key = {Function.concatenateElemOfList List_Words 32}

                        Value_Tree = {Tree.lookingUp {Function.get_Tree} {String.toAtom First_Key} none}
                        if Value_Tree == notfound then
                            Value_Tree2 = {Tree.lookingUp {Function.get_Tree} {String.toAtom Second_Key} none}
                            if Value_Tree2 == notfound then

                                {Tree.lookingUp {Function.get_Tree} {String.toAtom Second_Key} {Reverse First_Key.1}}
                                %%TODO
                                %% Need to search with the letters
                                %%TODO
                                {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                            else
                                ResultPress = {Tree.get_Result_Prediction Value_Tree2}
                                ProbableWords = ResultPress.1
                                Probability = ResultPress.2.1
                                Frequency = ResultPress.2.2.1

                                if ProbableWords == nil then {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                                else {Predict_All.proposeAllTheWords ProbableWords Frequency Probability} end
                            end
                        else
                            ResultPress = {Tree.get_Result_Prediction Value_Tree}
                            ProbableWords = ResultPress.1
                            Probability = ResultPress.2.1
                            Frequency = ResultPress.2.2.1

                            if ProbableWords == nil then {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                            else {Predict_All.proposeAllTheWords ProbableWords Frequency Probability} end
                        end
                    end
                end
            end
        in
            % Infinite loop
            {Interface.setText_Window Variables.outputText ""}
            {Automatic_Prediction_Aux}
            {Time.delay Time_Delay}
            {Automatic_Prediction Time_Delay}
        end
    end

    fun {RemoveLastCharOfLastWord List_Words}
        local
            fun {RemoveLastChar Word}
                local
                    fun {RemoveLastChar_Aux Word NewWord}
                        case Word
                        of nil then nil
                        [] H|nil then {Reverse NewWord}
                        [] H|T then {RemoveLastChar_Aux T H|NewWord}
                        end
                    end
                in
                    {RemoveLastChar_Aux Word nil}
                end
            end

            fun {RemoveLastCharOfLastWord_Aux List_Words NewList}
                case List_Words
                of nil then nil
                [] H|nil then {Reverse {RemoveLastChar H}|NewList}
                [] H|T then {RemoveLastCharOfLastWord_Aux T H|NewList}
                end
            end
        in
            {RemoveLastCharOfLastWord_Aux List_Words nil}
        end
    end

end