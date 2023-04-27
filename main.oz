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
    % In : "tweets/part_1.txt"
    % Out : ["Congress must..." "..." "..." "..." "..."]
    %
    % @param Filename : a string representing the path to the file
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
                {CleanUp Line}|{GetLine TextFile}
            end
        end
    in
        {GetLine {New TextFile init(name:Filename flags:[read])}}
    end

    %%%
    % Creates a filename by combining the name of a folder and the nth filename in a list of filenames
    %
    % Example usage:
    % In : "tweets" ["part_1.txt" "part_2.txt"] 2
    % Out : "tweets/part_2.txt"
    %
    % @param TweetsFolder_Name : a string representing the name of a folder
    % @param List_PathName : a list of filenames
    % @param Idx : an index representing the position of the desired filename in List_PathName
    % @return : a string representing the desired filename (the Idxth filename in the list) preceded by the folder name + "/"
    %%%
    fun {GetFilename TweetsFolder_Name List_PathName Idx}
        local PathName in
            PathName = {List.nth List_PathName Idx}
            {Append {Append TweetsFolder_Name "/"} PathName}
        end
    end

    %%% ================= PARSING ================= %%%
    %%% ================= PARSING ================= %%%

    %%%
    % TODO doc
    %%%
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

    %%%
    % TODO doc
    %%%
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

    %%%
    % TODO doc
    %%%
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

    %%%
    % TODO doc
    %%%
    % Faudra aussi remove la lettre d'après car les délimiteur sont :
    % Delimiteur1 = "â\x80\x99" (représente ')
    % Delimiteur2 = "â\x80\x9C" (représente " d'un côté)
    % Delimiteur3 = "â\x80\x9D" (représente " de l'autre côté)
    fun {CleanUp LineStr}
        {RemovePartString LineStr [226 128] 2 true} % [226 128] représente "â\x80\x9" (trouvé après des tests)
    end

    %%%
    % Applies a parsing function to each string in a list of strings
    %
    % Example usage:
    % In : ["  _&Hello there...! General Kenobi!!! %100 "]
    % Out : ["hello there general kenobi 100"] if Parser = fun {$ StrLine} {RemoveEmptySpace {ParseLine Str_Line}} end
    %
    % @param List : a list of strings
    % @param Parser : a function that takes a string as input and returns a parsed version of it
    % @return : a list of the parsed strings
    %%%
    fun {ParseAllLines List Parser}
        case List
        of nil then nil
        [] H|T then
            {Parser H} | {ParseAllLines T Parser}
        end
    end

    %%%
    % TODO doc
    %%%
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
    % In : "  general    kenobi       you are a           bold   one   "
    % Out : "general kenobi you are a bold one"
    %
    % @param Line : a string to be cleaned of unnecessary spaces.
    % @return : a new string with all excess spaces removed
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
    % Replaces special caracters by a space (== 32 in ASCII) and set all letters to lowercase
    % Don't touch to the digits

    % Example usage:
    % In : "FLATTENING OF THE CURVE!"
    % Out : "flattening of the curve "
    %
    % @param Line : a string ..... TODO
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
                New_H | {ParseLine T}
            end
        [] nil then nil
        end
    end
    

    %%% ================= TREE STRUCTURE ================= %%%
    %%% ================= TREE STRUCTURE ================= %%%

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

    %%%
    % Searchs a value recursively in a binary tree using its key
    %
    % @Tree : a binary tree
    % @Key : a value that represents a specific location in the binary tree
    % @return : the value at the location of the key
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
    % Inserts a value in a binary tree at the location of key
    %
    % @Tree : a binary tree
    % @Key : a value that represents a specific location in the binary tree and binded to Value
    % @Value : the value we want to insert in the tree
    % @return : the new updated Tree
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

    %%%
    % Updates a list with the frequency of an element
    % If the element is not yet in the list, it is added with a frequency of 1
    % If the element is already in the list, its frequency is increased by 1
    % In : [1#1 2#1 3#1 4#1] 4
    % Out : [1#1 2#1 3#1 4#2]
    %
    % @L : a list of frequencies
    % @Ch : the element which frequency we want to update
    % @return : the new updated list
    %%%
    fun {UpdateList L Ch}
        case L 
        of nil then (Ch#1)|nil 
        [] H|T then 
            case H 
            of H1#H2 then 
                if H1 == Ch then (H1#(H2+1))|T 
                else H|{UpdateList T Ch} end 
            end
        end
    end

    %%%
    % Returns second word of a string
    % In : "i am"
    % Out : "am"
    %
    % @Str : a string / a list of ASCII characters
    % @return : Str trimmed from its first word
    %%%
    fun {SecondWord Str}
        case Str
        of 32|T then T
        [] H|T then
            {SecondWord T}
        end
    end

    %%%
    % Inserts ListBiGramme in Tree
    % TODO doc
    %%%
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

    %%%
    % Creates bigrammes from a list of words
    % In : ["i" "am" "hungry" "hello" "there"]
    % Out : ['i am' 'am hungry' 'hungry hello' 'hello there']
    % 
    % @List : a list of words
    % @return : a list of bigrammes of input words
    %%%
    fun {BiGramme List}
        case List
        of nil then nil
        [] H|nil then nil
        [] H|T then
            {String.toAtom {Append {Append H [32]} T.1}}|{BiGramme T}
        end
    end

    %%%
    % Creates the main tree
    % In : L = [['i am the boss'] ['no problem sir']]
    %
    % @Tree : a binary tree
    % @L : a list of lists of a string
    % @return : the new updated binary tree
    %%%
    fun {CreateTree Tree L}
        case L
        of nil then Tree
        [] H|T then
            {CreateTree {AddLineToTree Tree {BiGramme {String.tokens H 32}}} T}
        end
    end

    %%%
    % Creates the subtrees
    % In : List_Value = [back#2 must#1 ok#3]
    %
    % @SubTree : a binary tree
    % @List_Value : a list of tuples
    % @return : the new updated binary tree
    %%%
    fun {CreateSubtree SubTree List_Value}
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

    %%%
    % TODO doc
    %%%
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

    %%%
    % TODO doc
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
    % TODO doc
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
            
            if {List.length SplittedText} < 2 then % Pourrait optimisé pour ne pas devoir appelé List.length
                none
            else
                Last = {String.tokens {List.last SplittedText} &\n}.1
                BeforeLast = {List.nth SplittedText {List.length SplittedText} - 1}
                
                Key = {String.toAtom {List.append {List.append BeforeLast [32]} Last}}
                Tree_Value = {LookingUp Main_Tree Key}
                
                % {System.show Tree_Value}

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
    % TODO doc
    %%%
	proc {CallPress}
		local ResultPress ProbableWords MaxFreq in
            
            % But de Tree_Over : bloquer le programme le temps que la structure soit crée!
            if Tree_Over == true then

                ResultPress = {Press}

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

    % proc {ListAllFiles L}
    %     case L
    %     of nil then skip
    %     [] H|T then
    %         {Browse {String.toAtom H}} {ListAllFiles T}
    %     end
    % end

    %%%
    % TODO doc
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
    % TODO doc
    %%%
    fun {Get_Nth_FirstElem_Port Stream_Port N}
        local
            fun {Get_Nth_FirstElem_Port Stream_Port Acc N}
                if N == 0 then nil
                else
                    case Stream_Port
                    of H|T then
                        {List.append H {Get_Nth_FirstElem_Port T Acc+1 N-1}}
                    end
                end
            end
        in
            {Get_Nth_FirstElem_Port Stream_Port 1 N}
        end
    end

    %%%
    % TODO doc
    %%%
    %%% Fetch Tweets Folder from CLI Arguments
    %%% See the Makefile for an example of how it is called
    fun {GetSentenceFolder}
        Args = {Application.getArgs record('folder'(single type:string optional:false))}
    in
        Args.'folder'
    end



    %%% Procedure principale qui cree la fenetre et appelle les differentes procedures et fonctions
    proc {Main}
        
        TweetsFolder_Name = {GetSentenceFolder}
        List_PathName_Tweets = {OS.getDir TweetsFolder_Name}

        NberFiles = {List.length List_PathName_Tweets}
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

        Basic_Tree = {CreateTree leaf List_Port}
        Main_Tree = {TraverseAndChange Basic_Tree Basic_Tree}
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