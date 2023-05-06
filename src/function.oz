functor
import
    Browser
    Variables at 'variables.ozf'
export
    Browse

    %% Basic functions implemented in recursive terminal way %%
    Append_List
    Nth_List
    Tokens_String

    %% Other usefull functions %%
    Remove_List_FirstNthElements
    FindPrefix_InList
    Get_Last_Nth_Word_List
    Get_ListFromPortStream
    SplitList_AtIdx
    ConcatenateElemOfList
    Get_Last_Elem_Stream
    IsInList
    CompareList
    RemoveLastValue
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

    % NOTE : These implementations are maybe a little bit more slow but there are recursive terminal like asked for the project.
    % NOTE : All the others functions that we have used (lile {Reverse List} or {ForAll List Function} are recursive terminal too.


    %%%
    % Implementation of the List.append function.
    % Appends two lists together.
    %
    % Example usage:
    % In: [83 97 108 117 116] [32 84 101 115 116]
    % Out: [83 97 108 117 116 32 84 101 115 116]
    %
    % @param L1: a list
    % @param L2: a list
    % return: a new list which is the concatenation of L1 and L2
    %%%
    fun {Append_List L1 L2}
        local
            fun {AppendList_Aux L1 NewList}
                case L1
                of nil then NewList
                [] H|T then
                    {AppendList_Aux T H|NewList}
                end
            end
        in
            {AppendList_Aux {Reverse L1} L2}
        end
    end


    %%%
    % Implementation of the List.nth function.
    % Returns the Nth element of a list.
    %
    % Example usage:
    % In: [83 97 108 117 116] 3
    % Out: 108
    %
    % @param List: a list
    % @param N: a positive integer representing the index of the element to return
    % @return: the Nth element of the list
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
            % If N is negative, we return nil
            if N =< 0 then nil
            else {Nth_List_Aux List N} end
        end
    end


    %%%
    % Implementation of the String.tokens function.
    % Splits a string into a list of strings using a delimiter.
    %
    % Example usage:
    % In: "hello there, please display me" " "
    % Out: ["hello" "there," "please" "display" "me"]
    %
    % @param Str: a string
    % @param Char_Delimiter: a character used to split the string
    % @return: a list of strings splitted from the original string by the delimiter
    fun {Tokens_String Str Char_Delimiter}
        local
            fun {Tokens_String_Aux Str SubList NewList}
                case Str
                of nil then
                    if SubList \= nil then {Reverse {Reverse SubList}|NewList}
                    else {Reverse NewList} end
                [] H|T then
                    if H == Char_Delimiter then
                        if SubList \= nil then {Tokens_String_Aux T nil {Reverse SubList}|NewList}
                        else {Tokens_String_Aux T nil NewList} end
                    else
                        {Tokens_String_Aux T H|SubList NewList}
                    end
                end
            end
        in
            {Tokens_String_Aux Str nil nil}
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ====== OTHER FUNCTIONS USEFULL IN THE PROGRAMM ====== %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%
    % Checks if a value is in a list => return true if the value is in the list, false otherwise.
    %
    % Example usage:
    % In1: [83 97 108 117 116] 83    In2: [83 97 108 117 116] 84
    % Out1: true                     Out2: false
    %
    % @param List: a list
    % @param Value: a value
    % Note : the value and the elements of the list must be of the same type
    % @return: true if the value is in the list, false otherwise
    fun {IsInList List Value}
        case List
        of nil then false
        [] H|T then
            if H == Value then true
            else {IsInList T Value} end
        end
    end


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


    %%%
    % Gets the last Nth elements from a list
    %
    % Example usage:
    % In1: [83 97 108 117 116] 3   In2: [83 97 108 117 116] 6   In3: [83 97 108 117 116] 0
    % Out1: [108 117 116]          Out2: nil                    Out3: nil
    %
    % @param List: a list
    % @param Nth: a positive integer representing the number of elements to get from the end of the list
    % @return: a new list with the last Nth elements from the original list.
    fun {Get_Last_Nth_Word_List List_Words Nth}
        local Length_Reversed in
            Length_Reversed = {Length List_Words} - Nth
            if Length_Reversed == 0 then List_Words
            elseif Length_Reversed < 0 then nil
            else {Remove_List_FirstNthElements List_Words Length_Reversed} end
        end
     end


    %%%
    % Slits a list at a given index
    %
    % Example usage:
    % In1: [83 97 108 117 116] 3
    % Out1: [[83 97 108] [117 116]]
    %
    % @param List: a list
    % @param Nth: a positive integer representing the index at which to split the list
    % @return: a list of two lists, the first one containing the first Nth elements of the original list,
    %          the second one containing the remaining elements of the original list.
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


    %%%
    % Concatenates the elements of a list into a string using a delimiter
    %
    % Example usage:
    % In1 ["hello" "there" "please" "display" "me"] " "
    % Out1 "hello there please display me"
    %
    % @param List: a list of strings
    % @param Delimiter: a string used to separate the elements of the list
    % @return: a string containing the elements of the list concatenated with the delimiter
    fun {ConcatenateElemOfList List Delimiter}
        local
            String_To_Cleaned

            %%%
            % Reversed a word.
            %%%
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

            %%%
            % Concatenates the elements of a list into a string using a delimiter.
            %%%
            fun {ConcatenateElemOfList_Aux List List_Str}
                case List
                of nil then {Reverse List_Str}
                [] H|T then
                    if Delimiter == none then
                        {ConcatenateElemOfList_Aux T {Append {AddReversedWord_ToString "" H} List_Str}}
                     else
                        {ConcatenateElemOfList_Aux T {Append {AddReversedWord_ToString "" H} Delimiter|List_Str}}
                     end
                end
            end
        in
            String_To_Cleaned = {ConcatenateElemOfList_Aux List ""}
            % Clean the string from the first space if there is one
            if String_To_Cleaned.1 == 32 then String_To_Cleaned.2
            else String_To_Cleaned end
        end
    end


    %%%
    % Get the list of strings from a stream associated with a port
    % Note : the stream is ending with the element nil.
    %
    % Example usage:
    % In: ['i am good and you']|['i am very good thanks']|['wow this is a port']|nil|_
    % Out: ['i am good and you']|['i am very good thanks']|['wow this is a port']
    %
    % @return: the list of strings (from the stream 'Stream' associated with the port 'Port' (= global variable))
    %%%
    fun {Get_ListFromPortStream}
        local
            fun {Get_ListFromPortStream_Aux Stream NewList}
                case Stream
                of nil|_ then NewList
                [] H|T then
                    {Get_ListFromPortStream_Aux T H|NewList}
                end
            end
        in
            {Get_ListFromPortStream_Aux Variables.separatedWordsStream nil}
        end
    end

    
    %%%
    % Get the last version of the tree (the last updated one) from the stream associated with a port.
    % Note : the stream isn't ending with any element (=> _ = unbound element).
    %
    % Example usage:
    % In: [tree(1,2,3)]|[tree(4,5,6)]|[tree(7,8,9)]|_
    % Out: tree(7,8,9)
    %
    % @return: the last version of the tree (from the stream 'Stream' associated with the port 'Port' (= global variable))
    fun {Get_Last_Elem_Stream Stream}
        local
            fun {Get_Last_Elem_Stream_Aux Stream}
                case Stream
                of H|T then
                    % {IsDet T} is used to check if the element T is bound or not (true in this case)
                    % If it is unbound, then it means that H is the last element of the stream!
                    if {IsDet T} == false then H
                    else {Get_Last_Elem_Stream_Aux T} end
                end
            end
        in
            {Get_Last_Elem_Stream_Aux Stream}
        end
    end


    %%%
    % Compare two lists and return true if they are the same (doesn't check the order!).
    %
    % Example usage:
    % In: ['the' 'all' 'with'] ['all' 'the' 'with']
    % Out: true
    %
    % @param L1_Str_InAtom: list of atoms
    % @param L2_Atom: list of atoms
    % @return: true if the lists are the same, false otherwise.
    %%%
    fun {CompareList L1_Str_InAtom L2_Atom}
        case L1_Str_InAtom
        of nil then true
        [] H|T then
            if {IsInList L2_Atom H} == true then {CompareList T L2_Atom}
            else false end
        end
    end
    

    %%%
    % Remove the last value of a list.
    %
    % Example usage:
    % In: [1 2 3 4]
    % Out: [1 2 3]
    %
    % @param List: list of atoms
    % @return: list without the last value.
    %%%
    fun {RemoveLastValue List}
        local
            fun {RemoveLastValue_Aux List NewList}
                case List
                of nil then NewList
                [] _|nil then NewList
                [] H|T then
                    {RemoveLastValue_Aux T H|NewList}
                end
            end
        in
            {Reverse {RemoveLastValue_Aux List nil}}
        end
    end

end