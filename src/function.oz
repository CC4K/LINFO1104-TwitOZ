functor
import
    Browser
    System
export
    Browse
    Append_List
    Nth_List
    Tokens_String
    Remove_List_FirstNthElements
    FindPrefix_InList
    Get_Last_Nth_Word_List
    Get_ListFromPortStream
    SplitList_AtIdx
    ConcatenateElemOfList
define

    %%%
    % Procedure used to display some datas
    %
    % Example usage:
    % In: 'hello there, please display me'
    % Out: Display on a window : 'hello there, please display me'
    %
    % @param Buf: The data that we want to display on a window.
    %             The data can be a list, a string, an atom,...
    % @return: /
    %%%
    proc {Browse Buf}
        {Browser.browse Buf}
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ====== IMPLEMENTATION OF BASIC FUNCTIONS TO MAKE THEM RECURSIVE TERMINAL ====== %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % NOTE : These implementations are maybe a little bit too slow but there are recursive terminal like asked for the project.

    %%%
    % Implementation of the List.append function but in recursive terminal way.
    %%%
    fun {Append_List L1 L2}
        local
            fun {AppendList_Aux L1 NewList}
                case L1
                of nil then NewList
                [] _|_ then
                    {AppendList_Aux L1.2 L1.1|NewList}
                end
            end
        in
            {AppendList_Aux {Reverse L1} L2}
        end
    end

    %%%
    % Implementation of the List.append function but in recursive terminal way.
    %%%
    fun {Nth_List List N}
        local
            fun {Nth_List_Aux List N}
                case List
                of nil then nil
                [] H|T then
                    if N == 1 then H
                    else {Nth_List T N-1} end
                end
            end
        in
            if N =< 0 then nil
            else {Nth_List_Aux List N} end
        end
    end

    fun {Tokens_String Str Char_Delimiter}
        local
            fun {Tokens_String_Aux Str SubList NewList}
                case Str
                of nil then
                    if SubList \= nil then
                        {Reverse {Reverse SubList}|NewList}
                    else
                        {Reverse NewList}
                    end
                [] H|T then
                    if H == Char_Delimiter then
                        if SubList \= nil then
                            {Tokens_String_Aux T nil {Reverse SubList}|NewList}
                        else
                            {Tokens_String_Aux T nil NewList}
                        end
                    else
                        {Tokens_String_Aux T H|SubList NewList}
                    end
                end
            end
        in
            {Tokens_String_Aux Str nil nil}
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ====== OTHER FUNCTIONS THAT CAN SOMETIMES BE USED FOR SEVERAL USAGES ====== %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%
    % Removes the first Nth elements from a list
    %
    % Example usage:
    % In: [83 97 108 117 116] 3
    % Out: [117 116]
    %
    % @param List: a list
    % @param Nth: a positive integer representing the number of elements to remove from the beginning of the list
    % @return: a new list with the first Nth elements removed from the original list.
    %          If Nth is greater than the length of the list, an empty list is returned.
    %%%
    fun {Remove_List_FirstNthElements List Nth}
        case List
        of nil then nil
        [] _|T then
            if Nth == 1 then T
            else
                {Remove_List_FirstNthElements T Nth-1}
            end
        end
    end

    %%%
    % Checks if a list is a prefix of another list
    %
    % Example usage:
    % In1: [83 97 108 117 116] [83 97]
    % Out1: true
    % In2: [83 97 108 117 116] [97 108]
    % Out2: false
    %
    % @param List: the list to search in
    % @param List_Prefix: the prefix list
    % @return: true if 'List_Prefix' is a prefix of  'List', false otherwise
    %%%
    fun {FindPrefix_InList List List_Prefix}
        case List_Prefix
        of nil then true
        [] H|T then
            if List == nil then false
            else
                if H == List.1 then {FindPrefix_InList List.2 T}
                else false end
            end
        end
    end


    fun {Get_Last_Nth_Word_List ListWords Nth}
        local
            Result
            fun {Get_Last_Nth_Word_List_Aux ListWords N}
                case ListWords
                of nil then nil
                [] _|T then
                    if N == 0 then ListWords
                    else
                        {Get_Last_Nth_Word_List_Aux T N-1}
                    end
                end
            end
        in                      
            Result = {Get_Last_Nth_Word_List_Aux ListWords {Length ListWords}-Nth}
            if Result == nil then ListWords
            else Result end
        end
    end

    fun {SplitList_AtIdx List Idx}
        local 
            fun {SplitList_AtIdx_Aux List NewList Idx}
                case List
                of nil then none
                [] H|T then
                    if Idx == 1 then [{Reverse H|NewList} T]
                    else {SplitList_AtIdx_Aux T H|NewList Idx-1} end
                end
            end
        in
            if Idx == 0 then List
            else {SplitList_AtIdx_Aux List nil Idx} end
        end
    end

    fun {AddReversedWord_ToString Str Word}
        local
            fun {AddReversedWord_ToString NewStr Word}
                case Word
                of nil then NewStr
                [] H|T then
                {AddReversedWord_ToString H|NewStr T}
                end
            end
        in
            {AddReversedWord_ToString nil Word}
        end
    end
     
    fun {ConcatenateElemOfList List Delimiter}
        local
            String_To_Cleaned
            fun {ConcatenateElemOfList_Aux List List_Str}
                case List
                of nil then List_Str
                [] H|T then
                    if Delimiter == none then
                        {ConcatenateElemOfList_Aux T {Append {AddReversedWord_ToString "" H} List_Str}}
                     else
                        {ConcatenateElemOfList_Aux T {Append {AddReversedWord_ToString "" H} Delimiter|List_Str}}
                     end
                end
            end
        in
            String_To_Cleaned = {Reverse {ConcatenateElemOfList_Aux List ""}}
            if String_To_Cleaned.1 == 32 then String_To_Cleaned.2
            else String_To_Cleaned end
        end
    end

    %%%
    % Get the list of strings from a stream associated with a port
    %
    % Example usage:
    % In: ['i am good and you']|['i am very good thanks']|['wow this is a port']|_ 
    % Out: ['i am good and you']|['i am very good thanks']|['wow this is a port']
    %
    % @param Stream: a stream associated with a port that contains a list of parsed lines
    % @return: the list of strings (from the stream 'Stream' associated with the port 'Port' (= global variable))
    %%%
    fun {Get_ListFromPortStream Stream}
        local
            fun {Get_ListFromPortStream_Aux Stream NewList}
                case Stream
                of nil|_ then NewList
                [] H|T then
                    {Get_ListFromPortStream_Aux T H|NewList}
                end
            end
        in
            {Get_ListFromPortStream_Aux Stream nil}
        end
    end

end