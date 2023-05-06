functor
import
    Variables at '../variables.ozf'
    Function at '../function.ozf'
export
    N_grams % Get the list of all the n-grams of the text.
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
    fun {N_grams List_N_grams}
        local
            fun {N_grams_Aux List_N_grams NewList}
                case List_N_grams
                of nil then {Reverse NewList}
                [] H|T then
                    local SplittedList = {Function.splitList_AtIdx T Variables.idx_N_grams-1} in
                        if SplittedList == none then {Reverse NewList}
                        else {N_grams_Aux T {Function.concatenateElemOfList H|SplittedList.1 32}|NewList} end
                    end
                end
            end
        in
            {N_grams_Aux List_N_grams nil}
        end
    end
    
end