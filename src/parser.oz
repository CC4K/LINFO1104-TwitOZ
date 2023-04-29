functor
import
    Function at 'function.ozf'
export
    CleanUp
    CleaningUserInput
    ParseInputUser
    RemoveEmptySpace
    RemovePartList
    ParseLine
    ParseAllLines
define

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%% FUNCTIONS TO CLEAN THE FILES OF THE DATABASE %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%
    % Remove a specified sublist from a given list
    %
    % Example usage:
    % In1: "Jeui ui suis okuiui et je suis louisuiuiuiui" "ui" true
    % Out1: "Jes oket je s lo"
    % In2: "    Je suis   ok  et je  suis louis    " [32] false
    % Out2: "Je suis ok et je suis louis"
    %
    % @param SubList: a list from which to remove the specified sublist
    % @param Length_SubList: the sublist to remove from the 'List'
    % @param NextCharRemoveToo: boolean indicating whether to remove the next character
    %                           after the substring if it is found in the 'List'
    % @return: a new list with all instances of the specified sublist removed
    %          (and their next character too if 'removeNextChar' is set to true)
    %%%
    fun {RemovePartList List SubList Replacer NextCharRemoveToo}
        local
            Length_SubList
            fun {RemovePartList_Aux List NewList Length_List}
                if Length_List < Length_SubList then NewList
                elseif List == nil then NewList
                else
                    local List_Updated NewList_Updated Length_List_Updated in
                        if {Function.findPrefix_InList List SubList} == true then
                            if NextCharRemoveToo == true then
                                List_Updated = {Function.remove_List_FirstNthElements List Length_SubList+1}
                                Length_List_Updated = Length_List - (Length_SubList + 1)
                                % 153 => = ' special not the basic => basic one is 39
                                if {Function.nth_List List Length_SubList+1} == 153 then
                                    NewList_Updated = 39 | NewList
                                else
                                    NewList_Updated = 32 | NewList
                                end
                            else
                                if Replacer == none then
                                    NewList_Updated = 32 | NewList
                                else
                                    NewList_Updated = NewList
                                end
                                List_Updated = {Function.remove_List_FirstNthElements List Length_SubList}
                                Length_List_Updated = Length_List - Length_SubList
                            end
                        else
                            List_Updated = List.2
                            NewList_Updated = List.1 | NewList
                            Length_List_Updated = Length_List
                        end

                        {RemovePartList_Aux List_Updated NewList_Updated Length_List_Updated}
                    end
                end
            end
        in
            Length_SubList = {Length SubList}
            {Reverse {RemovePartList_Aux List nil {Length List}}}
        end
    end

    %%%
    % Applies a cleaning function to a string
    %
    % Example usage:
    % If Cleaner = fun {$ LineStr} {RemovePartList LineStr [226 128] 32 true} end
    %   In1: "Jeui ui suis okuiui et je suis louisuiuiuiui" "ui" true
    %   Out1: "Jes oket je s lo"
    %   In2: "    Je suis   ok  et je  suis louis    " " " false
    %   Out2: "Je suis ok et je suis louis"
    %
    % @param LineStr: a string to be cleaned
    % @param Cleaner: a function that takes as input a string and returns a cleaned string
    % @return: a new string that has been cleaned by the function 'Cleaner'
    %%%
    fun {CleanUp LineStr Cleaner}
        {Cleaner LineStr}
    end

    %%%
    % Applies a parsing function to each string in a list of strings
    %
    % Example usage:
    % In: ["  _&Hello there...! General Kenobi!!! %100 "]
    % Out: ["hello there general kenobi 100"] if Parser = fun {$ StrLine} {RemoveEmptySpace {ParseLine Str_Line}} end
    %
    % @param List: a list of strings
    % @param Parser: a function that takes a string as input and returns a parsed version of it
    % @return: a list of the parsed strings
    %%%
    fun {ParseAllLines List Parser}
        local
            fun {ParseAllLines_Aux List Parser NewList}
                case List
                of nil then NewList
                [] H|T then
                    % {Browse {String.toAtom {Parser H}}}
                    % {Browse {String.toAtom H}}
                    local ParsedLine in
                        ParsedLine = {Parser H}
                        % nil represent the empty atom like this : ''.
                        % Useless because false the result of prediction.
                        % Remove it.
                        if ParsedLine == nil then
                            {ParseAllLines_Aux T Parser NewList}
                        else
                            {ParseAllLines_Aux T Parser ParsedLine|NewList}
                        end
                    end
                end
            end
        in
            {ParseAllLines_Aux List Parser nil}
        end
    end
    
    %%%
    % Removes any space larger than one character wide (and therefore useless)
    %
    % Example usage:
    % In: "  general    kenobi       you are a           bold   one   "
    % Out: "general kenobi you are a bold one"
    %
    % @param Line: a string to be cleaned of unnecessary spaces.
    % @return: a new string with all excess spaces removed
    %%%
    fun {RemoveEmptySpace Line}
        local
            CleanLine
            fun {RemoveEmptySpace_Aux Line NewLine PreviousSpace}
                case Line
                of nil then NewLine
                [] H|nil then
                    if H == 32 then NewLine
                    else H|NewLine end
                [] H|T then
                    if H == 32 then
                        if PreviousSpace == true then
                            {RemoveEmptySpace_Aux T NewLine true}
                        else
                            
                            {RemoveEmptySpace_Aux T H|NewLine true}
                        end
                    else
                        {RemoveEmptySpace_Aux T H|NewLine false}
                    end
                end
            end
        in
            CleanLine = {RemoveEmptySpace_Aux Line nil true}
            if CleanLine == nil then nil
            else
                if CleanLine.1 == 32 then
                    {Reverse CleanLine.2}
                else    
                    {Reverse CleanLine}
                end
            end
        end
    end

    %%%
    % Replaces the character by an other
    % If the character is an uppercase letter => replaces it by its lowercase version
    % If the character is a digit letter => don't replace it
    % If the character is a lowercase letter => don't replace it
    % If the character is a special character (all the other case) => replaces it by a space (32 in ASCII code)
    % Returns too a boolean : false if the new character is a space, true otherwise
    %
    % Example usage:
    % In1: 99          In2: 69            In3: 57           In4: 42
    % Out1: [99 true]  Out2: [101 true]   Out3: [57 true]   Out4: [32 false]
    %
    % @param Char: a character (number in ASCII code)
    % @return: a list of length 2 : [the new character    the boolean]
    %%%
    fun {GetNewChar Char}
        local New_Char Bool in
            if 97 =< Char andthen Char =< 122 then
                New_Char = Char 
                Bool = true
            elseif 48 =< Char andthen Char =< 57 then
                New_Char = Char 
                Bool = true
            elseif 65 =< Char andthen Char =< 90 then
                New_Char = Char + 32
                Bool = true
            else
                New_Char = 32 
                Bool = false
            end
            [New_Char Bool]
        end
    end

    %%%
    % Replaces special characters with spaces (== 32 in ASCII) and sets all letters to lowercase
    % Digits are left untouched

    % Example usage:
    % In: "FLATTENING of the CURVE! 888 IS a GoOd DIgit..#/!"
    % Out: "flattening of the curve  888 is a good digit     "
    %
    % @param Line: a string to be parsed
    % @return: a parsed string without any special characters or capital letters
    %%%
    fun {ParseLine Line PreviousGoodChar}
        local
            fun {ParseLine_Aux Line NewLine PreviousGoodChar}
                case Line
                of H|T then
                    local New_H Bool Next_Line Result_GetNewChar in
                        % 39 is the character ' => keep it only if the previous and the future
                        % character is a letter or a digit (not a special character!)

                        Next_Line = T
                        if H == 39 andthen PreviousGoodChar == true then
                            if T \= nil then
                                if T.1 == {GetNewChar T.1}.1 then
                                    New_H = H
                                    Bool = true
                                else
                                    New_H = 32
                                    Bool = false
                                end
                            else
                                New_H = 32
                                Bool = false
                            end
                        else
                            Result_GetNewChar = {GetNewChar H}
                            New_H = Result_GetNewChar.1
                            Bool = Result_GetNewChar.2.1
                        end
                        {ParseLine_Aux Next_Line New_H|NewLine Bool}
                    end
                [] nil then NewLine
                end
            end
        in
            {Reverse {ParseLine_Aux Line nil PreviousGoodChar}}
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%% FUNCTIONS TO CLEAN THE INPUT OF THE USER %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%
    % Parses the input of the user to set all the upercase letters to its lowercase letters.
    %
    % Example usage:
    % In1: "I aM"   In2: "you know"  In3: "WOW MAN"
    % Out2: "i am"  In2: "you know"  In3: "wow man" 
    %
    % @param Str_Line: a string (the input user) to be parsed
    % @return: the string parsed
    %%%
    fun {ParseInputUser Str_Line}
        local
            fun {ParseCharUser Char}
                local New_Char in
                    New_Char = {GetNewChar Char}.1
                    if New_Char == 32 then Char
                    else New_Char end
                end
            end

            fun {ParseInputUser_Aux Str_Line NewLine}
                case Str_Line
                of nil then NewLine
                [] H|T then
                    {ParseInputUser_Aux T {ParseCharUser H}|NewLine}
                end
            end
        in
            {Reverse {ParseInputUser_Aux Str_Line nil}}
        end
    end

    %%%
    % Removes all the "\n" character and the unnecessary " " character.
    %
    % Example usage:
    % In: ["hello       i am  okay 
    %      " "  you are   nice    "]
    % Out: ["hello i am okay" "you are nice"]
    %
    % @param SplittedText: a list of strings to be parsed
    % return: the new list with all the string parsed.
    %%%
    fun {CleaningUserInput SplittedText}
        local
            fun {CleaningUserInput_Aux SplittedText NewSplittedText}
                case SplittedText
                of nil then {Filter NewSplittedText fun {$ X} X \= nil end}
                [] H|T then
                    {CleaningUserInput_Aux T {CleanUp H fun {$ X} {RemoveEmptySpace {RemovePartList X [10] 32 false}} end}|NewSplittedText}
                end
            end
        in 
            {Reverse {CleaningUserInput_Aux SplittedText nil}}
        end
    end

end