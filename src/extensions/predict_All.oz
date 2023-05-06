functor
import    
    Variables at '../variables.ozf'
    Interface at '../interface.ozf'
    Function at '../function.ozf'
    Automatic_Prediction at 'automatic_prediction.ozf'
export
    ProposeAllTheWords % Propose all the most probable words (can me more than one)
define
    

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
    fun {ProposeAllTheWords List_MostProbableWords Frequency Probability Corr_auto}
        local
            Str_Line
            fun {ProposeAllTheWords_Aux List_MostProbableWords String_Associated}
                case List_MostProbableWords
                of nil then {Function.append_List String_Associated " ]\n"}
                [] H|T then
                    {ProposeAllTheWords_Aux T {Function.append_List String_Associated 32|{Atom.toString H}}}
                end
            end
        in
            {Interface.setText_Window Variables.outputText ""}

            if Corr_auto == true then
                Str_Line = {ProposeAllTheWords_Aux List_MostProbableWords "The most probable word(s) : ["}
                {Interface.insertText_Window Variables.outputText 0 0 none Str_Line}
                {DisplayFreq_And_Probability 2 Frequency Probability}
                {Automatic_Prediction.stockResultsInFile List_MostProbableWords Frequency Probability}
                Str_Line
            else
                {ProposeAllTheWords_Aux List_MostProbableWords "["}
            end
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

            {Interface.insertText_Window Variables.outputText Row 0 none {Function.append_List "The frequency of the/these word(s) is : " {Function.append_List Str_Frequency "\n"}}}
            {Interface.insertText_Window Variables.outputText Row+1 0 none {Function.append_List "The probability of the/these word(s) is : " Str_Probability}}
        end
    end

end