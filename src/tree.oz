functor
import
    Browser
    System
export
    CreateTree TraverseAndChange LookingUp GetTreeMaxFreq
define

    proc {Browse Buf}
        {Browser.browse Buf}
    end

    %%% MAIN TREE FUNCTIONS BEGIN %%%

    %%% Structure of the recursive binary tree : 
    %%%     obtree := leaf | obtree(Key Value Left Right)
    %%% Example : 
    %%%     T = tree(key:horse value:cheval
    %%%         tree(key:dog value:chien
    %%%         tree(key:cat value:chat leaf leaf)
    %%%         tree(key:elephant value:elephant leaf leaf))
    %%%     tree(key:mouse value:souris
    %%%         tree(key:monkey value:singe leaf leaf)
    %%%         tree(key:tiger value:tigre leaf leaf)))

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

    % fun {RemoveSmallest Tree}
    %     case Tree
    %     of leaf then none
    %     [] tree(key:K value:V t_left:TLeft t_right:TRight) then
    %         case {RemoveSmallest TLeft}
    %         of none then triple(TRight K V)
    %         [] triple(Tp Kp Vp) then
    %             triple(tree(key:K value:V t_left:Tp t_right:TRight) Kp Vp)
    %         end
    %     end
    % end

    % fun {Delete Tree Key}
    %     case Tree
    %     of leaf then leaf
    %     [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen Key == K then
    %         case {RemoveSmallest TRight}
    %         of none then TLeft
    %         [] triple(Tp Kp Vp) then
    %             tree(key:Kp value:Vp t_left:TLeft t_right:Tp)
    %         end
    %     [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen Key < K
    %         then tree(key:K value:V t_left:{Delete Key TLeft} t_right:TRight)
    %     [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen Key > K
    %         then tree(key:K value:V t_left:TLeft t_right:{Delete Key TRight})
    %     end
    % end


    fun {UpdateList L Ch}
        case L 
        of nil then (Ch#1)|nil 
        [] H|T then 
            case H 
            of H1#H2 then 
                if H1 == Ch then (H1#(H2+1))|T 
                else H | {UpdateList T Ch} end 
            end
        end
    end
    % {Browse {UpdateList [1#1 2#1 3#1 4#1] 4}} % Out : [1#1 2#1 3#1 4#2]


    fun {SecondWord L}
        case L
        of 32|T then T
        [] H|T then
            {SecondWord T}
        end
    end


    fun {AddLineToTree Tree ListBiGramme}

        case ListBiGramme
        of nil then Tree
        [] H|nil then Tree
        [] H|T then
            if T.1 \= nil andthen H \= nil then

                local List_Value Value_to_Insert Key NewList in

                    Key = H % ATOME : Représente un double mot (example 'i am' ou 'must go')
                    Value_to_Insert = {String.toAtom {SecondWord {Atom.toString T.1}}} % ATOME : Représente le prochain mot (example 'ready' ou 'now')
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

    fun {BiGramme List}
        case List
        of nil then nil
        [] H|nil then nil
        [] H|T then
            {String.toAtom {Append {Append H [32]} T.1}} | {BiGramme T}
        end
    end

    %%% Create the main Tree + all the SubTree
    %%% Pre : Tree is the main Tree
    %%%       L is a list of lists
    %%% Post : 
    %%% Example : L = [['i am the boss'] ['no problem sir']]   (Warning : In reality, it's a list of ASCII characters)
    fun {CreateTree Tree L}
        case L
        of nil then Tree
        [] H|T then
            {CreateTree {AddLineToTree Tree {BiGramme {String.tokens H 32}}} T}
        end
    end

    fun {CreateSubtree SubTree List_Value}
        % Value = [back#2 must#1 ok#3] (EXAMPLE)
        case List_Value
        of nil then SubTree
        [] H|T then
            case H
            of Word#Freq then
                local Value in
                    Value = {LookingUp SubTree Freq}
                    if Value == notfound then
                        {CreateSubtree {Insert SubTree Freq [Word]} T}
                    else
                        {CreateSubtree {Insert SubTree Freq {List.append Value [Word]}} T}
                    end
                end
            end
        end
    end

    % Tree = arbre de base
    % copyTree = arbre de base (c'est une référence) qui va être modifié petit à petit et renvoyer
    fun {TraverseAndChange Tree CopyTree}

        case Tree
        of leaf then CopyTree
        [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
            
            local NewValue NewTree T1 T2 in
                
               % Pre-Order traversal
                NewValue = {CreateSubtree leaf Value}
                NewTree = {Insert CopyTree Key NewValue}
                
                T1 = {TraverseAndChange TLeft NewTree}
                T2 = {TraverseAndChange TRight T1}
                
            end
        end
    end

    %%% FONCTIONNE PAS, JSP POURQUOI...
    % fun {TraverseAndChange Tree CopyTree}

    %     case Tree
    %     of leaf then CopyTree
    %     [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
            
    %         local NewValue NewTree T1 T2 in
                
    %             % Inorder traversal
    %             T1 = {TraverseAndChange TLeft CopyTree}

    %             NewValue = {CreateSubtree leaf Value}
    %             NewTree = {Insert CopyTree Key NewValue}

    %             T2 = {TraverseAndChange TRight NewTree}
                
    %         end
    %     end
    % end

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

end