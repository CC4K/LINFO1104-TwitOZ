functor
export
    parsealllines:ParseAllLines
    removeemptyspace:RemoveEmptySpace
    parseline:ParseLine
define

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
        case List
        of nil then nil
        [] H|T then
            {Parser H} | {ParseAllLines T Parser}
        end
    end

    %%%
    % Removes the last element of the string if it's a space (" " = 32 in ASCII code)
    %
    % Example usage:
    % In1: "Test de la fonction"
    % In2: "Test de la fonction "
    % Out1 = Out2: "Test de la fonction"
    %
    % @param Line: the input string to be processed
    % @return: a new string without the last element if it's a space,
    %          or the original string if the last element is not a space
    %%%
    fun {RemoveLastElemIfSpace Line}
        case Line
        of nil then nil
        [] H|nil then
            if H == 32 then nil
            else H | nil end
        [] H|T then
            H | {RemoveLastElemIfSpace T}
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
            fun {RemoveEmptySpaceAux Line PreviousSpace}
                case Line
                of nil then nil
                [] H|nil then
                    if H == 32 then nil
                    else H|nil end
                [] H|T then
                    if H == 32 then
                        if PreviousSpace == true then
                            {RemoveEmptySpaceAux T true}
                        else
                            H|{RemoveEmptySpaceAux T true}
                        end
                    else
                        H|{RemoveEmptySpaceAux T false}
                    end
                end
            end
        in
            CleanLine = {RemoveEmptySpaceAux Line true}
            {RemoveLastElemIfSpace CleanLine}
        end
    end

    %%%
    % Replaces special characters with spaces (== 32 in ASCII) and sets all letters to lowercase
    % Digits are left untouched
    %
    % Example usage:
    % In: "FLATTENING of the CURVE! 888 IS a GoOd DIgit..#/!"
    % Out: "flattening of the curve  888 is a good digit     "
    %
    % @param Line: a string to be parsed
    % @return: a parsed string without any special characters or capital letters
    %%%
    fun {ParseLine Line}
        case Line
        of H|T then
            local New_H in
                if 97 =< H andthen H =< 122 then
                    New_H = H
                elseif 65 =< H andthen H =< 90 then
                    New_H = H + 32
                elseif 48 =< H andthen H =< 57 then
                    New_H = H
                else
                    New_H = 32
                end
                New_H | {ParseLine T}
            end
        [] nil then nil
        end
    end

end