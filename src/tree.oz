functor
import
    System
    Function at 'function.ozf'
    Extensions at 'extensions.ozf'
export
    CreateSubTree
    CreateTree
    LookingUp
    Insert
    UpdateAll_Tree
    Update_Line_To_Tree
    Get_Result_Prediction
    Insert_Key
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
    fun {LookingUp Tree Key Prefix_Value}
        local
            fun {LookingUp_Aux Tree Key KeyToReturn}
                case Tree
                of leaf then KeyToReturn
                [] tree(key:K value:V t_left:_ t_right:_) andthen K == Key then
                    if Prefix_Value == none then V
                    else
                        if {Function.findPrefix_InList V Prefix_Value} then V
                        else KeyToReturn end
                    end

                [] tree(key:K value:V t_left:TLeft t_right:_) andthen K > Key then
                    if Prefix_Value == none then {LookingUp_Aux TLeft Key KeyToReturn}
                    else
                        if {Function.findPrefix_InList V Prefix_Value} then {LookingUp_Aux TLeft Key K}
                        else {LookingUp_Aux TLeft Key KeyToReturn} end
                    end

                [] tree(key:K value:V t_left:_ t_right:TRight) andthen K < Key then
                    if Prefix_Value == none then {LookingUp_Aux TRight Key KeyToReturn}
                    else
                        if {Function.findPrefix_InList V Prefix_Value} then {LookingUp_Aux TRight Key K}
                        else {LookingUp_Aux TRight Key KeyToReturn} end
                    end
                end
            end
        in
            {LookingUp_Aux Tree Key notfound}
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
            tree(key:K value:Value t_left:TLeft t_right:TRight)

        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K < Key then
            tree(key:K value:V t_left:TLeft t_right:{Insert TRight Key Value})

        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K > Key then
            tree(key:K value:V t_left:{Insert TLeft Key Value} t_right:TRight)
        end
    end

    %%% TODO
    fun {Insert_Key Tree Key NewKey}
        case Tree
        of leaf then tree(key:Key value:Value t_left:leaf t_right:leaf)

        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K == Key then
            tree(key:NewKey value:V t_left:TLeft t_right:TRight)

        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K < Key then
            tree(key:K value:V t_left:TLeft t_right:{Insert_Key TRight Key NewKey})

        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K > Key then
            tree(key:K value:V t_left:{Insert_Key TLeft Key NewKey} t_right:TRight)
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
            fun {UpdateList_Aux List NewList}
                case List
                of notfound then (NewElem#1)|nil % If the List of value hasn't be found in the tree
                [] nil then (NewElem#1)|NewList % If the value hasn't be found in the list => add element with frequency of one
                [] H|T then
                    case H 
                    of Word#Frequency then
                        if Word == NewElem then (Word#(Frequency+1))|{Function.append_List T NewList}
                        else {UpdateList_Aux T H|NewList} end 
                    end
                end
            end
        in
            {UpdateList_Aux List nil}
        end
    end


    % Creates the all binary tree structure (to store the datas).
    % To do it, the function 'Update_Tree' is applied on all
    % the element of the list given as parameter.
    %
    % Check the docstring of 'Update_Tree' to see an example usage.
    %
    % @param Parsed_Datas: a list composed of lists of lists of strings
    % @return: the all binary tree with all the datas added
    %%%
    fun {CreateTree Parsed_Datas}
        local
            fun {CreateTree_Aux Parsed_Datas Updated_Tree}
                case Parsed_Datas
                of nil then Updated_Tree
                [] H|T then
                    {CreateTree_Aux T {Update_File_To_Tree Updated_Tree H}}
                end
            end
        in
            {CreateTree_Aux Parsed_Datas leaf}
        end
    end


    %%%
    % Creates a part of the complete binary tree structure (to store the datas)
    %
    % Example usage:
    % In: L = [["i am the boss man"] ["no problem sir"] ["the boss is here"] ["the boss is here"]]
    % Out: tree(key:'i am' value:['the'#1] t_left:tree(key:'boss is' value:['here'#2] t_left:
    %      tree(key:'am the' value:['boss'#1] t_left:leaf t_right:leaf) t_right:leaf) t_right:
    %      tree(key:'no problem' value:['sir'#1] t_left:leaf t_right:tree(key:'the boss' value:['man'#1 'is'#2] t_left:leaf t_right:leaf)))
    %
    % @param Parsed_Datas: a list of lists of strings representing a line parsed (from a file)
    % @param NewTree: the new binary tree initialized to 'leaf' that will be update
    % @return: the new binary tree with some datas added
    %%%
    fun {Update_File_To_Tree Updated_Tree Parsed_Datas}
        local
            fun {Update_File_To_Tree_Aux Parsed_Datas Updated_Tree}
                case Parsed_Datas
                of nil then Updated_Tree
                [] H|T then
                    {Update_File_To_Tree_Aux T {Update_Line_To_Tree Updated_Tree {Extensions.n_Grams {Function.tokens_String H 32}}}}
                end
            end
        in
            {Update_File_To_Tree_Aux Parsed_Datas Updated_Tree}
        end
    end
    
    
    %%%
    % Applies the function 'Update_Value' on all the keys of the keys list
    %%%
    fun {Update_Line_To_Tree Tree List_Keys}
        local
            %%%
            % Changes the value with a new specified one at the location of a specified key in a binary tree
            %%%
            fun {Update_Value Tree Key List_Keys}
                local Value_to_Insert List_Value New_List_Value in
                    Value_to_Insert = {String.toAtom {Reverse {Function.tokens_String List_Keys.1 32}}.1}
                    List_Value = {LookingUp Tree Key none}
                    New_List_Value = {UpdateList List_Value Value_to_Insert}
                    {Insert Tree Key New_List_Value}
                end
            end
        in
            case List_Keys
            of nil then Tree
            [] _|nil then Tree
            [] H|T then
                {Update_Line_To_Tree {Update_Value Tree {String.toAtom H} T} T}
            end
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
    fun {CreateSubTree List_Value}
        local
            fun {CreateSubTree_Aux List_Value SubTree}
                case List_Value
                of nil then SubTree
                [] H|T then
                    case H
                    of Word#Freq then
                        local Current_Value Updated_Value in
                            Current_Value = {LookingUp SubTree Freq none}
                            if Current_Value == notfound then
                                Updated_Value = [Word]
                            else
                                Updated_Value = Word|Current_Value
                            end
                            {CreateSubTree_Aux T {Insert SubTree Freq Updated_Value}}
                        end
                    end
                end
            end
        in
            {CreateSubTree_Aux List_Value leaf}
        end
    end

    %%%
    % Traverse a binary tree in a Pre-Order traversal to update the tree
    % A function Updater_Tree is used to update the tree
    % This function is mainly used to update the value of the tree
    %
    % Example usage: 
    % In: Tree = tree(key:5 value:['ok'#1] t_left:tree(key:3 value:['must'#2 'okay'#1] t_left:leaf t_right:leaf) t_right:leaf)
    %     UpdaterTree_ChangerValue = fun {$ Tree Key Value} {Insert Tree Key {CreateSubtree Value}} end
    % Out: tree(key:5 value:tree(key:1 value:['ok'] t_left:leaf t_right:leaf) t_left:tree(key:2 value:tree(key: value:['okay'] t_left:tree(key:1 value:['must'] t_left:leaf t_right:leaf) t_right:leaf) t_left:leaf t_right:leaf) t_right:leaf)
    %
    % @param Tree: a binary tree
    % @param UpdaterTree_ChangerValue: a function that takes as input a tree, a key and a value and update the value at the specified key
    % @return: a new binary tree where each of these value has been updated by UpdaterTree_ChangerValue
    %%%
    fun {UpdateAll_Tree Tree Updater_Tree Condition Key_Where_Update}
        local
            fun {UpdateAll_Tree_Aux Tree Updated_Tree}
                case Tree
                of leaf then Updated_Tree
                [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
                    local T1 in
                        if {Condition Key_Where_Update Key} == true then
                            T1 = {UpdateAll_Tree_Aux TLeft {Updater_Tree Updated_Tree Key Value}}
                        else
                            T1 = {UpdateAll_Tree_Aux TLeft Updated_Tree}
                        end
                        _ = {UpdateAll_Tree_Aux TRight T1}
                    end
                end
            end
        in
            {UpdateAll_Tree_Aux Tree Tree}
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
    fun {Get_Result_Prediction Tree}
        local
            List_Result
            Total_Frequency
            Max_Frequency
            List_Words
            Probability
            fun {Get_Result_Prediction_Aux Tree Total_Freq Max_Freq List_Words}
                case Tree
                of leaf then [Total_Freq Max_Freq List_Words]
                [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
                    local T1 in
                        T1 = {Get_Result_Prediction_Aux TLeft ({Length Value} * Key) + Total_Freq Key Value}
                        _ = {Get_Result_Prediction_Aux TRight ({Length Value} * Key) + T1.1 Key Value}
                    end
                end
            end
        in
            List_Result = {Get_Result_Prediction_Aux Tree 0 0 nil}
            Total_Frequency = List_Result.1 div 2
            Max_Frequency = List_Result.2.1
            List_Words = List_Result.2.2.1
            Probability = {Int.toFloat Max_Frequency} / {Int.toFloat Total_Frequency}
            [List_Words Probability Max_Frequency] % Return all the necessary information that we need in {Press}
        end
    end
end