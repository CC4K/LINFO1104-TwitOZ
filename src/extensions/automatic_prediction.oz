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
    Automatic_Prediction
define

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% PREDICTION AUTOMATIQUE %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    proc {Automatic_Prediction Time_Delay}
        local
            User_Input Splitted_Text List_Words Length_Splitted_Text First_Key Second_Key Value_Tree Value_Tree2 ResultPress ProbableWords Probability Frequency
            proc {Automatic_Prediction_Aux}

                % Get user input, clean it and split it
                User_Input = {Variables.inputText getText(p(1 0) 'end' $)}
                Splitted_Text = {Parser.cleaningUserInput User_Input}
                Length_Splitted_Text = {Length Splitted_Text}

                % Get the last N words into 'List_Words'
                if Length_Splitted_Text == Variables.idx_N_Grams then
                    List_Words = Splitted_Text
                else
                    List_Words = {Function.get_Last_Nth_Word_List Splitted_Text Variables.idx_N_Grams+1}
                end

                % If there isn't enough words
                if Length_Splitted_Text < Variables.idx_N_Grams then {Interface.insertText_Window Variables.outputText 1 0 none {Append "Need at least " {Append {Int.toString Variables.idx_N_Grams} " words to predict the next one."}}}
                else % If there is enough words

                    % If there is only N words
                    if Length_Splitted_Text == Variables.idx_N_Grams then

                        % Get the only key (all the words concatenated) and the subtree associated
                        First_Key = {Function.concatenateElemOfList List_Words 32}
                        Value_Tree = {Tree.lookingUp {Function.get_Tree} {String.toAtom First_Key}}

                        % If the key is not found
                        if Value_Tree == notfound then {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                        else % If the key is found

                            % Get the result of the prediction
                            ResultPress = {Tree.get_Result_Prediction Value_Tree none}
                            ProbableWords = ResultPress.1
                            Probability = ResultPress.2.1
                            Frequency = ResultPress.2.2.1

                            % Predict and display the result
                            if ProbableWords == nil then {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                            else {Predict_All.proposeAllTheWords ProbableWords Frequency Probability} end
                        end           
                    else % If there is more than N words

                        % Example with N = 4:
                        % List_Words = [i am a student that] => First_Key = [am a student that]
                        %                                       Second_Key = [i am a student]
                        First_Key = {Function.concatenateElemOfList List_Words.2 32}
                        Second_Key = {Function.concatenateElemOfList {RemoveLastValue List_Words} 32}

                        % Get the subtree associated to the first key
                        Value_Tree = {Tree.lookingUp {Function.get_Tree} {String.toAtom First_Key}}

                        {System.show {String.toAtom First_Key}}
                        {System.show Value_Tree}

                        % If the first key is not found
                        if Value_Tree == notfound then
                            
                            % Get the subtree associated to the second key
                            Value_Tree2 = {Tree.lookingUp {Function.get_Tree} {String.toAtom Second_Key}}

                            if Value_Tree2 == notfound then {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                            else

                                ResultPress = {Tree.get_Result_Prediction Value_Tree2 {Reverse List_Words.2}.1}
                                ProbableWords = ResultPress.1

                                if ProbableWords == nil then {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                                else
                                    Probability = ResultPress.2.1
                                    Frequency = ResultPress.2.2.1

                                    {Predict_All.proposeAllTheWords ProbableWords Frequency Probability}
                                end
                            end
                        else % If the first key is found

                            ResultPress = {Tree.get_Result_Prediction Value_Tree none}
                            ProbableWords = ResultPress.1
                            Probability = ResultPress.2.1
                            Frequency = ResultPress.2.2.1

                            % Predict and display the result
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

    % fun {Get_And_Display_Results Value_Tree}
    %     0
    % end


    fun {RemoveLastValue List}
        local
            fun {RemoveLastValue_Aux List NewList}
                case List
                of nil then NewList
                [] H|nil then NewList
                [] H|T then
                    {RemoveLastValue_Aux T H|NewList}
                end
            end
        in
            {Reverse {RemoveLastValue_Aux List nil}}
        end
    end
end