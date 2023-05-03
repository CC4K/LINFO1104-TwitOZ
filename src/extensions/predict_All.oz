functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
    OS
    System
    
    Variables at '../variables.ozf'
    Interface at '../interface.ozf'
    Function at '../function.ozf'
    Automatic_Prediction at 'automatic_prediction.ozf'
export
    ProposeAllTheWords
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
            if {Automatic_Prediction.checkIfSamePrediction List_MostProbableWords Frequency Probability} == true then skip
            else
                {Interface.setText_Window Variables.outputText ""}
                {Interface.setText_Window Variables.outputText "The most probable word(s) : ["}
                {ProposeAllTheWords_Aux List_MostProbableWords 30}
                {DisplayFreq_And_Probability 2 Frequency Probability}
                {Automatic_Prediction.stockResultsInFile List_MostProbableWords Frequency Probability}
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