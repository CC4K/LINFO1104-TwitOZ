functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
    OS
    System
    
    Variables at '../variables.ozf'
    Function at '../function.ozf'
export
    N_Grams
define
    

    %%%
    % Return the list of all the n-grams of the text.
    % The text is a list of words.
    %
    % Example usage:
    % In1: ['the' 'most' 'probable' 'word'] 2
    % Out1: [['the' 'most'] ['most' 'probable'] ['probable' 'word']]
    % In2: ['the' 'most' 'probable' 'word' 'yes'] 3
    % Out2: [['the' 'most' 'probable'] ['most' 'probable' 'word'] ['probable' 'word' 'yes']]
    %
    % @param List_Words: The list of words (text)
    % @param N: a positive integer representing the prefixe of N-gramme
    %           (= size of each element of the n-grams list)
    % @return: The list of all the n-grams of the text.
    fun {N_Grams List_N_Grams}
        local
            fun {N_Grams_Aux List_N_Grams NewList}
                case List_N_Grams
                of nil then {Reverse NewList}
                [] H|T then
                    local SplittedList = {Function.splitList_AtIdx T Variables.idx_N_Grams-1} in
                        if SplittedList == none then {Reverse NewList}
                        else {N_Grams_Aux T {Function.concatenateElemOfList H|SplittedList.1 32}|NewList} end
                    end
                end
            end
        in
            {N_Grams_Aux List_N_Grams nil}
        end
    end
end