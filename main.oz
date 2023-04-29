functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    OS
    Property
    Browser
    Open
define

    % Global variables
	InputText OutputText TweetsFolder_Name List_PathName_Tweets Main_Tree Tree_Over NberFiles NbThreads SeparatedWordsStream SeparatedWordsPort

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

    %%%
    % Class used to open the files, read it and close it.
    %%%
    class TextFile
        from Open.file Open.text
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ================= READING SECTION ================= %%%
    %%% ================= READING SECTION ================= %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%
    % Reads a text file (given its filename) and creates a list of all its lines
    %
    % Example usage:
    % In: "tweets/part_1.txt"
    % Out: ["Congress must..." "..." "..." "..." "..."]
    %
    % @param Filename: a string representing the path to the file
    % @return: a list of all lines in the file, where each line is a string
    %%%
    fun {Reader Filename}
        fun {GetLine TextFile ListLine}
            Line = {TextFile getS($)}
        in
            if Line == false then
                {TextFile close}
                ListLine
            else
                % {Browse {String.toAtom Line}}
                % {Browse {String.toAtom {CleanUp Line fun {$ LineStr} {RemovePartList LineStr [226 128] true} end}}}

                % [226 128] is a character that is not recognised by UTF-8 (the follow char too). That's why the last argument is set to true.
                {GetLine TextFile {CleanUp Line fun {$ LineStr} {RemovePartList LineStr [226 128] true} end} | ListLine}
            end
        end
    in
        {GetLine {New TextFile init(name:Filename flags:[read])} nil}
    end

    %%%
    % Creates a filename by combining the name of a folder and the nth filename in a list of filenames
    %
    % Example usage:
    % In: "tweets" ["part_1.txt" "part_2.txt"] 2
    % Out: "tweets/part_2.txt"
    %
    % @param TweetsFolder_Name: a string representing the name of a folder
    % @param List_PathName: a list of filenames
    % @param Idx: an index representing the position of the desired filename in List_PathName
    % @return: a string representing the desired filename (the Idxth filename in the list) preceded by the folder name + "/"
    %%%
    fun {GetFilename TweetsFolder_Name List_PathName Idx}
        {Append {Append TweetsFolder_Name "/"} {Nth List_PathName Idx}}
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% ================= PARSING SECTION ================= %%%%
    %%%% ================= PARSING SECTION ================= %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    fun {RemoveFirstNthElements List Nth}
        case List
        of nil then nil
        [] H|T then
            if Nth == 1 then T
            else
                {RemoveFirstNthElements T Nth-1}
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
    fun {FindPrefix List List_Prefix}
        case List_Prefix
        of nil then true
        [] H|T then
            if List == nil then false
            else
                if H == List.1 then {FindPrefix List.2 T}
                else false end
            end
        end
    end

    %%%
    % Remove a specified sublist from a given list
    %
    % Example usage:
    % In1: "Jeui ui suis okuiui et je suis louisuiuiuiui" "ui" true
    % Out1: "Jes oket je s lo"
    % In2: "    Je suis   ok  et je  suis louis    " " " false
    % Out2: "Je suis ok et je suis louis"
    %
    % @param SubList: a list from which to remove the specified sublist
    % @param Length_SubList: the sublist to remove from the 'List'
    % @param NextCharRemoveToo: boolean indicating whether to remove the next character
    %                           after the substring if it is found in the 'List'
    % @return: a new list with all instances of the specified sublist removed
    %          (and their next character too if 'removeNextChar' is set to true)
    %%%
    fun {RemovePartList List SubList NextCharRemoveToo}
        local
            Length_SubList
            fun {RemovePartList_Aux List NewList Length_List}
                if Length_List < Length_SubList then NewList
                elseif List == nil then NewList
                else
                    local List_Updated NewList_Updated Length_List_Updated in
                        if {FindPrefix List SubList} == true then
                            if NextCharRemoveToo == true then
                                List_Updated = {RemoveFirstNthElements List Length_SubList+1}
                                Length_List_Updated = Length_List - (Length_SubList + 1)
                                % 153 => = ' special not the basic => basic one is 39
                                if {Nth List Length_SubList+1} == 153 then
                                    NewList_Updated = 39 | NewList
                                else
                                    NewList_Updated = 32 | NewList
                                end
                            else
                                List_Updated = {RemoveFirstNthElements List Length_SubList}
                                NewList_Updated = 32 | NewList
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

    % fun {RemovePartList List SubList NextCharRemoveToo}
    %     local
    %         Length_SubList
    %         fun {RemovePartList_Aux List SubList Length_SubList NextCharRemoveToo}
    %             case List
    %             of nil then nil
    %             [] H|T then
    %                 if {FindPrefix T SubList} == true then
    %                     if NextCharRemoveToo == true then
    %                         % 153 => = ' special not the basic => basic one is 39
    %                         if {Nth T Length_SubList+1} == 153 then
    %                             H | 39 | {RemovePartList_Aux {RemoveFirstNthElements T Length_SubList+1} SubList Length_SubList NextCharRemoveToo}
    %                         else
    %                             H | 32 | {RemovePartList_Aux {RemoveFirstNthElements T Length_SubList+1} SubList Length_SubList NextCharRemoveToo}
    %                         end
    %                     else
    %                         H | 32 | {RemovePartList_Aux {RemoveFirstNthElements T Length_SubList} SubList Length_SubList NextCharRemoveToo}
    %                     end
    %                 else
    %                     H | {RemovePartList_Aux T SubList Length_SubList NextCharRemoveToo}
    %                 end
    %             end
    %         end
    %     in
    %         Length_SubList = {Length SubList}
    %         if {FindPrefix List SubList} == true then
    %             if NextCharRemoveToo == true then
    %                 {RemovePartList_Aux {RemoveFirstNthElements List Length_SubList+1} SubList Length_SubList NextCharRemoveToo}
    %             else
    %                 {RemovePartList_Aux {RemoveFirstNthElements List Length_SubList} SubList Length_SubList NextCharRemoveToo}
    %             end
    %         else
    %             {RemovePartList_Aux List SubList Length_SubList NextCharRemoveToo}
    %         end
    %     end
    % end

    %%%
    % Applies a cleaning function to a string
    %
    % Example usage:
    % If Cleaner = fun {$ LineStr} {RemovePartList LineStr [226 128] true} end
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
        case List
        of nil then nil
        [] H|T then
            % {Browse {String.toAtom {Parser H}}}
            % {Browse {String.toAtom H}}
            local ParsedLine in
                ParsedLine = {Parser H}
                % nil represent the empty atom like this : ''.
                % Useless because false the result of prediction.
                % Remove it.
                if ParsedLine == nil then
                    {ParseAllLines T Parser}
                else
                    {Parser H} | {ParseAllLines T Parser}
                end
            end
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
        case Line
        of H|T then
            local New_H Result_List in
                % 39 is the character ' => keep it only if the previous and the future
                % character is a letter or a digit (not a special character!)
                if H == 39 andthen PreviousGoodChar == true then
                    if T \= nil then
                        if T.1 == {GetNewChar T.1}.1 then
                            H | {ParseLine T true}
                        else
                            32 | {ParseLine T false}
                        end
                    else
                        32 | {ParseLine T false}
                    end
                else
                    Result_List = {GetNewChar H}
                    Result_List.1 | {ParseLine T Result_List.2.1}
                end
            end
        [] nil then nil
        end
    end
    


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ================= TREE STRUCTURE SECTION ================= %%%
    %%% ================= TREE STRUCTURE SECTION ================= %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%
    % Structure of the recursive binary tree : 
    %     tree := leaf | tree(key:Key value:Value t_left:TLeft t_right:TRight)
    %%%

    %%%
    % Recursively searches for a value in a binary tree using its key (based on lexicographical order of the keys)
    %
    % Example usage:
    % In: Tree = tree(key:'i am' value:['the'#1] t_left:tree(key:'boss is' value:['here'#2] t_left:
    %            tree(key:'am the' value:['boss'#1] t_left:leaf t_right:leaf) t_right:leaf) t_right:
    %            tree(key:'no problem' value:['sir'#1] t_left:leaf t_right:tree(key:'the boss' value:['man'#1 'is'#2] t_left:leaf t_right:leaf)))
    %     Key = 'the boss'
    % Out: ['man'#1 'is'#2]
    %
    % @param Tree: a binary tree
    % @param Key: a value representing a specific location in the binary tree
    % @return: the value at the location of the key in the binary tree, or 'notfound' if the key is not present
    %%%
    fun {LookingUp Tree Key}
        case Tree
        of leaf then notfound
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K == Key
            then V
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K > Key
            then {LookingUp TLeft Key}
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K < Key
            then {LookingUp TRight Key}
        end
    end

    %%%
    % Inserts a value into a binary tree at the location of the given key
    % The value is inserted based on the lexicographical order of the keys
    %
    % Example usage:
    % In: Tree = tree(key:'i am' value:['the'#1] t_left:tree(key:'boss is' value:['here'#2] t_left:
    %            tree(key:'am the' value:['boss'#1] t_left:leaf t_right:leaf) t_right:leaf) t_right:
    %            tree(key:'no problem' value:['sir'#1] t_left:leaf t_right:tree(key:'the boss' value:['man'#1 'is'#2] t_left:leaf t_right:leaf)))
    %     Key = 'the boss'
    %     Value = ['newValue'#3]
    % Out: tree(key:'i am' value:['the'#1] t_left:tree(key:'boss is' value:['here'#2] t_left:
    %      tree(key:'am the' value:['boss'#1] t_left:leaf t_right:leaf) t_right:leaf) t_right:
    %      tree(key:'no problem' value:['sir'#1] t_left:leaf t_right:tree(key:'the boss' value:['newValue'#3] t_left:leaf t_right:leaf)))
    %
    % @param Tree: a binary tree
    % @param Key: a value representing a specific location in the binary tree where the value should be inserted
    % @param Value: a value to insert into the binary tree
    % @return: a new tree with the inserted value
    %%%
    fun {Insert Tree Key Value}
        case Tree
        of leaf then tree(key:Key value:Value t_left:leaf t_right:leaf)
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K == Key then
            tree(key:Key value:Value t_left:TLeft t_right:TRight)
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K < Key then
            tree(key:K value:V t_left:TLeft t_right:{Insert TRight Key Value})
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K > Key then
            tree(key:K value:V t_left:{Insert TLeft Key Value} t_right:TRight)
        end
    end

    %%%
    % Updates a list to increase the frequency of specified element
    % If the element is not yet in the list, it is added with a frequency of 1
    % If the element is already in the list, its frequency is increased by 1
    %
    % Example usage:
    % In1: ['word1'#1 'word2'#1 'word3'#9 'word4'#2] 'word4'
    % Out1: ['word1'#1 'word2'#1 'word3'#9 'word4'#3]
    % In2: ['word1'#1 'word2'#1 'word3'#9 'word4'#2] 'word5'
    % Out2: ['word1'#1 'word2'#1 'word3'#9 'word4'#2 'word5'#1]
    %
    % @param L: a list of pairs in the form of atom#frequency
    % @param NewElem: the element whose frequency we want to increase by one
    % @return: a new updated list
    %%%
    fun {UpdateList L NewElem}
        case L
        of notfound then (NewElem#1) | nil
        [] nil then (NewElem#1) | nil 
        [] H|T then 
            case H 
            of H1#H2 then 
                if H1 == NewElem then (H1#(H2+1))|T 
                else H |{ UpdateList T NewElem} end 
            end
        end
    end

    %%%
    % Returns the part of the string after a specified delimiter character
    %
    % Example usage:
    % In: "i am alone"
    % Out: "am alone" if the delimiter is " " (32 in ASCII code)
    %
    % @param Str_Line: a string
    % @param Delimiter_Char: a delimiter character to separate the string
    % @return: the substring of the input string after the delimiter character
    %%%
    fun {GetStrAfterDelimiter Str_Line Delimiter_Char}
        case Str_Line
        of nil then nil
        [] H|T then
            if H == Delimiter_Char then T
            else {GetStrAfterDelimiter T Delimiter_Char} end
        end
    end

    %%%
    % Applies a function that changes the value of an element into a binary tree
    %
    % Example usage:
    % Checks the example for the UpdateValue_ElemOfTree function (repeats that for each elements of the list)
    %
    % @param Tree: a binary tree
    % @param List_Keys: a list of keys (a key representing a location in the binary tree)
    % @return: the new updated tree with all the value updated (at the location of each key in List_Keys)
    %%%
    fun {UpdateElementsOfTree Tree List_Keys}
        local

            %%%
            % Changes the value with a new specified one at the location of a specified key in a binary tree
            %
            % Example usage:  tree(key: value: t_left: t_right:)
            % In: Tree = tree(key:'character too' value:['hard'#2 'special'#1] t_left:tree(key:'amical friend' value:['for'#1] t_left:leaf t_right:leaf) t_right:leaf)
            %     Key = 'i am'
            %     ListOfKeys = ['am the' 'the boss']
            % Out: tree(key:'i am' value:['the'#1] t_left:tree(key:'amical friend' value:['for'#1] t_left:leaf t_right:leaf) t_right:tree(key:['character too'] value:['hard'#2 'special'#1] t_left:leaf t_right:leaf))
            %
            % @param Tree: a binary tree
            % @param Key: a value representing a location in the binary tree
            % @param List_Keys: a list of key (the next one after Key)
            % @return: the new updated tree with one value updated
            %%%
            fun {UpdateValue_ElemOfTree Tree Key List_Keys}

                local Value_to_Insert List_Value New_List_Value in
                    Value_to_Insert = {String.toAtom {GetStrAfterDelimiter {Atom.toString List_Keys.1} 32}} % atom that represent the next word of the Key (example : Key = 'must go' => Value_to_Insert = ['ready' 'now'])
                    List_Value = {LookingUp Tree Key}
                    New_List_Value = {UpdateList List_Value Value_to_Insert}
                    {Insert Tree Key New_List_Value}
                end
            end
        in
            case List_Keys
            of nil then Tree
            [] H|nil then Tree
            [] H|T then
                {UpdateElementsOfTree {UpdateValue_ElemOfTree Tree H T} T}
            end
        end
    end

    %%%
    % Creates a bi-grams list from a list of words (representing the list of the main binary tree's keys)
    %
    % Example usage:
    % In: ["i" "am" "hungry" "get" "some" "food"]
    % Out: ['i am' 'am hungry' 'hungry get' 'get some' 'some food']
    % 
    % @param List: a list of strings representing words
    % @return: a list of bi-grams (atom, not string) created from adjacent words in the input list
    %%%
    fun {BiGrams List}
        case List
        of nil then nil
        [] H|nil then nil
        [] H|T then
            {String.toAtom {Append {Append H [32]} T.1}} | {BiGrams T}
        end
    end

    %%%
    % Creates a binary tree structure to store the data
    %
    % Example usage:
    % In: L = [['i am the boss man'] ['no problem sir'] ["the boss is here"] ["the boss is here"]]
    % Out: tree(key:'i am' value:['the'#1] t_left:tree(key:'boss is' value:['here'#2] t_left:
    %      tree(key:'am the' value:['boss'#1] t_left:leaf t_right:leaf) t_right:leaf) t_right:
    %      tree(key:'no problem' value:['sir'#1] t_left:leaf t_right:tree(key:'the boss' value:['man'#1 'is'#2] t_left:leaf t_right:leaf)))
    %
    % @param L: a list of lists of strings representing a line parsed (from a file)
    % @return: a binary tree with all the data added
    %%%
    fun {CreateTree L}
        local
            fun {CreateTreeAux Tree L}
                case L
                of nil then Tree
                [] H|T then
                    {CreateTreeAux {UpdateElementsOfTree Tree {BiGrams {String.tokens H 32}}} T}
                end
            end
        in
            {CreateTreeAux leaf L}
        end
    end

    %%%
    % Creates a binary subtree representing a value of the main binary tree,
    % given a list of Word#Frequency pairs
    %
    % Example usage:
    % In: ['back'#1 'perfect'#9 'must'#3 'ok'#5 'okay'#3]  b m o p
    % Out: tree(key:5 value:['ok'] t_left:tree(key:3 value:['must' 'okay'] t_left:
    %      tree(key:1 value:['back'] t_left:leaf t_right:leaf) t_right:leaf) t_right:
    %      tree(key:9 value:['perfect'] t_left:leaf t_right:leaf))
    %
    % @param List_Value: a list of pairs in the form Word#Frequence (where Word is an atom and Frequence is a integer)
    % @return: a binary subtree representing a value of the main binary tree
    %%%
    fun {CreateSubtree List_Value}
        local
            fun {CreateSubtreeAux SubTree List_Value}
                case List_Value
                of nil then SubTree
                [] H|T then
                    case H
                    of Word#Freq then
                        local Value in
                            Value = {LookingUp SubTree Freq}
                            if Value == notfound then
                                {CreateSubtreeAux {Insert SubTree Freq [Word]} T}
                            else
                                {CreateSubtreeAux {Insert SubTree Freq {Append Value [Word]}} T}
                            end
                        end
                    end
                end
            end
        in
            {CreateSubtreeAux leaf List_Value}
        end
    end

    %%%
    % Traverse a binary tree in a Pre-Order traversal to update the value of all keys
    % A function UpdaterTree_ChangerValue is used to update values
    % tree(key: value: t_left: t_right:)
    % Example usage: 
    % In: Tree = tree(key:5 value:['ok'#1] t_left:tree(key:3 value:['must'#2 'okay'#1] t_left:leaf t_right:leaf) t_right:leaf)
    %     UpdaterTree_ChangerValue = fun {$ Tree Key Value} {Insert Tree Key {CreateSubtree Value}} end
    % Out: tree(key:5 value:tree(key:1 value:['ok'] t_left:leaf t_right:leaf) t_left:tree(key:2 value:tree(key: value:['okay'] t_left:tree(key:1 value:['must'] t_left:leaf t_right:leaf) t_right:leaf) t_left:leaf t_right:leaf) t_right:leaf)
    %
    % @param Tree: a binary tree
    % @param UpdaterTree_ChangerValue: a function that takes as input a tree, a key and a value and update the value at the specified key
    % @return: a new binary tree where each of these value has been updated by UpdaterTree_ChangerValue
    %%%
    fun {TraverseAndChange Tree UpdaterTree_ChangerValue}
        local
            fun {TraverseAndChangeAux Tree UpdaterTree_ChangerValue UpdatedTree}
                case Tree
                of leaf then UpdatedTree
                [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
                    local T1 T2 in
                        T1 = {TraverseAndChangeAux TLeft UpdaterTree_ChangerValue {UpdaterTree_ChangerValue UpdatedTree Key Value}}
                        T2 = {TraverseAndChangeAux TRight UpdaterTree_ChangerValue T1}
                    end
                end
            end
        in
            {TraverseAndChangeAux Tree UpdaterTree_ChangerValue Tree}
        end
    end

    %%%
    % Traverse a binary tree in Pre-Order traversal to get the following three items in a list:
    %   1) The sum of all keys
    %   2) The greatest key
    %   3) The value associated with the greatest key
    % Note: The keys are numbers, and the values are lists of atoms (words)
    %
    % Example usage: 
    % In: Tree = tree(key:5 value:['ok'] t_left:tree(key:3 value:['must' 'okay'] t_left:leaf t_right:leaf) t_right:leaf)
    % Out: [8 5 ['ok']]
    %
    % @param Tree: a binary tree
    % @return: a list of length 3 => [The sum of all keys      The greater key      The value associated to the greater key]
    %%%
    fun {TraverseToGetProbability Tree}
        local
            List
            TotalFreq
            MaxFreq
            List_Word
            Probability
            fun {TraverseToGetProbability_Aux Tree TotalFreq MaxFreq ListWord}
                case Tree
                of leaf then [TotalFreq MaxFreq ListWord]
                [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
                    local T1 T2 in
                        T1 = {TraverseToGetProbability_Aux TLeft ({Length Value}*Key)+TotalFreq Key Value}
                        T2 = {TraverseToGetProbability_Aux TRight ({Length Value}*Key)+T1.1 Key Value}
                    end
                end
            end
        in
            if Tree == leaf then [nil 0]
            else
                List = {TraverseToGetProbability_Aux Tree 0 0 nil}
                TotalFreq = List.1 div 2
                MaxFreq = List.2.1
                List_Word = List.2.2.1
                Probability = {Int.toFloat MaxFreq} / {Int.toFloat TotalFreq}
                [List_Word Probability]
            end
        end
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ================= MAIN SECTION ================= %%%
    %%% ================= MAIN SECTION ================= %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%
    % Concatenates a list of strings from a stream associated with a port
    %
    % Example usage:
    % In: ['i am good and you']|['i am very good thanks']|['wow this is a port']|_ 
    % Out: ['i am good and you i am very good thanks wow this is a port']
    %
    % @param Stream: a stream associated with a port that contains a list of parsed lines
    % @return: a list with all the elements of the stream concatenated together
    %%%
    fun {Get_ListFromPortStream Stream}
        local
            ListParsed
            fun {Get_ListFromPortStreamAux Stream}
                case Stream
                of nil|T then nil
                [] H|T then
                    {Append H {Get_ListFromPortStreamAux T}}
                end
            end
        in
            {Send SeparatedWordsPort nil}
            {Get_ListFromPortStreamAux Stream}
        end
    end


    %%%
    % Function called when the user pressed the button 'predict'.
    % Call the function {Press} to get the most probable word to predict and display it on the window.
    %
    % @param: /
    % @return: /
    %%%
	proc {CallPress}
		local ResultPress ProbableWords MaxFreq in
            
            % Goal of Tree_Over : Block this bloc of instruction until the structure is created.
            % If {CallPress} is called (= if the user pressed the button "predict") and the structure
            % to stock datas is not ready yet, the program wait here because Tree_Over is only bind
            % when the structure is over and ready.
            if Tree_Over == true then

                ResultPress = {Press}
                {Browse ResultPress}

                if ResultPress == none then
                    {SetText_Window OutputText "You must write minimum 2 words."}
                else
                    ProbableWords = ResultPress.1
                    MaxFreq = ResultPress.2.1

                    % {Browse ProbableWords}
                    % {Browse MaxFreq}

                    if ProbableWords == nil then
                        {SetText_Window OutputText "NO WORD FIND!"}
                    else
                        {SetText_Window OutputText ProbableWords.1}
                    end
                end
            else
                % Will never be executed but need to put something
                skip
                % {SetText_Window OutputText "Will never be display."}
            end
		end
	end


    %%%
    % Inserts a text into the tk window.
    %
    % @param Location_Text: the location where inserts the text (InputText or OutputText)
    % @param Row: a positive number representing the row where to inserts the text
    % @param Col: a positive number representing the column where to inserts the text
    % @param Special_Location: = 'end' or none if no special location
    % @param Text: the text to inserts
    % @return: /
    %%%
    proc {InsertText_Window Location_Text Row Col Special_Location Text}
        if Special_Location == none then
            {Location_Text tk(insert p(Row Col) Text)}
        else
            {Location_Text tk(insert Special_Location Text)}
        end
    end


    %%%
    % Set a text into the tk window (and delete all before).
    %
    % @param Location_Text: the location where set the text (InputText or OutputText)
    % @param Text: the text to sets
    % @return: /
    %%%
    proc {SetText_Window Location_Text Text}
        {Location_Text set(Text)}
    end

    fun {ParseInputUser Str_Line}
        local
            fun {ParseCharUser Char}
                local New_Char in
                    New_Char = {GetNewChar Char}.1
                    if New_Char == 32 then Char
                    else New_Char end
                end
            end
        in
            case Str_Line
            of nil then nil
            [] H|T then
                {ParseCharUser H} | {ParseInputUser T}
            end
        end
    end


    %%%
    % Displays the most likely prediction of the next word based on the last two entered words.
    %
    % @pre: The threads are "ready".
    % @post: Function called when the prediction button is pressed.
    %
    % @param: /
    % @return: Returns a list containing the most probable word(s) list accompanied by the highest probability/frequency.
    %          The return value must take the form:
    %               <return_val> := <most_probable_words> '|' <probability/frequency> '|' nil
    %               <most_probable_words> := <atom> '|' <most_probable_words> | nil
    %               <probability/frequency> := <int> | <float>
    %%%
    fun {Press}
		
		local ProbableWords_Probability TreeMaxFreq SplittedText BeforeLast Last Key Parsed_Key Tree_Value in
            
			SplittedText = {String.tokens {InputText getText(p(1 0) 'end' $)} & }
            
            % Could optimise this line to not have to call {Length List}
            if {Length SplittedText} < 2 then
                none
            else
                Last = {String.tokens {List.last SplittedText} &\n}.1
                BeforeLast = {Nth SplittedText {Length SplittedText} - 1}

                Key = {String.toAtom {Append {Append BeforeLast [32]} Last}}

                Parsed_Key = {String.toAtom {ParseInputUser {Atom.toString Key}}}

                Tree_Value = {LookingUp Main_Tree Parsed_Key}
                
                % {System.show Tree_Value}

                if Tree_Value == notfound then
                    ProbableWords_Probability = {TraverseToGetProbability leaf}
                else
                    ProbableWords_Probability = {TraverseToGetProbability Tree_Value}
                end
            end
		end
    end

    
    %%%
    % Launches N reading and parsing threads that will read and process all the files.
    % The parsing threads send their results to the Port.
    %
    % @param Port: a port structure to store the results of the parser threads
    % @param N: the number of threads used to read and parse all files
    % @return: /
    %%%
    proc {LaunchThreads Port N}
        
        local Port_Waiting_Threads Stream_Waiting_Threads Basic_Nber_Iter Rest_Nber_Iter Current_Nber_Iter in

            Port_Waiting_Threads = {NewPort Stream_Waiting_Threads}
            Basic_Nber_Iter = NberFiles div N
            Rest_Nber_Iter = NberFiles mod N

            for X in 1..N do

                local Current_Nber_Iter1 Start End in
                    
                    % Those formulas are used to split (in the best way) the work between threads.
                    % Those formulas are complicated to find but the idea is here:
                    % Example : if we have 6 threads and 23 files to read and process,
                    %           the repartition will be [4 4 4 4 4 3].
                    %           A naive version will do a repartition
                    %           like this [3 3 3 3 3 8].
                    %           This is a bad version because the last
                    %           thread will slow down the program
                    if Rest_Nber_Iter - X >= 0 then
                        Current_Nber_Iter1 = Basic_Nber_Iter + 1
                        Start = (X - 1) * Current_Nber_Iter1 + 1
                    else
                        Current_Nber_Iter1 = Basic_Nber_Iter
                        Start = Rest_Nber_Iter * (Current_Nber_Iter1 + 1) + (X - 1 - Rest_Nber_Iter) * Current_Nber_Iter1 + 1
                    end

                    End = Start + Current_Nber_Iter1 - 1

                    for Y in Start..End do

                        local File_Parsed File LineToParsed Thread_Reader_Parser L P in

                            File = {GetFilename TweetsFolder_Name List_PathName_Tweets Y}
                            % File = "tweets/custom.txt"

                            thread Thread_Reader_Parser =
                                LineToParsed = {Reader File}
                                L=1
                                {Wait L}
                                File_Parsed = {ParseAllLines LineToParsed fun {$ Str_Line} {RemoveEmptySpace {ParseLine Str_Line false}} end}
                                P=1
                            end

                            {Send Port_Waiting_Threads P}
                            {Send Port File_Parsed}
                        end
                        
                    end
                end
            end
            {Send Port_Waiting_Threads nil}
            {ForAll_Port Stream_Waiting_Threads}
        end
    end

    %%%
    % Procedure usefull to wait that all threads have finished their work.
    %
    % Example usage:
    % In1: 1|1|1|_|1|_|nil|_ 
    % Out1: Wait because the 4th thread doesn't finished  yet!
    % In2: 1|1|1|1|1|_|nil|_ 
    % Out2: Wait because the 6th thread doesn't finished  yet!
    % In3: 1|1|1|1|1|1|nil|_ 
    % Out3: the program can go out of this procedure!
    %
    % @param Stream: a stream associated with a port that contains a list of value that are unbind or bind to 1.
    % @return: /
    %%%
    proc {ForAll_Port Stream}
        case Stream
        of nil|T then skip
        [] H|T then
            {Wait H}
            {ForAll_Port T}
        end
    end


    %%%
    % Fetches Tweets Folder specified in the command line arguments
    %
    % @param: /
    % @return: the Tweets folder specified in the command line arguments
    %%%
    fun {GetSentenceFolder}
        Args = {Application.getArgs record('folder'(single type:string optional:false))}
    in
        Args.'folder'
    end


    %%%
    % Main procedure that creates the Qtk window and calls differents functions/procedures to make the program functional.
    %
    % This procedure creates a GUI window using the Qt toolkit and sets up event handlers to interact with user inputs.
    % It then calls other functions/procedures to parse data files, build data structures, and make predictions based on user inputs.
    %
    % @param: /
    % @return: /
    %%%
    proc {Main}
        
        TweetsFolder_Name = {GetSentenceFolder}
        List_PathName_Tweets = {OS.getDir TweetsFolder_Name}

        NberFiles = {Length List_PathName_Tweets}
        % NberFiles = 5

        % if NberFiles < 10 then
        %     NbThreads = NberFiles
        % else
        %     NbThreads = NberFiles div 2
        % end

        NbThreads = 50

        local UpdaterTree List_Line_Parsed Window Description in

            {Property.put print foo(width:1000 depth:1000)}  % for stdout siz

            % Description of the graphical user interface
            Description=td(
                title: "Text predictor"
                lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:CallPress))
                text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
                action:proc{$} {Application.exit 0} end % Quitte le programme quand la fenetre est fermee
                )
            
            % Creation of the graphical user interface
            Window = {QTk.build Description}
            {Window show}

            {InsertText_Window InputText 0 0 'end' "Loading... Please wait."}
            {InputText bind(event:"<Control-s>" action:CallPress)} % You can also bind events
            {InsertText_Window OutputText 0 0 'end' "You must wait until the database is parsed.\nA message will notify you.\nDon't press the 'predict' button until the message appears!\n"}

            % Create the Port
            SeparatedWordsPort = {NewPort SeparatedWordsStream}
            
            % Launch all threads to reads and parses the files
            {LaunchThreads SeparatedWordsPort NbThreads}

            % We retrieve the information (parsed lines of the files) from the port's stream
            List_Line_Parsed = {Get_ListFromPortStream SeparatedWordsStream}
            {InsertText_Window OutputText 6 0 none "Step 1 Over : Reading + Parsing\n"}
    
            % Creation of the main binary tree (with all subtree as value)
            UpdaterTree = fun {$ Tree Key Value} {Insert Tree Key {CreateSubtree Value}} end
            Main_Tree = {TraverseAndChange {CreateTree List_Line_Parsed} UpdaterTree}

            % CallPress can work now because the structure is ready
            Tree_Over = true

            % Display and remove some strings
            {InsertText_Window OutputText 7 0 none "Step 2 Over : Stocking datas\n"}
            {InsertText_Window OutputText 9 0 none "The database is now parsed.\nYou can write and predict!"}

            if {FindPrefix {InputText getText(p(1 0) 'end' $)} "Loading... Please wait."} then
                % Remove the first 23 characters (= "Loading... Please wait.")
                {InputText tk(delete p(1 0) p(1 23))}
            else
                % Remove all because the user add some texts between or before the line : "Loading... Please wait."
                {SetText_Window InputText ""}
            end
        end
        %%ENDOFCODE%%
    end

    % Appelle la procedure principale
    {Main}
end