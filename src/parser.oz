functor
import
    Function at 'function.ozf'
export
    CleaningUserInput % Cleans the user input
    Cleaning_UnNecessary_Spaces % Removes any space larger than one character wide (and therefore useless)
    Parses_AllLines % Parses all the lines of a file
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
    % @param Replacer: the character to replace the removed sublist with (if none, then the replaced character is a space)
    % @param NextCharRemoveToo: boolean indicating whether to remove the next character
    %                           after the substring if it is found in the 'List'
    % @return: a new list with all instances of the specified sublist removed
    %          (and their next character too if 'removeNextChar' is set to true)
    %%%
    fun {Removes_All_SubString List SubList Replacer NextCharRemoveToo}
        local
            Length_SubList = {Length SubList}
            Length_List = {Length List}

            %%%
            % Removes the substring from the list
            %%%
            fun {Remove_SubString List NewList}
                if NextCharRemoveToo == true then
                    % 153 => = ' special not the basic => basic one is 39 (to replace with 39)
                    if {Function.nth_List List Length_SubList+1} == 153 then
                        {Removes_All_SubString_Aux {Function.remove_List_FirstNthElements List Length_SubList+1} 39|NewList Length_List-(Length_SubList+1)}
                    else
                        if Replacer == none then {Removes_All_SubString_Aux {Function.remove_List_FirstNthElements List Length_SubList+1} 32|NewList Length_List-(Length_SubList+1)}
                        else {Removes_All_SubString_Aux {Function.remove_List_FirstNthElements List Length_SubList+1} Replacer|NewList Length_List-(Length_SubList+1)} end
                    end
                else
                    if Replacer == none then {Removes_All_SubString_Aux {Function.remove_List_FirstNthElements List Length_SubList} 32|NewList Length_List-Length_SubList}
                    else {Removes_All_SubString_Aux {Function.remove_List_FirstNthElements List Length_SubList} Replacer|NewList Length_List-Length_SubList} end
                end
            end
            
            %%%
            % Auxilliary function
            %%%
            fun {Removes_All_SubString_Aux List NewList Length_List}
                case List
                of nil then NewList
                [] H|T then
                    if {Function.findPrefix_InList List SubList} == true then
                        {Remove_SubString List NewList}
                    else
                        {Removes_All_SubString_Aux T H|NewList Length_List}
                    end
                end
            end
        in
            if Length_List < Length_SubList then nil
            else {Reverse {Removes_All_SubString_Aux List nil Length_List}} end
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
    fun {Cleaning_UnNecessary_Spaces Line}
        local
            CleanLine
            fun {Cleaning_UnNecessary_Spaces_Aux Line NewLine PreviousSpace}
                case Line
                of nil then NewLine
                [] H|nil then
                    if H == 32 then NewLine
                    else H|NewLine end
                [] H|T then
                    if H == 32 then
                        if PreviousSpace == true then {Cleaning_UnNecessary_Spaces_Aux T NewLine true}
                        else {Cleaning_UnNecessary_Spaces_Aux T H|NewLine true} end
                    else {Cleaning_UnNecessary_Spaces_Aux T H|NewLine false} end
                end
            end
        in
            CleanLine = {Cleaning_UnNecessary_Spaces_Aux Line nil true}
            if CleanLine == nil then nil
            else
                if CleanLine.1 == 32 then {Reverse CleanLine.2}
                else {Reverse CleanLine} end
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
        if 97 =< Char andthen Char =< 122 then [Char true]
        elseif 48 =< Char andthen Char =< 57 then [Char true]
        elseif 65 =< Char andthen Char =< 90 then [Char+32 true]
        else [32 false] end
    end

    %%%
    % Replaces special characters with spaces (== 32 in ASCII) and sets all letters to lowercase
    % Digits are left untouched.
    % Keep also the character 39 (') if it is between two letters or two digits.
    %
    % Example usage:
    % In: "FLATTENING of the CURVE! 888 IS a GoOd DIgit..#/! I can't believe it!"
    % Out: "flattening of the curve  888 is a good digit i can't believe it"
    %
    % @param Line: a string to be parsed
    % @return: a parsed string without any special characters or capital letters
    %%%
    fun {Parses_Line Line}
        local
            fun {Parses_Line_Aux Line NewLine Previous_Changed_Char}
                case Line
                of nil then {Reverse NewLine}
                [] H|nil then {Reverse {GetNewChar H}.1|NewLine}
                [] H|T then
                    % 39 is the character ' => keep it only if the previous and the future
                    % character is a letter or a digit (not a special character!)
                    if H == 39 andthen Previous_Changed_Char == true then          
                        if T.1 == {GetNewChar T.1}.1 then {Parses_Line_Aux T H|NewLine true}
                        else {Parses_Line_Aux T 32|NewLine false} end
                    else
                        local Result_GetNewChar = {GetNewChar H} in
                            {Parses_Line_Aux T Result_GetNewChar.1|NewLine Result_GetNewChar.2.1}
                        end
                    end
                end
            end
        in
            {Parses_Line_Aux Line nil false}
        end
    end


    %%%
    % Applies a parsing function to each string in a list of strings (to clean the string)
    %
    % Example usage:
    % In: ["  _&Hello there...! General Kenobi!!! %100 "]
    % Out: ["hello there general kenobi 100"]
    %
    % @param List: a list of strings
    % @return: a list of the parsed strings
    %%%
    fun {Parses_AllLines List}
        local
            % Function to parse a single line of the database
            Parser = fun {$ Line_Str} {Cleaning_UnNecessary_Spaces {Parses_Line {Removes_All_SubString Line_Str [226 128] 32 true}}} end
            fun {Parses_AllLines_Aux List NewList}
                case List
                of nil then NewList
                [] H|T then
                    local ParsedLine in
                        ParsedLine = {Parser H}
                        % nil represent the empty atom like this : ''.
                        % Useless because it false the result of a prediction.
                        % => Remove it.
                        if ParsedLine == nil then {Parses_AllLines_Aux T NewList}
                        else {Parses_AllLines_Aux T ParsedLine|NewList} end
                    end
                end
            end
        in
            {Parses_AllLines_Aux List nil}
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
            fun {ParseInputUser_Aux Str_Line NewLine}
                case Str_Line
                of nil then {Reverse NewLine}
                [] H|T then {ParseInputUser_Aux T {GetNewChar_User H}|NewLine} end
            end
        in
            {ParseInputUser_Aux Str_Line nil}
        end
    end

    %%%
    % Replaces the character by an other one parsed.
    % If the character is an uppercase letter => replaces it by its lowercase version
    % If the character is a special character (all the other case) => replaces it by a space (32 in ASCII code)
    % Keep also the character 39 (').
    %
    % Example usage:
    % In1: 99     In2: 69     In3: 57     In4: 42
    % Out1: 99    Out2: 101   Out3: 57    Out4: 32
    %
    % @param Char: a character (number in ASCII code)
    % @return: the new characte parsed.
    %%%
    fun {GetNewChar_User Char}
        % 39 is the character ' => keep it
        if Char == 39 then Char
        else {GetNewChar Char}.1 end
    end

    %%%
    % Removes all the "\n" character and the unnecessary " " character.
    %
    % Example usage:
    % In: "hello       i am  okay 
    %      " "  you are   nice    "
    % Out: ["hello i am okay" "you are nice"]
    %
    % @param SplittedText: a list of strings to be parsed
    % return: the new list with all the string parsed.
    %%%
    fun {CleaningUserInput Text_Line}
        local
            Cleaner = fun {$ Str_Line} {Cleaning_UnNecessary_Spaces {ParseInputUser Str_Line}} end
            fun {CleaningUserInput_Aux SplittedText NewSplittedText}
                case SplittedText
                of nil then {Filter NewSplittedText fun {$ X} X \= nil end}
                [] H|T then
                    {CleaningUserInput_Aux T {Cleaner H}|NewSplittedText}
                end
            end
        in
            {Reverse {CleaningUserInput_Aux {Function.tokens_String Text_Line 32} nil}}
        end
    end
    
end