functor
import 
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    Open
    OS
    Property
    Browser
define
    
	InputText OutputText TweetsFolder_List Tree % Global variables

    %%% Class used to open the files
    class TextFile
        from Open.file Open.text
    end

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
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K == Key
            then tree(key:Key value:Value t_left:TLeft t_right:TRight)
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K < Key
            then tree(key:K value:V t_left:TLeft t_right:{Insert TRight Key Value})
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen K > Key
            then tree(key:K value:V t_left:{Insert TLeft Key Value} t_right:TRight)
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


    %%% MAIN TREE FUNCTIONS END %%%

    %%% LIST (SUBTREE) FUNCTIONS BEGIN %%%

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


    %%% LIST (SUBTREE) FUNCTIONs END %%%

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
                
                NewValue = {CreateSubtree leaf Value}
                NewTree = {Insert CopyTree Key NewValue}
                
                T1 = {TraverseAndChange TLeft NewTree}
                T2 = {TraverseAndChange TRight T1}
                
            end
        end
    end


    %%% Create the filename "tweets/part_N.txt" where N is given in argument
    fun {GetFilename List_PathName Idx}
        {List.nth List_PathName Idx}
    end
    % {Browse {String.toAtom {GetFilename 1}}} % "tweets/part_1.txt"

    fun {RemoveFirstLetter Str}
        Str.2
    end

    fun {ReplaceList List Str}
        case List
        of nil then Str
        [] H|nil then Str
        [] H|T then
            {ReplaceList T {Append H {RemoveFirstLetter T.1}}}
        end
    end

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

    fun {RemovePartString Str Delimiter Length_Delimiter NextCharRemoveToo}
        local
            fun {RemovePartString_Aux Str Delimiter Length_Delimiter NextCharRemoveToo}
                case Str
                of nil then nil
                [] H|T then
                    if {FindDelimiter T Delimiter} == true then
                        if NextCharRemoveToo == true then
                            %%% Si on veut séparer comme ceci : "didn't" en "didn t" et pas en "didnt", il faut faire
                            %%% H | 32 | {RemovePartString_Aux {GetListAfterNth T Length_Delimiter+1} Delimiter Length_Delimiter NextCharRemoveToo}
                            %%% à la place de la ligne en-dessous
                            H | {RemovePartString_Aux {GetListAfterNth T Length_Delimiter+1} Delimiter Length_Delimiter NextCharRemoveToo}
                        else
                            H | {RemovePartString_Aux {GetListAfterNth T Length_Delimiter} Delimiter Length_Delimiter NextCharRemoveToo}
                        end
                    else
                        H | {RemovePartString_Aux T Delimiter Length_Delimiter NextCharRemoveToo}
                    end
                end
            end
        in
            if {FindDelimiter Str Delimiter} == true then
                if NextCharRemoveToo == true then
                    %%% Si on veut séparer comme ceci : "didn't" en "didn t" et pas en "didnt", il faut faire
                    %%% H | 32 | {RemovePartString {GetListAfterNth T Length_Delimiter+1} Delimiter Length_Delimiter NextCharRemoveToo}
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

    % Faudra aussi remove la lettre d'après car les délimiteur sont :
    % Delimiteur1 = "â\x80\x99" (représente ')
    % Delimiteur2 = "â\x80\x9C" (représente " d'un côté)
    % Delimiteur3 = "â\x80\x9D" (représente " de l'autre côté)
    fun {CleanUp LineStr}
        {RemovePartString LineStr [226 128] 2 true} % [226 128] représente "â\x80\x9" (trouvé après des tests)
    end

    %%% Create a list with all line of the file named "Filename"
    fun {Reader Filename}
        fun {GetLine TextFile}
            Line = {TextFile getS($)}
        in
            if Line == false then
                {TextFile close}
                nil
            else
                {CleanUp Line} | {GetLine TextFile}
            end
        end
    in
        {GetLine {New TextFile init(name:Filename flags:[read])}}
    end
    % {Browse {Reader {GetFilename 1}}} % une liste avec ttes les lignes du fichier 1


    fun {ParseAllLines List}
        case List
        of nil then nil
        [] H|T then
            {RemoveEmptySpace {ParseLine H}} | {ParseAllLines T}
        end
    end

    fun {RemoveEmptySpace Line}
        local
            fun {RemoveEmptySpaceAux Line PreviousSpace}
                case Line
                of nil then nil
                [] H|T then
                    if H == 32 andthen PreviousSpace then
                        {RemoveEmptySpaceAux T true}
                    else
                        if H == 32 then
                            H | {RemoveEmptySpaceAux T true}
                        else
                            H | {RemoveEmptySpaceAux T false}
                        end
                    end
                end
            end
        in
            {RemoveEmptySpaceAux Line false}
        end
    end

	
	fun {CreateList Start End}
		if End >= Start then
			Start | {CreateList Start+1 End}
		else
			nil
		end
	end

	fun {IsInList List Value}
		case List
		of nil then false
		[] H|T then
			if H == Value then true
			else
				{IsInList T Value}
			end
		end
	end

    % Replaces special caracters by a space (== 32 in ASCII) and letters to lowercase
    fun {ParseLine Line}

		local ListMin ListMaj ListChiffre in
			ListMaj = {CreateList 65 90}
			ListMin = {CreateList 97 122}
			ListChiffre = {CreateList 48 57}

			case Line
			of H|T then
                local New_H in
                    if {IsInList ListMin H} == true then
                        New_H = H
                    elseif {IsInList ListMaj H} == true then
                        New_H = H + 32
                    elseif {IsInList ListChiffre H} == true then
                        New_H = H
                    else
                        New_H = 32
                    end
                    New_H | {ParseLine T}
                end
			[] nil then nil
			end
		end
    end
    % {Browse {ParseLine "FLATTENING OF THE CURVE!"}} % "flattening of the curve "


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
		
		local TreeMaxFreq SplittedText BeforeLast Last Key Tree_Value Word_To_Display in
            
			SplittedText = {String.tokens {InputText getText(p(1 0) 'end' $)} & }
			Last = {String.tokens {List.last SplittedText} &\n}.1
			BeforeLast = {List.nth SplittedText {List.length SplittedText} - 1}

			Key = {String.toAtom {List.append {List.append BeforeLast [32]} Last}}
			Tree_Value = {LookingUp Tree Key}
			
            TreeMaxFreq = {GetTreeMaxFreq Tree_Value}
            {Browse Tree_Value}

            if TreeMaxFreq == leaf then
                [none 0]
            else
                {Browse TreeMaxFreq.value}
                {Browse TreeMaxFreq.key}
                [TreeMaxFreq.value TreeMaxFreq.key]
            end
		end
    end

	proc {CallPress}
		local List_To_Display ProbableWords MaxFreq in

			List_To_Display = {Press}

            ProbableWords = List_To_Display.1
            MaxFreq = List_To_Display.2

            if ProbableWords == none then
                {OutputText set("NO WORD FIND!")} % Que faire dans ce cas ?
            else
                {OutputText set(ProbableWords.1)}
            end
		end
	end

    proc {ListAllFiles L}
        case L
        of nil then skip
        [] H|T then
            {Browse {String.toAtom H}} {ListAllFiles T}
        end
    end

    %%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
    %%% Les threads de parsing envoient leur resultat au port Port
    proc {LaunchThreads Port N}
        
        local NberFiles Basic_Nber_Iter Rest_Nber_Iter Current_Nber_Iter in

            NberFiles = 208
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

                        local File_1 File ThreadReader ThreadParser L P in
                               
                            File_1 = {GetFilename TweetsFolder_List Y}
                            File = {Append "tweets/" File_1} %% DE BASE => Ne devrait pas avoir cette ligne je pense
                            thread ThreadReader = {Reader File} L=1 end
                            thread {Wait L} ThreadParser = {ParseAllLines ThreadReader} P=1 end
                            {Wait P}
                            {Send Port ThreadParser}

                        end
                    end
                end
            end
        end
    end


    fun {Get_Nth_Elem_Port Stream_Port N}
        local
            fun {Get_Nth_Elem_Port_Aux Stream_Port Acc N}
                if N == 0 then nil
                else
                    case Stream_Port
                    of H|T then
                        {List.append H {Get_Nth_Elem_Port_Aux T Acc+1 N-1}}
                    end
                end
            end
        in
            {Get_Nth_Elem_Port_Aux Stream_Port 1 N}
        end
    end

    %%% Fetch Tweets Folder from CLI Arguments
    %%% See the Makefile for an example of how it is called
    fun {GetSentenceFolder}
        Args = {Application.getArgs record('folder'(single type:string optional:false))}
    in
        Args.'folder'
    end

    %%% Procedure principale qui cree la fenetre et appelle les differentes procedures et fonctions
    proc {Main}
        
        TweetsFolder_List = {OS.getDir {GetSentenceFolder}}

        %% Fonction d'exemple qui liste tous les fichiers
        %% contenus dans le dossier passe en Argument.
        %% Inspirez vous en pour lire le contenu des fichiers
        %% se trouvant dans le dossier
        %%% N'appelez PAS cette fonction lors de la phase de
        %%% soumission !!!
        % {ListAllFiles TweetsFolder_List}

        local List_Port ParsedListLines FirstTree File Line ParsedLine PressCaller List_Press NbThreads Window Description SeparatedWordsStream SeparatedWordsPort in
        {Property.put print foo(width:1000 depth:1000)}  % for stdout siz

        % Creation de l interface graphique
        Description=td(
            title: "Text predictor"
            lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:CallPress))
            text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
            action:proc{$} {Application.exit 0} end % Quitte le programme quand la fenetre est fermee
            )
        
        % Creation de la fenetre
        Window = {QTk.build Description}
        {Window show}
        
        % {InputText tk(insert 'end' "Loading... Please wait.")}
        {InputText bind(event:"<Control-s>" action:CallPress)} % You can also bind events

        %%% On créer le Port %%%
        SeparatedWordsPort = {NewPort SeparatedWordsStream}
        NbThreads = 10
        
        %%% On lance les threads de lecture et de parsing %%%
        {LaunchThreads SeparatedWordsPort NbThreads}
        {Browse 'OVER : Reading + Parsing'}

        %%% On créer l'arbre principale avec tout les sous-arbres en valeur ***
        List_Port = {Get_Nth_Elem_Port SeparatedWordsStream 208}
        FirstTree = {CreateTree leaf List_Port}
        Tree = {TraverseAndChange FirstTree FirstTree}
        {Browse 'OVER : Creating Structure'}
        end
    end

    % Appelle la procedure principale
    {Main}
end