functor
import
    Function at 'function.ozf'
    N_grams at 'extensions/n_grams.ozf'
export
    %% Usefull functions to search in a tree or replace a value in a tree (= update the tree) %%
    LookingUp
    Insert_Value
    Insert_Key
    
    %% Usefull functions to create the tree structure %%
    Create_Basic_Tree
    Create_Main_Tree

    %% Usefull functions to get the result of the prediction %%
    Get_Result_Prediction
define


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%% Function very usefull to create the all tree structure %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
        [] tree(key:K value:V t_left:_ t_right:_) andthen K == Key then V

        [] tree(key:K value:V t_left:TLeft t_right:_) andthen K > Key then
            {LookingUp TLeft Key}

        [] tree(key:K value:V t_left:_ t_right:TRight) andthen K < Key then
            {LookingUp TRight Key}
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
    fun {Insert_Value Tree Key Value}
        case Tree
        of leaf then tree(key:Key value:Value t_left:leaf t_right:leaf)

        [] tree(key:K value:_ t_left:TLeft t_right:TRight) andthen K == Key then
            tree(key:K value:Value t_left:TLeft t_right:TRight)

        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K < Key then
            tree(key:K value:V t_left:TLeft t_right:{Insert_Value TRight Key Value})

        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K > Key then
            tree(key:K value:V t_left:{Insert_Value TLeft Key Value} t_right:TRight)
        end
    end

    %%%
    % Exactly the same as Insert, but with a new key to insert and not a value.
    % See documentation of Insert for more details.
    %%%
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


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%% Create the all tree structure => binary tree with binary tree as value %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    % Creates the all basic binary tree structure (without the binary tree as value).
    %
    % Example usage:
    % In: [[["je suis d'accord avec toi"] ["evidemment que oui"]]  [[...] [...] ...] ...]
    % Out: tree(key:'je suis' value:['d'accord']
    %                         t_left:tree(key:'evidement que' value:['oui']
    %                             t_left:tree(key:'je suis' value:['d'accord']
    %                                  t_left:leaf
    %                                  t_right:leaf)
    %                             t_right:leaf)
    %                         t_right:tree(key:'suis d'accord' value:['avec'] t_left:leaf t_right:leaf) t_right:leaf))
    %             
    % @param Parsed_Datas: a list composed of lists of lists of strings
    % @return: the all binary tree with all the datas added
    %%%
    fun {Create_Basic_Tree Parsed_Datas}
        local

            %%%
            % Updates the values of the tree at the key X (where X is an element of 'List_Keys')
            % with the new values (correspond to the next word).
            % This function is generalized to be used with any number of N-grams.
            %
            % Example usage (simplified):
            % List_Keys = ['i am' 'am happy']
            % The value of the tree at the key 'i am' is updated with the new value 'happy'
            % 
            % @param Tree: a binary tree
            % @param List_Keys: a list of keys to access the value to update
            % @return: a new tree with the new values updated
            %%%
            fun {Update_Values_Tree Tree List_Keys}
                case List_Keys
                of nil then Tree
                [] _|nil then Tree
                [] H|T then
                    local Key Value_to_Insert Current_List_Value New_List_Value in
                        % The key to access the value to update
                        Key = {String.toAtom H}

                        % The new value to insert into the tree at the specified key
                        Value_to_Insert = {String.toAtom {Reverse {Function.tokens_String T.1 32}}.1}

                        % The current value of the tree at the key H
                        Current_List_Value = {LookingUp Tree Key}

                        % The new list of values with the new value corrected inserted
                        New_List_Value = {UpdateList Current_List_Value Value_to_Insert}

                        % The new tree with the new value inserted
                        {Update_Values_Tree {Insert_Value Tree Key New_List_Value} T}
                    end
                end
            end

            %%%
            % Deals with a line of the datas (a line is a list of lists of strings)
            % This function is generalized to be used with any number of N-grams.
            % This function applies, for every line in 'Line_Datas', the function 'Update_Values_Tree'
            % to the list of keys found with the function 'N_grams.n_grams'
            %
            % @param Updated_Tree: the tree to update
            % @param Line_Datas: a list of lists of strings
            % @return: a new tree with the new values updated
            %%%
            fun {Deal_File Updated_Tree Line_Datas}
                local
                    fun {Deal_File_Aux Line_Datas Updated_Tree}
                        case Line_Datas
                        of nil then Updated_Tree
                        [] H|T then
                            local List_Keys_N_grams Value_Updated in
                                List_Keys_N_grams = {N_grams.n_grams {Function.tokens_String H 32}}
                                Value_Updated = {Update_Values_Tree Updated_Tree List_Keys_N_grams}
                                {Deal_File_Aux T Value_Updated}
                            end
                        end
                    end
                in
                    {Deal_File_Aux Line_Datas Updated_Tree}
                end
            end

            %%%
            % Applies the function 'Deal_File' to every list of line (corresponding to one file) in 'Parsed_Datas'.
            %
            % @param Parsed_Datas: a list composed of lists of lists of strings
            % @param Updated_Tree: the tree to update
            % @return: a new tree with the new values updated
            %%%
            fun {Create_Basic_Tree_Aux Parsed_Datas Updated_Tree}
                case Parsed_Datas
                of nil then Updated_Tree
                [] H|T then
                    {Create_Basic_Tree_Aux T {Deal_File Updated_Tree H}}
                end
            end
        in
            {Create_Basic_Tree_Aux Parsed_Datas leaf}
        end
    end
  

    %%%
    % Traverse a binary tree in a Pre-Order traversal to update all the values of the tree.
    %
    % Example usage: 
    % In: Tree = tree(key:5 value:['ok'#1] t_left:tree(key:3 value:['must'#2 'okay'#1] t_left:leaf t_right:leaf) t_right:leaf)
    % Out: tree(key:5 value:tree(key:1 value:['ok'] t_left:leaf t_right:leaf) t_left:tree(key:2 value:tree(key: value:['okay'] t_left:tree(key:1 value:['must'] t_left:leaf t_right:leaf) t_right:leaf) t_left:leaf t_right:leaf) t_right:leaf)
    %
    % @param Tree: a binary tree
    % @return: a new binary tree where each of these value has been updated by UpdaterTree_ChangerValue
    %%%
    fun {Create_Main_Tree Tree}
        local
            Updater_Values = fun {$ Updated_Tree Key Value} {Insert_Value Updated_Tree Key {Create_SubTree Value}} end

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
            fun {Create_SubTree List_Value}
                local
                    fun {Create_SubTree_Aux List_Value SubTree}
                        case List_Value
                        of nil then SubTree
                        [] H|T then
                            case H
                            of Word#Freq then
                                local Current_Value in
                                    Current_Value = {LookingUp SubTree Freq}
                                    if Current_Value == notfound then {Create_SubTree_Aux T {Insert_Value SubTree Freq [Word]}}
                                    else {Create_SubTree_Aux T {Insert_Value SubTree Freq Word|Current_Value}} end
                                end
                            end
                        end
                    end
                in
                    {Create_SubTree_Aux List_Value leaf}
                end
            end

            fun {Create_Main_Tree_Aux Tree Updated_Tree}
                case Tree
                of leaf then Updated_Tree
                [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
                    local T1 in
                        T1 = {Create_Main_Tree_Aux TLeft {Updater_Values Updated_Tree Key Value}}
                        _ = {Create_Main_Tree_Aux TRight T1}
                    end
                end
            end
        in
            {Create_Main_Tree_Aux Tree Tree}
        end
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%% Functions to do a Traversal of the tree to get the prediction %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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
    fun {Get_Result_Prediction Tree Prefix_Value}
        local
            % Usefull variables to make it easier to understand the code
            List_Result Total_Frequency Max_Frequency List_Words Probability

            fun {Get_Result_Prediction_Aux Tree Total_Freq Max_Freq List_Words}
                case Tree
                of leaf then [Total_Freq Max_Freq List_Words]
                [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
                    local NewList_Value T1 in
                        if Prefix_Value == none then
                            T1 = {Get_Result_Prediction_Aux TLeft Total_Freq Max_Freq List_Words}
                            _ = {Get_Result_Prediction_Aux TRight ({Length Value} * Key)+T1.1 Key Value}
                        else
                            T1 = {Get_Result_Prediction_Aux TLeft Total_Freq Max_Freq List_Words}

                            NewList_Value = {GetNewListValue Value Prefix_Value}
                            if NewList_Value == nil then
                                _ = {Get_Result_Prediction_Aux TRight ({Length Value} * Key)+T1.1 Max_Freq List_Words}
                            else
                                _ = {Get_Result_Prediction_Aux TRight ({Length Value} * Key)+T1.1 Key NewList_Value}
                            end
                        end
                    end
                end
            end
        in
            List_Result = {Get_Result_Prediction_Aux Tree 0 0 nil}
            Total_Frequency = List_Result.1
            Max_Frequency = List_Result.2.1
            List_Words = List_Result.2.2.1
            Probability = {Int.toFloat Max_Frequency} / {Int.toFloat Total_Frequency}
            [List_Words Probability Max_Frequency] % Return all the necessary information that we need in {Press}
        end
    end


    %%%
    % Get the new list of words that are in the list Value and that have the prefix Prefix_Value.
    % If there is no word in Value that has the prefix Prefix_Value, then return nil.
    %
    % Example usage:
    % In: Value = ['ok' 'must' 'okay' 'perfect' 'back']  Prefix_Value = 'o'
    % Out: ['ok' 'okay']
    %
    % @param Value: a list of atoms (words)
    % @param Prefix_Value: an atom
    % @return: a list of atoms (words) with all the atoms that have the prefix Prefix_Value
    %%%
    fun {GetNewListValue Value Prefix_Value}
        local
            fun {GetNewListValue_Aux List_Value_Tree NewList}
                case List_Value_Tree
                of nil then NewList
                [] H|T then
                    if {Function.findPrefix_InList {Atom.toString H} Prefix_Value} == true then {GetNewListValue_Aux T H|NewList}
                    else {GetNewListValue_Aux T NewList} end
                end
            end
        in
            {GetNewListValue_Aux Value nil}
        end
    end
    
end