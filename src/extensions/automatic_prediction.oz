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
                            ResultPress = {Tree.get_Result_Prediction Value_Tree}
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

                        % If the first key is not found
                        if Value_Tree == notfound then
                            
                            % Get the subtree associated to the second key
                            Value_Tree2 = {LookingUp_Extensions {Function.get_Tree} {String.toAtom Second_Key} {Reverse List_Words}.1}
                            % If the second key is not found
                            if Value_Tree2 == notfound then

                                % Display that no word has been found
                                {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}

                            else % If the second key is found

                                ResultPress = {Tree.get_Result_Prediction Value_Tree2}
                                ProbableWords = ResultPress.1
                                Probability = ResultPress.2.1
                                Frequency = ResultPress.2.2.1

                                % Predict and display the result
                                if ProbableWords == nil then {Interface.insertText_Window Variables.outputText 1 0 none "Words not found."}
                                else {Predict_All.proposeAllTheWords ProbableWords Frequency Probability} end
                            end
                        else % If the first key is found

                            ResultPress = {Tree.get_Result_Prediction Value_Tree}
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

    fun {Get_And_Display_Results Value_Tree}
        0
    end

    fun {LookingUp_Extensions Tree Key Prefix_Value}
        local
            fun {LookingUp_Extensions_Aux Tree Key ValueToReturn}
                case Tree
                of leaf then ValueToReturn
                [] tree(key:K value:V t_left:_ t_right:_) andthen K == Key then
                    local BestWord in
                        BestWord = {SearchPrefixValue V Prefix_Value}
                        if BestWord == notfound then notfound
                        else BestWord end
                    end

                [] tree(key:K value:V t_left:TLeft t_right:_) andthen K > Key then
                    local BestWord in
                        BestWord = {SearchPrefixValue V Prefix_Value}
                        if BestWord == notfound then {LookingUp_Extensions_Aux TLeft Key ValueToReturn}
                        else {LookingUp_Extensions_Aux TLeft Key BestWord} end
                    end

                [] tree(key:K value:V t_left:_ t_right:TRight) andthen K < Key then
                    local BestWord in
                        BestWord = {SearchPrefixValue V Prefix_Value}
                        if BestWord == notfound then {LookingUp_Extensions_Aux TRight Key ValueToReturn}
                        else {LookingUp_Extensions_Aux TRight Key BestWord} end
                    end
                end
            end
        in
            {LookingUp_Extensions_Aux Tree Key notfound}
        end
    end

    fun {GetListWithPrefix List Prefix}
        local
            fun {GetListWithPrefix_Aux List NewList}
                case List
                of nil then NewList
                [] H|T then
                    {System.show {Atom.toString H}}
                    {System.show Prefix}
                    if {Function.findPrefix_InList {Atom.toString H} Prefix} == true then
                        {GetListWithPrefix_Aux T H|NewList}
                    else
                        {GetListWithPrefix_Aux T NewList}
                    end
                end
            end

        in
            {GetListWithPrefix_Aux List nil}
        end
    end

    fun {SearchPrefixValue SubTree Prefix_Value}
        local
            fun {SearchPrefixValue_Aux SubTree BestWord}
                case SubTree
                of leaf then BestWord
                [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
                    local T1 List_Words in
                        {System.show Prefix_Value}
                        {System.show Value}
                        List_Words = {GetListWithPrefix Value Prefix_Value}
                        {System.show List_Words}
                        if List_Words == nil then
                            T1 = {SearchPrefixValue_Aux TLeft BestWord}
                        else
                            T1 = {SearchPrefixValue_Aux TLeft List_Words}
                        end
                        _ = {SearchPrefixValue_Aux TRight BestWord}
                    end
                end
            end
        in
            {SearchPrefixValue_Aux SubTree notfound}
        end
    end

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