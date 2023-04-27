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
	InputText OutputText TweetsFolder_Name List_PathName_Tweets Main_Tree Tree_Over NberFiles NbThreads

    proc {Browse Buf}
        {Browser.browse Buf}
    end

    class TextFile
        from Open.file Open.text
    end


    %%% ================= READING ================= %%%
    %%% ================= READING ================= %%%

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
        fun {GetLine TextFile}
            Line = {TextFile getS($)}
        in
            if Line == false then
                {TextFile close}
                nil
            else
                % The last argument of the anonymous function is set to true because we
                % also need to remove the next letter because the substrings we want to remove are :
                %      Substring n°1 = "â\x80\x99" (represent ')
                %      Substring n°2 = "â\x80\x9C" (represent " from one side)
                %      Substring n°3 = "â\x80\x9D" (represent " on the other side)
                % [226 128] represent "â\x80\x9" (found after test)
                {CleanUp Line fun {$ LineStr} {RemovePartList LineStr [226 128] true} end} | {GetLine TextFile}
            end
        end
    in
        {GetLine {New TextFile init(name:Filename flags:[read])}}
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
        local PathName in
            PathName = {Nth List_PathName Idx}
            {Append {Append TweetsFolder_Name "/"} PathName}
        end
    end

    %%% ================= PARSING ================= %%%
    %%% ================= PARSING ================= %%%

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
            fun {RemovePartList_Aux List SubList Length_SubList NextCharRemoveToo}
                case List
                of nil then nil
                [] H|T then
                    if {FindPrefix T SubList} == true then
                        if NextCharRemoveToo == true then
                            %%% Si on veut séparer comme ceci : "didn't" en "didn t" et pas en "didnt", il faut faire
                            %%% H | 32 | {RemovePartList_Aux {RemoveFirstNthElements T Length_SubList+1} SubList Length_SubList NextCharRemoveToo}
                            %%% à la place de la ligne en-dessous
                            H | {RemovePartList_Aux {RemoveFirstNthElements T Length_SubList+1} SubList Length_SubList NextCharRemoveToo}
                        else
                            H | {RemovePartList_Aux {RemoveFirstNthElements T Length_SubList} SubList Length_SubList NextCharRemoveToo}
                        end
                    else
                        H | {RemovePartList_Aux T SubList Length_SubList NextCharRemoveToo}
                    end
                end
            end
        in
            Length_SubList = {Length SubList}
            if {FindPrefix List SubList} == true then
                if NextCharRemoveToo == true then
                    %%% Si on veut séparer comme ceci : "didn't" en "didn t" et pas en "didnt", il faut faire
                    %%% H | 32 | {RemovePartList_Aux {RemoveFirstNthElements T Length_SubList+1} SubList Length_SubList NextCharRemoveToo}
                    %%% à la place de la ligne en-dessous
                    {RemovePartList_Aux {RemoveFirstNthElements List Length_SubList+1} SubList Length_SubList NextCharRemoveToo}
                else
                    {RemovePartList_Aux {RemoveFirstNthElements List Length_SubList} SubList Length_SubList NextCharRemoveToo}
                end
            else
                {RemovePartList_Aux List SubList Length_SubList NextCharRemoveToo}
            end
        end
    end

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
    

    %%% ================= TREE STRUCTURE ================= %%%
    %%% ================= TREE STRUCTURE ================= %%%

    %%%
    % Structure of the recursive binary tree : 
    %     tree := leaf | tree(key:Key value:Value t_left:TLeft t_right:TRight)
    %
    % Example usage: 
    %     T = tree(key:horse value:cheval
    %               t_left:tree(key:dog value:chien
    %                   t_left:tree(key:cat value:chat t_left:leaf t_right:leaf)
    %                   t_right:tree(key:elephant value:elephant t_left:leaf t_right:leaf))
    %               t_right:tree(key:mouse value:souris
    %                   t_left:tree(key:monkey value:singe t_left:leaf t_right:leaf)
    %                   t_right:tree(key:tiger value:tigre t_left:leaf t_right:leaf)))
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
        of nil then (NewElem#1)|nil 
        [] H|T then 
            case H 
            of H1#H2 then 
                if H1 == NewElem then (H1#(H2+1))|T 
                else H|{UpdateList T NewElem} end 
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
    %%%%%%%%%%%%%%%%%%%%%%%%%% TODO DOC %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%
    fun {AddLineToTree Tree ListBiGrams}
        case ListBiGrams
        of nil then Tree
        [] H|nil then Tree
        [] H|T then
            if T.1 \= nil andthen H \= nil then
                local List_Value Value_to_Insert Key NewList in
                    Key = H % ATOME : Représente un double mot (example 'i am' ou 'must go')
                    Value_to_Insert = {String.toAtom {GetStrAfterDelimiter {Atom.toString T.1} 32}} % ATOME : Représente le prochain mot (example 'ready' ou 'now')
                    List_Value = {LookingUp Tree Key}

                    % The first word is not in the main tree
                    if List_Value == notfound then
                        {AddLineToTree {Insert Tree Key [Value_to_Insert#1]} T} % Appel récursif

                    % The first word is in the main tree
                    else
                        NewList = {UpdateList List_Value Value_to_Insert}
                        {AddLineToTree {Insert Tree Key NewList} T} % Appel récursif
                    end
                end
            end
        end
    end

    %%%
    % Creates a bi-grams list from a list of words
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
                    {CreateTreeAux {AddLineToTree Tree {BiGrams {String.tokens H 32}}} T}
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
    %%%%%%%%%%%%%%%%%%%%%%%%%% TODO DOC %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%
    fun {TraverseAndChange Tree}
        local
            fun {TraverseAndChangeAux Tree CopyTree}
                case Tree
                of leaf then CopyTree
                [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
                    local NewValue NewTree T1 T2 in
                    % Pre-Order traversal
                        NewValue = {CreateSubtree Value}
                        NewTree = {Insert CopyTree Key NewValue}
                        
                        T1 = {TraverseAndChangeAux TLeft NewTree}
                        T2 = {TraverseAndChangeAux TRight T1}
                    end
                end
            end
        in
            {TraverseAndChangeAux Tree Tree}
        end
    end

    %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% TODO DOC %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%
    fun {GetTreeMaxFreq Tree}
        case Tree
        of notfound then leaf
        [] tree(key:K value:V t_left:TLeft t_right:TRight) then
            if TRight \= leaf then
                {GetTreeMaxFreq TRight}
            else
                tree(key:K value:V t_left:TLeft t_right:TRight)
            end
        end
    end

    %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% TODO DOC %%%%%%%%%%%%%%%%%%%%%%%%%%
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
                        T1 = {TraverseToGetProbability_Aux TLeft TotalFreq+Key Key Value}
                        T2 = {TraverseToGetProbability_Aux TRight T1.1+Key Key Value}
                    end
                end
            end
        in
            if Tree == leaf then [none 0]
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


    %%% ================= MAIN ================= %%%
    %%% ================= MAIN ================= %%%

    %%%===================================================================%%%
    %%% /!\ Fonction testee /!\
    %%% @pre : les threads sont "ready"
    %%% @post: Fonction appellee lorsqu on appuie sur le bouton de prediction
    %%%        Affiche la prediction la plus probable du prochain mot selon les deux derniers mots entres
    %%% @return: Retourne une liste contenant la liste du/des mot(s) le(s) plus probable(s) accompagnee de 
    %%%          la probabilite/frequence la plus elevee. 
    %%%          La valeur de retour doit prendre la forme:
    %%%                  <return_val> := <most_probable_words> '|' <probability/frequence> '|' nil
    %%%                  <most_probable_words> := <atom> '|' <most_probable_words> 
    %%%                                           | nil
    %%%                  <probability/frequence> := <int> | <float>
    fun {Press}
		
		local ProbableWords_Probability TreeMaxFreq SplittedText BeforeLast Last Key Tree_Value in
            
			SplittedText = {String.tokens {InputText getText(p(1 0) 'end' $)} & }
            
            if {Length SplittedText} < 2 then % Pourrait optimisé pour ne pas devoir appelé {Length List}
                none
            else
                Last = {String.tokens {List.last SplittedText} &\n}.1
                BeforeLast = {Nth SplittedText {Length SplittedText} - 1}

                Key = {String.toAtom {Append {Append BeforeLast [32]} Last}}
                Tree_Value = {LookingUp Main_Tree Key}
                
                % {Browse Tree_Value}

                if Tree_Value == notfound then
                    ProbableWords_Probability = {TraverseToGetProbability leaf}
                else
                    ProbableWords_Probability = {TraverseToGetProbability Tree_Value}
                end
                
                %%% To have frequence and not the probability %%%

                % TreeMaxFreq = {Tree.getTreeMaxFreq Tree_Value}

                % if TreeMaxFreq == leaf then
                %     [none 0]
                % else
                %     {Browse TreeMaxFreq.value}
                %     {Browse TreeMaxFreq.key}
                %     [TreeMaxFreq.value TreeMaxFreq.key]
                % end

            end
		end
    end

    %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% TODO DOC %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%
	proc {CallPress}
		local ResultPress ProbableWords MaxFreq in
            
            % But de Tree_Over : bloquer le programme le temps que la structure soit crée!
            if Tree_Over == true then

                ResultPress = {Press}
                {Browse ResultPress}

                if ResultPress == none then
                    {OutputText set("You must write minimum 2 words.")}
                else
                    ProbableWords = ResultPress.1
                    MaxFreq = ResultPress.2.1

                    % {Browse ProbableWords}
                    % {Browse MaxFreq}

                    if ProbableWords == none then
                        {OutputText set("NO WORD FIND!")}
                    else
                        {OutputText set(ProbableWords.1)} % Faut-il renvoyer le premier si y'en a plusieurs ?
                    end
                end
            else
                % Never executed
                {OutputText set("Will never be display.")}
            end
		end
	end

    %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% TODO DOC %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%
    %%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
    %%% Les threads de parsing envoient leur resultat au port Port
    proc {LaunchThreads Port N}
        
        local Basic_Nber_Iter Rest_Nber_Iter Current_Nber_Iter in

            Basic_Nber_Iter = NberFiles div N
            Rest_Nber_Iter = NberFiles mod N

            for X in 1..N do

                local Current_Nber_Iter1 Start End in
                    
                    if Rest_Nber_Iter - X >= 0 then
                        Current_Nber_Iter1 = Basic_Nber_Iter + 1
                        Start = (X - 1) * Current_Nber_Iter1 + 1
                    else
                        Current_Nber_Iter1 = Basic_Nber_Iter
                        %% Permet de répartir le mieux possible le travail entre les threads ! Formule trouvé par de la logique
                        Start = Rest_Nber_Iter * (Current_Nber_Iter1 + 1) + (X - 1 - Rest_Nber_Iter) * Current_Nber_Iter1 + 1
                    end

                    End = Start + Current_Nber_Iter1 - 1

                    for Y in Start..End do

                        local File ThreadReader ThreadParser L P in
                               
                            File = {GetFilename TweetsFolder_Name List_PathName_Tweets Y}
                            thread ThreadReader = {Reader File} L=1 end
                            thread {Wait L} ThreadParser = {ParseAllLines ThreadReader fun {$ Str_Line} {RemoveEmptySpace {ParseLine Str_Line}} end} P=1 end
                            {Wait P}
                            {Send Port ThreadParser}
                        end
                    end
                end
            end
        end
    end

    %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% TODO DOC %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%
    fun {Get_Nth_FirstElem_Port Stream_Port N}
        local
            fun {Get_Nth_FirstElem_Port Stream_Port Acc N}
                if N == 0 then nil
                else
                    case Stream_Port
                    of H|T then
                        {Append H {Get_Nth_FirstElem_Port T Acc+1 N-1}}
                    end
                end
            end
        in
            {Get_Nth_FirstElem_Port Stream_Port 1 N}
        end
    end

    %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% TODO DOC %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%
    %%% Fetch Tweets Folder from CLI Arguments
    %%% See the Makefile for an example of how it is called
    fun {GetSentenceFolder}
        Args = {Application.getArgs record('folder'(single type:string optional:false))}
    in
        Args.'folder'
    end


    %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% TODO DOC %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%
    %%% Procedure principale qui cree la fenetre et appelle les differentes procedures et fonctions
    proc {Main}
        
        TweetsFolder_Name = {GetSentenceFolder}
        List_PathName_Tweets = {OS.getDir TweetsFolder_Name}

        NberFiles = {Length List_PathName_Tweets}
        NbThreads = 5

        local List_Port Basic_Tree Window Description SeparatedWordsStream SeparatedWordsPort in

        {Property.put print foo(width:1000 depth:1000)}  % for stdout siz

        % Création de l'interface graphique
        Description=td(
            title: "Text predictor"
            lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:CallPress))
            text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
            action:proc{$} {Application.exit 0} end % Quitte le programme quand la fenetre est fermee
            )
        
        % Création de la fenêtre
        Window = {QTk.build Description}
        {Window show}
        
        {InputText tk(insert 'end' "Loading... Please wait.")}
        {InputText bind(event:"<Control-s>" action:CallPress)} % You can also bind events
        {OutputText set("You must wait until the database is parsed.\nA message will notify you.\nDon't press the 'predict' button until the message appears!\n")}

        %%% On créer le Port %%%
        SeparatedWordsPort = {NewPort SeparatedWordsStream}
        
        %%% On lance les threads de lecture et de parsing %%%
        {LaunchThreads SeparatedWordsPort NbThreads}

        %%% On créer l'arbre principale avec tout les sous-arbres en valeur ***
        List_Port = {Get_Nth_FirstElem_Port SeparatedWordsStream NberFiles}
        
        {OutputText tk(insert p(6 0) "Step 1 Over : Reading + Parsing\n")} % Pour la position, c'est du test essais-erreur

        Basic_Tree = {CreateTree List_Port}
        Main_Tree = {TraverseAndChange Basic_Tree}
        Tree_Over = true

        {OutputText tk(insert p(7 0) "Step 2 Over : Stocking datas\n")} % Pour la position, c'est du test essais-erreur
        {OutputText tk(insert p(9 0) "The database is now parsed.\nYou can write and predict!")} % Pour la position, c'est du test essais-erreur
        {InputText set("")}
        
        end
        
        %%ENDOFCODE%%
    end

    % Appelle la procedure principale
    {Main}
end