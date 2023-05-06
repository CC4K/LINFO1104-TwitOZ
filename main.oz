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


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ====== IMPLEMENTATION OF BASIC FUNCTIONS TO MAKE THEM RECURSIVE TERMINAL : SECTION ====== %%%
    %%% ====== IMPLEMENTATION OF BASIC FUNCTIONS TO MAKE THEM RECURSIVE TERMINAL : SECTION ====== %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % NOTE : These implementations are maybe a little bit too slow but there are recursive terminal like asked for the project.

    %%%
    % Implementation of the List.append function but in recursive terminal way.
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
    % Implementation of the List.nth function but in recursive terminal way.
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

    %%%
    % Implementation of the String.tokens function but in recursive terminal way.
    %%%
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


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ==== IMPLEMENTATION OF USEFULL FUNCIONS : SECTION ==== %%%
    %%% ==== IMPLEMENTATION OF USEFULL FUNCIONS : SECTION ==== %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
            {Send SeparatedWordsPort nil}
            {Get_ListFromPortStream_Aux Stream nil}
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
    % Gets the last word and the word before the last one of a list.
    %
    % Example usage:
    % In: ["hello" "i am okay" "where is" "here"]
    % Out: ["where is" "here"]
    %
    % @param ListWords: a list of strings
    % return: a list of length 2 : [before_last_word   last_word]
    %%%
    fun {Get_TwoLastWord ListWords}
        case ListWords
        of nil then nil
        [] _|nil then nil
        [] H|T then
            if T.2 == nil then
                [H T.1]
            else
                {Get_TwoLastWord T}
            end
        end
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
    fun {Read Filename}
        local
            fun {GetLine TextFile List_Line}
                try 
                    Line = {TextFile getS($)}
                in
                    if Line == false then
                        {TextFile close}
                        List_Line
                    else {GetLine TextFile List_Line|32|Line} end
                catch _ then {Application.exit} end
            end
        in
            try
                TextOfFile = {New TextFile init(name:Filename flags:[read])}
            in
                {Flatten {GetLine TextOfFile nil}}
            catch _ then {Application.exit} end
        end
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
        {Append_List TweetsFolder_Name 47|{Nth_List List_PathName Idx}}
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% ================= PARSING SECTION ================= %%%%
    %%%% ================= PARSING SECTION ================= %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % NOTE : The parsing is done in a recursive terminal way.
    % NOTE : The parsing in this basic version (without extensions) is naive and not very efficient.
    % NOTE : Checks the version with extensions to see a better parsing.
    

    %%%
    % Replaces the character by an other
    % If the character is an uppercase letter => replaces it by its lowercase version
    % If the character is a digit letter => don't replace it
    % If the character is a lowercase letter => don't replace it
    % If the character is a special character (all the other case) => replaces it by a space (32 in ASCII code)
    %
    % Example usage:
    % In1: 99          In2: 69            In3: 57           In4: 42
    % Out1: 99         Out2: 101          Out3: 57          Out4: 32
    %
    % @param Char: a character (number in ASCII code)
    % @return: the char parsed
    %%%
    fun {GetNewChar Char}
        if 97 =< Char andthen Char =< 122 then
            Char
        elseif 48 =< Char andthen Char =< 57 then
            Char
        elseif 65 =< Char andthen Char =< 90 then
            Char + 32
        else
            32
        end
    end


    %%%
    % Applies a parsing function to each string in a list of strings
    %
    % Example usage:
    % In: ["  !Hello there...! General Kenobi!!! ...100     "]
    % Out: ["hello there general kenobi 100"]
    %
    % @param List: a list of strings
    % @return: a list of the parsed strings
    %%%
    fun {ParseLines List Parser}
        local
            fun {ParseLines_Aux List NewList}
                case List
                of nil then {Reverse NewList}
                [] H|T then
                    {ParseLines_Aux T {Parser H}|NewList}
                end
            end
        in
            {Cleaning_UnNecessary_Spaces {ParseLines_Aux List nil}}
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
                    New_Char = {GetNewChar Char}
                    if New_Char == 32 then Char
                    else New_Char end
                end
            end
        in
            {ParseLines Str_Line fun {$ Char} {ParseCharUser Char} end}
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
        [] tree(key:K value:V t_left:_ t_right:_) andthen K == Key
            then V
        [] tree(key:K value:_ t_left:TLeft t_right:_) andthen K > Key
            then {LookingUp TLeft Key}
        [] tree(key:K value:_ t_left:_ t_right:TRight) andthen K < Key
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
        [] tree(key:K value:_ t_left:TLeft t_right:TRight) andthen K == Key then
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
    % @param List: a list of pairs in the form of atom#frequency
    % @param NewElem: the element whose frequency we want to increase by one
    % @return: a new updated list
    %%%
    fun {UpdateList List NewElem}
        local
            fun {UpdateList_Aux List NewList NewElem}
                case List
                of notfound then (NewElem#1)|nil % Special case if the List of value hasn't be found in the tree
                [] nil then (NewElem#1)|NewList
                [] H|T then 
                    case H 
                    of H1#H2 then 
                        if H1 == NewElem then (H1#(H2+1))|{Append_List T NewList}
                        else {UpdateList_Aux T H|NewList NewElem} end 
                    end
                end
            end
        in
            {UpdateList_Aux List nil NewElem}
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
            [] _|nil then Tree
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
        local
            fun {BiGrams_Aux List NewList}
                case List
                of nil then nil
                [] _|nil then {Reverse NewList}
                [] H|T then
                    {BiGrams_Aux T {String.toAtom {Append_List H 32|T.1}}|NewList}
                end
            end
        in
            {BiGrams_Aux List nil}
        end
    end


    % Creates the all binary tree structure (to store the datas).
    % To do it, the function 'Update_Tree' is applied on all
    % the element of the list given as parameter.
    % Check the docstring of 'Update_Tree' to see an example usage.
    %
    % @param List_List_Line: a list of lists of lists of strings
    % @return: the all binary tree with all the datas added
    %%%
    fun {CreateTree List_List_Line}
        local
            fun {CreateTree_Aux List_List_Line NewTree}
                case List_List_Line
                of nil then NewTree
                [] H|T then
                    {CreateTree_Aux T {UpdateElementsOfTree NewTree {BiGrams {Tokens_String H 32}}}}
                end
            end
        in
            {CreateTree_Aux List_List_Line leaf}
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
            fun {CreateSubtree_Aux SubTree List_Value}
                case List_Value
                of nil then SubTree
                [] H|T then
                    case H
                    of Word#Freq then
                        local Value in
                            Value = {LookingUp SubTree Freq}
                            if Value == notfound then
                                {CreateSubtree_Aux {Insert SubTree Freq [Word]} T}
                            else
                                {CreateSubtree_Aux {Insert SubTree Freq Word|Value} T}
                            end
                        end
                    end
                end
            end
        in
            {CreateSubtree_Aux leaf List_Value}
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
    fun {Change_Tree_Values Tree UpdaterTree_ChangerValue}
        local
            fun {Change_Tree_Values_Aux Tree UpdatedTree}
                case Tree
                of leaf then UpdatedTree
                [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
                    local T1 in
                        T1 = {Change_Tree_Values_Aux TLeft {UpdaterTree_ChangerValue UpdatedTree Key Value}}
                        _ = {Change_Tree_Values_Aux TRight T1}
                    end
                end
            end
        in
            {Change_Tree_Values_Aux Tree Tree}
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
    fun {GetResultPrediction Tree}
        local
            List TotalFreq MaxFreq List_Word Probability
            fun {GetResultPrediction_Aux Tree TotalFreq MaxFreq ListWord}
                case Tree
                of leaf then [TotalFreq MaxFreq ListWord]
                [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
                    local T1 in
                        T1 = {GetResultPrediction_Aux TLeft TotalFreq MaxFreq ListWord}
                        _ = {GetResultPrediction_Aux TRight ({Length Value}*Key)+T1.1 Key Value}
                    end
                end
            end
        in
            if Tree == leaf then [[nil] 0.0]
            else
                List = {GetResultPrediction_Aux Tree 0 0 nil}
                TotalFreq = List.1
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
                ProbableWords = ResultPress.1
                MaxFreq = ResultPress.2.1

                if ProbableWords == [nil] then {SetText_Window OutputText "No word found."}
                else {SetText_Window OutputText ProbableWords.1} end
            else skip end
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


    %%%
    % Displays to the output zone on the window the most likely prediction of the next word based on the N last entered words.
    % The value of N depends of the N-Grams asked by the user.
    % This function is called when the prediction button is pressed.
    %
    % @param: /
    % @return: Returns a list containing the most probable word(s) list accompanied by the highest probability/frequency.
    %          The return value must take the form:
    %
    %               <return_val> := <most_probable_words> '|' <probability/frequency> '|' nil
    %
    %               <most_probable_words> := <atom> '|' <most_probable_words>
    %                                        | nil
    %                                        | <no_word_found>
    %
    %               <no_word_found>         := nil '|' nil
    %
    %               <probability/frequency> := <int> | <float>
    %%%
    fun {Press}
		local SplittedText List_Words BeforeLast Last Key Parsed_Key Tree_Value in

            % Clean the input user and get the 2 last words
            SplittedText = {Tokens_String {ParseLines {InputText getText(p(1 0) 'end' $)} fun {$ Char} {GetNewChar Char} end} 32}
            List_Words = {Get_TwoLastWord SplittedText}

            if List_Words == nil then  [[nil] 0.0] % If the user did't write at least two words => return [[nil] 0.0]
            elseif {Length List_Words} < 2 then [[nil] 0.0] % If the user did't write at least two words => return [[nil] 0.0]
            else
                BeforeLast = List_Words.1
                Last = {Tokens_String List_Words.2.1 10}.1

                Key = {String.toAtom {Append_List BeforeLast 32|Last}}
                Parsed_Key = {String.toAtom {ParseInputUser {Atom.toString Key}}}
                Tree_Value = {LookingUp Main_Tree Parsed_Key}

                if Tree_Value == notfound then
                    [[nil] 0.0]
                else
                    {GetResultPrediction Tree_Value}
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

        local
            Basic_Nber_Iter = NberFiles div N
            Rest_Nber_Iter = NberFiles mod N
            List_Waiting_Threads

            %%%
            % Allows to launch a thread that will read and parse a file
            % and to get the list with the value unbound until the thread has finished its work.
            %
            % @param Start: the number of the file where the thread begins to work (reads and parses)
            % @param End: the number of the file where the thread stops to work (reads and parses)
            % @param List_Waiting_Threads: a list initialized to nil
            % @return: the list containing all the value unbound of all threads.
            %          the value will be bound where the thread has finished its work.
            fun {Launch_OneThread Start End List_Waiting_Threads}

                if Start == End+1 then List_Waiting_Threads
                else
                    local File_Parsed File LineToParsed Thread_Reader_Parser L P in

                        File = {GetFilename TweetsFolder_Name List_PathName_Tweets Start}
                        % File = "tweets/custom.txt"

                        thread Thread_Reader_Parser =
                            LineToParsed = {Read File}
                            L=1
                            {Wait L}
                            File_Parsed = {ParseLines LineToParsed fun {$ Char} {GetNewChar Char} end}
                            P=1
                        end
                    
                        {Send Port File_Parsed}
                        {Launch_OneThread Start+1 End P|List_Waiting_Threads}
                    end
                end
            end


            %%%
            % Allows to launch N threads and to get the list with the value of each thread :
            %     Unbound if the thread has not finished its work
            %     Bound if the thread has finished its work
            %
            % @param List_Waiting_Threads: a list initialized to nil
            % @param Nber_Threads: the number of threads to launch
            % @return: the list containing all the value unbound (until they have finished their work) of all threads.    
            fun {Launch_AllThreads List_Waiting_Threads Nber_Iter}
                
                if Nber_Iter == 0 then List_Waiting_Threads
                else
                    local Current_Nber_Iter1 Start End in

                        % Those formulas are used to split (in the best way) the work between threads.
                        % Those formulas are complicated to find but the idea is here:
                        % Example : if we have 6 threads and 23 files to read and process, the repartition will be [4 4 4 4 4 3].
                        %           A naive version will do a repartition like this [3 3 3 3 3 8].
                        %           This is a bad version because the last thread will slow down the program
                        %%%
                        if Rest_Nber_Iter - Nber_Iter >= 0 then
                            Current_Nber_Iter1 = Basic_Nber_Iter + 1
                            Start = (Nber_Iter - 1) * Current_Nber_Iter1 + 1
                        else
                            Current_Nber_Iter1 = Basic_Nber_Iter
                            Start = Rest_Nber_Iter * (Current_Nber_Iter1 + 1) + (Nber_Iter - 1 - Rest_Nber_Iter) * Current_Nber_Iter1 + 1
                        end
        
                        End = Start + Current_Nber_Iter1 - 1

                        {Launch_AllThreads {Append_List {Launch_OneThread Start End nil} List_Waiting_Threads} Nber_Iter-1}

                    end
                end

            end
        in
            % Launch all the threads
            % The parsing files are stocked in the Port
            % The variables to Wait all the threads are stocked in List_Waiting_Threads
            List_Waiting_Threads = {Launch_AllThreads nil N}
        
            % Wait for all the threads
            % When a thread have finished, the value P associated to this thread
            % is bind and the program can move on 
            {ForAll List_Waiting_Threads proc {$ P} {Wait P} end}
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

        % More threads than files is useless in this case.
        % We take the maximum because the threads are 'false' threads.
        % They are not really threads but they are used to split the work between the files.
        % There is no overhead to create more threads.
        NbThreads = NberFiles

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
            Main_Tree = {Change_Tree_Values {CreateTree List_Line_Parsed} UpdaterTree}

            % {Press} can be applied now because the structure is ready
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