functor
import
    Browser
export
    CleanUp ParseAllLines
define

    proc {Browse Buf}
        {Browser.browse Buf}
    end

    fun {GetListAfterNth List N}
        case List
        of nil then nil
        [] H|T then
            if N == 1 then T
            else
                {GetListAfterNth T N-1}
            end
        end
    end

    fun {FindDelimiter List Delimiter}
        case Delimiter
        of nil then true
        [] H|T then
            if List == nil then false
            else
                if H == List.1 then {FindDelimiter List.2 T}
                else false end
            end
        end
    end

    fun {RemovePartString Str Delimiter Length_Delimiter NextCharRemoveToo}
        local
            fun {RemovePartString_Aux Str Delimiter Length_Delimiter NextCharRemoveToo}
                case Str
                of nil then nil
                [] H|T then
                    if {FindDelimiter T Delimiter} == true then
                        if NextCharRemoveToo == true then
                            %%% Si on veut séparer comme ceci : "didn't" en "didn t" et pas en "didnt", il faut faire
                            %%% H|32|{RemovePartString_Aux {GetListAfterNth T Length_Delimiter+1} Delimiter Length_Delimiter NextCharRemoveToo}
                            %%% à la place de la ligne en-dessous
                            H|{RemovePartString_Aux {GetListAfterNth T Length_Delimiter+1} Delimiter Length_Delimiter NextCharRemoveToo}
                        else
                            H|{RemovePartString_Aux {GetListAfterNth T Length_Delimiter} Delimiter Length_Delimiter NextCharRemoveToo}
                        end
                    else
                        H|{RemovePartString_Aux T Delimiter Length_Delimiter NextCharRemoveToo}
                    end
                end
            end
        in
            if {FindDelimiter Str Delimiter} == true then
                if NextCharRemoveToo == true then
                    %%% Si on veut séparer comme ceci : "didn't" en "didn t" et pas en "didnt", il faut faire
                    %%% H|32|{RemovePartString {GetListAfterNth T Length_Delimiter+1} Delimiter Length_Delimiter NextCharRemoveToo}
                    %%% à la place de la ligne en-dessous
                    {RemovePartString_Aux {GetListAfterNth Str Length_Delimiter+1} Delimiter Length_Delimiter NextCharRemoveToo}
                else
                    {RemovePartString_Aux {GetListAfterNth Str Length_Delimiter} Delimiter Length_Delimiter NextCharRemoveToo}
                end
            else
                {RemovePartString_Aux Str Delimiter Length_Delimiter NextCharRemoveToo}
            end
        end
    end

    % Faudra aussi remove la lettre d'après car les délimiteur sont :
    % Delimiteur1 = "â\x80\x99" (représente ')
    % Delimiteur2 = "â\x80\x9C" (représente " d'un côté)
    % Delimiteur3 = "â\x80\x9D" (représente " de l'autre côté)
    fun {CleanUp LineStr}
        {RemovePartString LineStr [226 128] 2 true} % [226 128] représente "â\x80\x9" (trouvé après des tests)
    end

    %%%
    % Applies {ParseLine} parsing on all the lines in a list
    % In : ["Hello there!" "General Kenobi!!!"]
    % Out : ["hello there " "general kenobi "]
    %
    % @List : a list of strings/lines
    % @return : the input list with all its strings parsed
    %%%
    fun {ParseAllLines List}
        case List
        of nil then nil
        [] H|T then
            {RemoveEmptySpace {ParseLine H}}|{ParseAllLines T}
        end
    end

    fun {RemoveLastElemIfSpace Line}
        case Line
        of nil then nil
        [] H|nil then
            if H == 32 then nil
            else H|nil end
        [] H|T then
            H|{RemoveLastElemIfSpace T}
        end
    end
    
    %%%
    % Removes any space larger than one character wide (and therefore useless)
    % In : "general         kenobi      you are a           bold one"
    % Out : "general kenobi you are a bold one"
    %
    % @Line : a string/list of ASCII characters
    % @return : the input string trimmed from its excess spaces
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
    % Replaces special caracters by a space (== 32 in ASCII) and letters to lowercase
    % In : "FLATTENING OF THE CURVE!"
    % Out : "flattening of the curve "
    %
    % @Line : a string/list of ASCII characters
    % @return : a parsed string without any special characters or capital letters
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
                New_H|{ParseLine T}
            end
        [] nil then nil
        end
    end
    % {Browse {ParseLine "FLATTENING OF THE CURVE!"}} % "flattening of the curve "
end