functor
import
    System

    Function at 'function.ozf'
export
    CreateSubtree
    CreateTree
    LookingUp
    Insert
    TraverseAndChange
    TraverseToGetProbability
define

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
    fun {UpdateList List NewElem}
        local
            fun {UpdateList_Aux List NewList NewElem}
                case List
                of notfound then (NewElem#1)|nil % Special case if the List of value hasn't be found in the tree
                [] nil then (NewElem#1)|NewList
                [] H|T then 
                    case H 
                    of H1#H2 then 
                        if H1 == NewElem then (H1#(H2+1))|{Function.append_List T NewList}
                        else {UpdateList_Aux T H|NewList NewElem} end 
                    end
                end
            end
        in
            {UpdateList_Aux List nil NewElem}
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
        local
            fun {BiGrams_Aux List NewList}
                case List
                of nil then NewList
                [] H|nil then NewList
                [] H|T then
                    {BiGrams_Aux T {String.toAtom {Function.append_List H 32|T.1}}|NewList}
                end
            end
        in
            {Reverse {BiGrams_Aux List nil}}
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

            %%%
            % Creates a part of the complete binary tree structure (to store the datas)
            %
            % Example usage:
            % In: L = [["i am the boss man"] ["no problem sir"] ["the boss is here"] ["the boss is here"]]
            % Out: tree(key:'i am' value:['the'#1] t_left:tree(key:'boss is' value:['here'#2] t_left:
            %      tree(key:'am the' value:['boss'#1] t_left:leaf t_right:leaf) t_right:leaf) t_right:
            %      tree(key:'no problem' value:['sir'#1] t_left:leaf t_right:tree(key:'the boss' value:['man'#1 'is'#2] t_left:leaf t_right:leaf)))
            %
            % @param List_Line: a list of lists of strings representing a line parsed (from a file)
            % @param NewTree: the new binary tree initialized to 'leaf' that will be update
            % @return: the new binary tree with some datas added
            %%%
            fun {Update_Tree List_Line NewTree}
                case List_Line
                of nil then NewTree
                [] H|T then
                    {Update_Tree T {UpdateElementsOfTree NewTree {BiGrams {Function.tokens_String H 32}}}}
                end
            end

            fun {CreateTree_Aux List_List_Line UpdaterTree NewTree}
                case List_List_Line
                of nil then NewTree
                [] H|T then
                    {CreateTree_Aux T UpdaterTree {UpdaterTree H NewTree}}
                end
            end
        in
            {CreateTree_Aux List_List_Line fun {$ List_Line NewTree} {Update_Tree List_Line NewTree} end leaf}
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
    fun {TraverseAndChange Tree UpdaterTree_ChangerValue}
        local
            fun {TraverseAndChange_Aux Tree UpdatedTree}
                case Tree
                of leaf then UpdatedTree
                [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
                    local T1 T2 in
                        T1 = {TraverseAndChange_Aux TLeft {UpdaterTree_ChangerValue UpdatedTree Key Value}}
                        T2 = {TraverseAndChange_Aux TRight T1}
                    end
                end
            end
        in
            {TraverseAndChange_Aux Tree Tree}
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
            if Tree == leaf then [[nil] 0.0]
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

end