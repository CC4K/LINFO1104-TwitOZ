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

	InputText OutputText Tree % Global variables

	%%% HELP SI BESOIN (mec discord) : Récursive terminale avec invariant
	%%% Perso je créé N arbres (N = nombre de threads) et pour chaque arbre je traite 208/N fichiers (plus exactement 208 % N pour tous sauf le dernier, qui est 208 - N * (208 % N))
	%%% Et pour chaque fichier, je traite chaque mot et je le rajoute à l'arbre jusqu'à atteindre la fin
	%%% Si ça t'aide, tu peux toujours réimplémenter les boucles while en récursive terminale

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
		else 
			nil
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

    fun {RemoveSmallest Tree}
        case Tree
        of leaf then none
        [] tree(key:K value:V t_left:TLeft t_right:TRight) then
            case {RemoveSmallest TLeft}
            of none then triple(TRight K V)
            [] triple(Tp Kp Vp) then
                triple(tree(key:K value:V t_left:Tp t_right:TRight) Kp Vp)
            end
        end
    end

    fun {Delete Tree Key}
        case Tree
        of leaf then leaf
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen Key == K then
            case {RemoveSmallest TRight}
            of none then TLeft
            [] triple(Tp Kp Vp) then
                tree(key:Kp value:Vp t_left:TLeft t_right:Tp)
            else
                none
            end
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen Key < K
            then tree(key:K value:V t_left:{Delete Key TLeft} t_right:TRight)
        [] tree(key:K value:V t_left:TLeft t_right:TRight) andthen Key > K
            then tree(key:K value:V t_left:TLeft t_right:{Delete Key TRight})
        end
    end

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
        else
            nil
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

            else
                Tree
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
        % Value = [back#2 must#1 ok#3]
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
    proc {TraverseAndChange Tree CopyTree ?R}

        case Tree
        of leaf then R = CopyTree
        [] tree(key:Key value:Value t_left:TLeft t_right:TRight) then
            
            local NewValue NewTree T1 in
                
                NewValue = {CreateSubtree leaf Value}
                NewTree = {Insert CopyTree Key NewValue}

                T1 = {TraverseAndChange TLeft NewTree}
                R = {TraverseAndChange TRight NewTree}
                
            end
        else
            R = CopyTree
        end
    end


    %%% Create the filename "tweets/part_N.txt" where N is given in argument
    fun {GetFilename N}
        local F1 F2 in
            F1 = "tweets/part_"
            F2 = {Append F1 {Int.toString N}}
            {Append F2 ".txt"}
        end
    end
    % {Browse {String.toAtom {GetFilename 1}}} % "tweets/part_1.txt"


    %%% Create a list with all line of the file named "Filename"
    fun {Reader Filename}
        fun {GetLine TextFile}
            Line = {TextFile getS($)}
        in
            if Line == false then
                {TextFile close}
                nil
            else
                Line | {GetLine TextFile}
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
                else
                    nil
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

        % [] H|T then                     % if capital or lowercase letter
        %     local New_H in
        %         if H < 97 then          % if capital letter
        %             if H == 32 then     % AND not a space
        %                 New_H = H
        %             else
        %                 New_H = H + 32  % switch to lowercase letter
        %             end
        %         else                    % else
        %             New_H = H           % keep the already lowercase letter
        %         end
        %         New_H | {ParseLine T}
        %     end
        
        % [] nil then nil
        % end
    end
    % {Browse {ParseLine "FLATTENING OF THE CURVE!"}} % "flattening of the curve "

	fun {GetWordMostFreq List_Value_Freq}
		local
			fun {GetWordMostFreqAux List_Value_Freq MaxFreq List_Word}
				case List_Value_Freq
				of notfound then [none 0]
				[] nil then
					[List_Word|nil MaxFreq]
				[] H|T then
					case H
					of W#F then
						if F >= MaxFreq then
							if List_Word == nil then % First iteration
								{GetWordMostFreqAux T F [W]}
							else
								{GetWordMostFreqAux T F List_Word|W}
							end
						else
							{GetWordMostFreqAux T MaxFreq List_Word}
						end
					end
				end
			end
		in
			{GetWordMostFreqAux List_Value_Freq 0 nil}
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
		
		local SplittedText BeforeLast Last Key List_Value Word_To_Display in

			SplittedText = {String.tokens {InputText getText(p(1 0) 'end' $)} & }
			Last = {String.tokens {List.last SplittedText} &\n}.1
			BeforeLast = {List.nth SplittedText {List.length SplittedText} - 1}
			% {Browse {String.toAtom Last}}
			% {Browse {String.toAtom BeforeLast}}
			
			Key = {String.toAtom {List.append {List.append BeforeLast [32]} Last}}
			% {Browse Key}

			List_Value = {LookingUp Tree Key}
			% {Browse List_Value}
			
			{GetWordMostFreq List_Value}.1
		end
    end

	proc {CallPress}
		local Word_To_Display in

			Word_To_Display = {Press}
			% {Browse Word_To_Display}
			% {Browse {List.is Word_To_Display}}
			% {Browse Word_To_Display.1}

			if Word_To_Display == none then
				{OutputText set("Error")} % you can get/set text this way too
			else
				% {Browse Word_To_Display.1.1}
				{OutputText set(Word_To_Display.1.1)} % you can get/set text this way too
			end

		end
	end


    %%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
    %%% Les threads de parsing envoient leur resultat au port Port
    proc {LaunchThreads Port N}
        for X in 1..N do
            local File ThreadReader ThreadParser ThreadSaver L P in
                File = {GetFilename X}
                thread ThreadReader = {Reader File} L=1 end
                thread {Wait L} ThreadParser = {ParseAllLines ThreadReader} P=1 end
                {Wait P}
                {Port.send Port ThreadParser}
            end
        end
    end


    %%% Fetch Tweets Folder from CLI Arguments
    %%% See the Makefile for an example of how it is called
    fun {GetSentenceFolder}
        Args = {Application.getArgs record('folder'(single type:string optional:false))}
    in
        Args.'folder'
    end

    %%% Decomnentez moi si besoin
    % proc {ListAllFiles L}
    %   case L of nil then skip
    %   [] H|T then
    %       {Browse {String.toAtom H}}
    %       {ListAllFiles T}
    %   end
    % end
    

    %%% Procedure principale qui cree la fenetre et appelle les differentes procedures et fonctions
    proc {Main}
        TweetsFolder = {GetSentenceFolder}
    in
        %% Fonction d'exemple qui liste tous les fichiers
        %% contenus dans le dossier passe en Argument.
        %% Inspirez vous en pour lire le contenu des fichiers
        %% se trouvant dans le dossier
        %%% N'appelez PAS cette fonction lors de la phase de
        %%% soumission !!!
        % {ListAllFiles {OS.getDir TweetsFolder}}
        
        local File Line ParsedLine PressCaller List_Press NbThreads Window Description SeparatedWordsStream SeparatedWordsPort in
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
		
		File = {GetFilename 1}
		Line = {Reader File}
		ParsedLine = {ParseAllLines Line}

		% % {Browse {String.toAtom ParsedLine.1}}
		%Tree = {CreateTree leaf ParsedLine}

        local NewTree in

            Tree = {CreateTree leaf ParsedLine}
            % {Browse Tree}

            NewTree = {TraverseAndChange Tree Tree}
            
            {Browse {LookingUp NewTree 'must go'}}
            {Browse {LookingUp NewTree 'i have'}}
            {Browse {LookingUp NewTree 'closer cooperation'}}
            {Browse {LookingUp NewTree 'the fake'}}

        end
		
		%%% TODO : Pas encore fonctionnel %%%

        % On lance les threads de lecture et de parsing
        % SeparatedWordsPort = {NewPort SeparatedWordsStream}
        % NbThreads = 10

        % {LaunchThreads SeparatedWordsPort NbThreads}
        % {Record.forAll SeparatedWordsPort proc{$ X} {Browse X} end}

        end
    end

    % Appelle la procedure principale
    {Main}
end