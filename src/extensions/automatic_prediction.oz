functor
import
    Application
    Open
    System
    
    Variables at '../variables.ozf'
    Function at '../function.ozf'
    Interface at '../interface.ozf'
    Parser at '../parser.ozf'
    Tree at '../tree.ozf'
    Predict_All at 'predict_All.ozf'
export
    Automatic_Prediction % To launch the automatic prediction
    StockResultsInFile % To stock the results of the prediction in a file
    Reset_LastPrediction_File % To reset the file of the last prediction to ""
define


    %%%
    % Automatic Prediction done by a thread.
    %
    % @param Time_Delay: the time between each prediction.
    % @return: /
    %%%
    proc {Automatic_Prediction Time_Delay}
        local
            Delay_Correction User_Input Splitted_Text List_Words Length_Splitted_Text First_Key Second_Key Value_Tree Value_Tree2 ResultPress ProbableWords Probability Frequency
            fun {Automatic_Prediction_Aux}

                % Get user input, clean it and split it
                User_Input = {Variables.inputText getText(p(1 0) 'end' $)}
                Splitted_Text = {Parser.cleaningUserInput User_Input}
                Length_Splitted_Text = {Length Splitted_Text}

                % Get the last N words into 'List_Words'
                if Length_Splitted_Text == Variables.idx_N_grams then
                    List_Words = Splitted_Text
                else
                    List_Words = {Function.get_Last_Nth_Word_List Splitted_Text Variables.idx_N_grams+1}
                end

                % If there isn't enough words
                if Length_Splitted_Text < Variables.idx_N_grams then
                    [none 0 0.0]
                else % If there is enough words

                    % If there is only N words
                    if Length_Splitted_Text == Variables.idx_N_grams then

                        % Get the only key (all the words concatenated) and the subtree associated
                        First_Key = {Function.concatenateElemOfList List_Words 32}
                        Value_Tree = {Tree.lookingUp {Function.get_Last_Elem_Stream Variables.stream_Tree} {String.toAtom First_Key}}

                        % If the key is not found
                        if Value_Tree == notfound then
                            [nil 0 0.0]
                        else % If the key is found

                            % Get the result of the prediction
                            ResultPress = {Tree.get_Result_Prediction Value_Tree none}
                            ProbableWords = ResultPress.1
                            Probability = ResultPress.2.1
                            Frequency = ResultPress.2.2.1

                            [ProbableWords Frequency Probability]
                        end           
                    else % If there is more than N words

                        % Example with N = 4:
                        % List_Words = [i am a student that] => First_Key = [am a student that]
                        %                                       Second_Key = [i am a student]
                        First_Key = {Function.concatenateElemOfList List_Words.2 32}
                        Second_Key = {Function.concatenateElemOfList {Function.removeLastValue List_Words} 32}

                        % Get the subtree associated to the first key
                        Value_Tree = {Tree.lookingUp {Function.get_Last_Elem_Stream Variables.stream_Tree} {String.toAtom First_Key}}

                        % If the first key is not found
                        if Value_Tree == notfound then
                            
                            % Get the subtree associated to the second key
                            Value_Tree2 = {Tree.lookingUp {Function.get_Last_Elem_Stream Variables.stream_Tree} {String.toAtom Second_Key}}

                            if Value_Tree2 == notfound then
                                [nil 0 0.0]
                            else

                                ResultPress = {Tree.get_Result_Prediction Value_Tree2 {Reverse List_Words.2}.1}
                                ProbableWords = ResultPress.1
                                Probability = ResultPress.2.1
                                Frequency = ResultPress.2.2.1

                                [ProbableWords Frequency Probability] 
                            end
                        else % If the first key is found
                            ResultPress = {Tree.get_Result_Prediction Value_Tree none}
                            ProbableWords = ResultPress.1
                            Probability = ResultPress.2.1
                            Frequency = ResultPress.2.2.1

                            [ProbableWords Frequency Probability]
                        end
                    end
                end
            end
        in
            if Variables.tree_Over == true then
                Delay_Correction = {Function.get_Last_Elem_Stream Variables.stream_Auto_Corr_Threads}
                if Delay_Correction \= 0 then
                    
                    {Time.delay Delay_Correction}
                    {Send Variables.port_Auto_Corr_Threads 0}

                    % Infinite loop
                    local ResultPrediction ProbableWords Frequency Probability in
                        ResultPrediction = {Automatic_Prediction_Aux}
                        ProbableWords = ResultPrediction.1
                        Frequency = ResultPrediction.2.1
                        Probability = ResultPrediction.2.2.1

                        if ProbableWords == nil then
                            {Interface.setText_Window Variables.outputText ""}
                            {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                            {StockResultsInFile nil 0 0.0}

                        elseif ProbableWords == none then
                            {Interface.setText_Window Variables.outputText ""}
                            {Interface.insertText_Window Variables.outputText 1 0 none {Append "Need at least " {Append {Int.toString Variables.idx_N_grams} " words to predict the next one."}}}
                            {StockResultsInFile none 0 0.0}

                        else _ = {Predict_All.proposeAllTheWords ProbableWords Frequency Probability true} end
                        {Automatic_Prediction Time_Delay}
                    end

                else
                    {Time.delay Time_Delay}

                    % Infinite loop
                    local ResultPrediction ProbableWords Frequency Probability in
                        ResultPrediction = {Automatic_Prediction_Aux}
                        ProbableWords = ResultPrediction.1
                        Frequency = ResultPrediction.2.1
                        Probability = ResultPrediction.2.2.1

                        if {CheckIfSamePrediction ProbableWords Frequency Probability} == true then
                            {Automatic_Prediction Time_Delay}
                        else
                            if ProbableWords == nil then
                                {Interface.setText_Window Variables.outputText ""}
                                {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                                {StockResultsInFile nil 0 0.0}

                            elseif ProbableWords == none then
                                {Interface.setText_Window Variables.outputText ""}
                                {Interface.insertText_Window Variables.outputText 1 0 none {Append "Need at least " {Append {Int.toString Variables.idx_N_grams} " words to predict the next one."}}}
                                {StockResultsInFile none 0 0.0}

                            else _ = {Predict_All.proposeAllTheWords ProbableWords Frequency Probability true} end
                            {Automatic_Prediction Time_Delay}
                        end
                    end
                end
            else
                {Time.delay Time_Delay}
                {Automatic_Prediction Time_Delay}
            end
        end
    end


    %%%
    % Stocks the results of the prediction in a file "user_historic/last_prediction.txt".
    % If the file doesn't exist, it is created.
    % If the file exists, it is truncated.
    %
    % @param ProbableWords: list of the probable words
    % @param Frequency: frequency of the prediction
    % @param Probability: probability of the prediction
    % @return: /
    %%%
    proc {StockResultsInFile ProbableWords Frequency Probability}
        try
            local Str_Prediction Path_LastPrediction_File in
                Str_Prediction = {CreateString_Prediction ProbableWords Frequency Probability}
                Path_LastPrediction_File = {New Open.file init(name:"user_historic/last_prediction.txt" flags:[write create truncate])}
                {Path_LastPrediction_File write(vs:Str_Prediction)}
                {Path_LastPrediction_File close}
            end
        catch _ then {System.show 'Error in StockResultsInFile function'} {Reset_LastPrediction_File} {Application.exit 0} end
    end


    %%%
    % Reset the file "user_historic/last_prediction.txt" to the number 0.
    %
    % @param: /
    % @return: /
    %%%
    proc {Reset_LastPrediction_File}
        local Path_LastPrediction_File in
            Path_LastPrediction_File = {New Open.file init(name:"user_historic/last_prediction.txt" flags:[write create truncate])}
            {Path_LastPrediction_File write(vs:"")} 
            {Path_LastPrediction_File close}
        end
    end


    %%%
    % Check if the prediction is the same as the last one.
    %
    % @param ProbableWords: list of the probable words
    % @param Frequency: frequency of the prediction
    % @param Probability: probability of the prediction
    % @return: true if the prediction is the same, false otherwise.
    %%%
    fun {CheckIfSamePrediction ProbableWords Frequency Probability}
        try
            local Path_LastPrediction_File Last_List_Prediction Max_Error Abs_Diff_Probability List_Words Str_Prediction in
                
                Path_LastPrediction_File = {New Open.file init(name:"user_historic/last_prediction.txt" flags:[read])}

                Str_Prediction = {Path_LastPrediction_File read(list:$ size:all)}

                if Str_Prediction == "0.0 0 none" then
                    if ProbableWords == none then
                        {Path_LastPrediction_File close}
                        true
                    else
                        {Path_LastPrediction_File close}
                        false
                    end
                elseif Str_Prediction == "0.0 0 nil" then
                    if ProbableWords == nil then
                        {Path_LastPrediction_File close}
                        true
                    else
                        {Path_LastPrediction_File close}
                        false
                    end
                else
                    % If the file is empty (= first prediction)
                    if Str_Prediction == "" then false
                    else
                        Last_List_Prediction = {Function.tokens_String Str_Prediction 32}

                        Max_Error = 0.000001
                        Abs_Diff_Probability = {Number.abs ~Probability+{String.toFloat Last_List_Prediction.1}}

                        % Compare if it's the same
                        if Frequency == {String.toInt Last_List_Prediction.2.1} andthen Abs_Diff_Probability < Max_Error then

                            List_Words  = {Map Last_List_Prediction.2.2 fun {$ X} {String.toAtom X} end}

                            if ProbableWords == none andthen Last_List_Prediction.1 == "none" then
                                {Path_LastPrediction_File close}
                                true
                            elseif {Length List_Words} == {Length ProbableWords} then
                                {Path_LastPrediction_File close}
                                {Function.compareList List_Words ProbableWords}
                            else
                                {Path_LastPrediction_File close}
                                false
                            end
                        else
                            {Path_LastPrediction_File close}
                            false
                        end
                    end
                end
            end
        catch _ then {System.show 'Error in CheckIfSamePrediction function'} {Application.exit 0} none end
    end

    %%%
    % Create a string representing the prediction.
    %
    % Example usage:
    % In: ['the' 'all' 'with'] 23 0.83763
    % Out: "23 0.83763 the all with"
    %
    % @param ProbableWords: list of the probable words
    % @param Frequency: frequency of the prediction
    % @param Probability: probability of the prediction
    % @return: string representing the prediction.
    %%%
    fun {CreateString_Prediction ProbableWords Frequency Probability}
        local
            fun {CreateList_Prediction_Aux ProbableWords NewList}
                case ProbableWords
                of nil then NewList
                [] H|T then
                    {CreateList_Prediction_Aux T {Atom.toString H}|NewList}
                end
            end
        in
            if ProbableWords == none then "0.0 0 none"
            elseif ProbableWords == nil then "0.0 0 nil"
            else {Function.concatenateElemOfList {Reverse {CreateList_Prediction_Aux ProbableWords [{Int.toString Frequency} {Float.toString Probability}]}} 32}
            end
        end
    end

end