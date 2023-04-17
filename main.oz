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
	
	%%% Class used to open the files
	class TextFile
		from Open.file Open.text
	end

	proc {Browse Buf}
		{Browser.browse Buf}
	end


	%%% MAIN TREE FUNCTIONS BEGIN %%%

	%%% Structure of the recursive binary tree : 
	%%% 	obtree := leaf | obtree(Key Value Left Right)
	%%% Example : 
	%%% 	T = tree(key:horse value:cheval
	%%%			tree(key:dog value:chien
	%%%			tree(key:cat value:chat leaf leaf)
	%%%			tree(key:elephant value:elephant leaf leaf))
	%%%		tree(key:mouse value:souris
	%%%			tree(key:monkey value:singe leaf leaf)
	%%%			tree(key:tiger value:tigre leaf leaf)))

	fun {LookingUp Tree Key}
		case Tree
		of leaf then notfound
		[] tree(key:K value:V TLeft TRight) andthen K == Key
			then V
		[] tree(key:K value:V TLeft TRight) andthen K > Key
			then {LookingUp TLeft Key}
		[] tree(key:K value:V TLeft TRight) andthen K < Key
			then {LookingUp TRight Key}
		end
	end

	fun {Insert Key Value Tree}
		case Tree
		of leaf then tree(key:Key value:Value leaf leaf)
		[] tree(key:K value:V TLeft TRight) andthen K == Key
			then tree(key:Key value:Value TLeft TRight)
		[] tree(key:K value:V TLeft TRight) andthen K < Key
			then tree(key:K value:V TLeft {Insert Key Value TRight})
		[] tree(key:K value:V TLeft TRight) andthen K > Key
			then tree(key:K value:V {Insert Key Value TLeft} TRight)
		end
	end

	fun {RemoveSmallest Tree}
		case Tree
		of leaf then none
		[] tree(key:K value:V TLeft TRight) then
			case {RemoveSmallest TLeft}
			of none then triple(TRight K V)
			[] triple(Tp Kp Vp) then
				triple(tree(key:K value:V Tp TRight) Kp Vp)
			end
		end
	end

	fun {Delete Key Tree}
		case Tree
		of leaf then leaf
		[] tree(key:K value:V TLeft TRight) andthen Key == K then
			case {RemoveSmallest TRight}
			of none then TLeft
			[] triple(Tp Kp Vp) then
				tree(key:Kp value:Vp TLeft Tp)
			end
		[] tree(key:K value:V TLeft TRight) andthen Key < K
			then tree(key:K value:V {Delete Key TLeft} TRight)
		[] tree(key:K value:V TLeft TRight) andthen Key > K
			then tree(key:K value:V TLeft {Delete Key TRight})
		end
	end

	%%% MAIN TREE FUNCTIONS END %%%



	%%% SUBTREE FUNCTIONS BEGIN %%%

	proc {AddChild SubTree Child}
		SubTree.children = Child|SubTree.children
	end

	% fun {CreateNewSubTree Key Frequence Child}
	% 	local SubTree Child in
	% 		SubTree = tree(key:Key frequence:Frequence children:[])
	% 		Child = tree(key:Child frequence:1 children:[])
	% 		{AddChild SubTree Child}
	% 	end
	% end

	%%% SUBTREE FUNCTIONS END %%%
	
	fun {AddLineToTree Tree ListWords}
		case ListWords
		of nil then Tree
		[] H|T then
			if T.1 \= nil andthen T.2 \= nil then
				local SearchValue SubTree in
					SearchValue = {LookingUp Tree {String.toAtom H}}

					% The first word is not in the main tree
					if SearchValue == notfound then
						SubTree = {CreateNewSubTree T.1 1 T.2}
						{Insert {String.toAtom H} SubTree Tree}

					% The first word is in the main tree
					else
						SubTree = SearchValue
						
					end
				end
			else
				Tree
			end
		end
	end


	%%% Create the main Tree + all the SubTree
	%%% Pre : Tree is the main Tree
	%%%		  L is a list of lists
	%%% Post : 
	%%% Example : L = [['i am the boss'] ['no problem sir']]   (Warning : In reality, it's a list of ASCII characters)
	fun {CreateTree Tree L}
		case L
		of nil then Tree
		[] H|T then
			{CreateTree {AddLineToTree Tree {String.tokens H & }} T}
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
	% {Browse {GetFilename 1}} % "tweets/part_1.txt"


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
				end
			end
		in
			{RemoveEmptySpaceAux Line false}
		end
	end


	% Replaces special caracters by a space (== 32 in ASCII) and letters to lowercase
	fun {ParseLine Line}
		case Line
		of 34|T then 32|{ParseLine T} % if "
		[] 35|T then 32|{ParseLine T} % if #
		[] 36|T then 32|{ParseLine T} % if $
		[] 37|T then 32|{ParseLine T} % if %
		[] 38|T then 32|{ParseLine T} % if &
		[] 39|T then 32|{ParseLine T} % if '
		[] 40|T then 32|{ParseLine T} % if (
		[] 41|T then 32|{ParseLine T} % if )
		[] 42|T then 32|{ParseLine T} % if *
		[] 43|T then 32|{ParseLine T} % if +
		[] 45|T then 32|{ParseLine T} % if -
		[] 47|T then 32|{ParseLine T} % if /
		[] 60|T then 32|{ParseLine T} % if <
		[] 61|T then 32|{ParseLine T} % if =
		[] 62|T then 32|{ParseLine T} % if >
		[] 64|T then 32|{ParseLine T} % if @
		[] 91|T then 32|{ParseLine T} % if [
		[] 92|T then 32|{ParseLine T} % if \
		[] 93|T then 32|{ParseLine T} % if ]
		[] 94|T then 32|{ParseLine T} % if ^
		[] 95|T then 32|{ParseLine T} % if _
		[] 96|T then 32|{ParseLine T} % if `
		[]123|T then 32|{ParseLine T} % if {
		[]124|T then 32|{ParseLine T} % if |
		[]125|T then 32|{ParseLine T} % if }
		[]126|T then 32|{ParseLine T} % if ~
		[] 33|T then 32|{ParseLine T} % if !
		[] 44|T then 32|{ParseLine T} % if ,
		[] 46|T then 32|{ParseLine T} % if .
		[] 58|T then 32|{ParseLine T} % if :
		[] 59|T then 32|{ParseLine T} % if ;
		[] 63|T then 32|{ParseLine T} % if ?

		[] H|T then 					% if capital or lowercase letter
			local New_H in
				if H < 97 then 			% if capital letter
					if H == 32 then		% AND not a space
						New_H = H
					else
						New_H = H + 32	% switch to lowercase letter
					end
				else					% else
					New_H = H			% keep the already lowercase letter
				end
				New_H | {ParseLine T}
			end
		
		[] nil then nil
		end
	end
	% {Browse {ParseLine "FLATTENING OF THE CURVE!"}} % "flattening of the curve "

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
		Text = {InputText tkReturnAtom(get p(1 0) 'end' $)} 	% read first line of input from 0 to end (ex: "I am\n")
		Splitted = {String.tokens Text & } 						% splits on spaces (ex: ["I" "am\n"])
        End = {List.last Splitted} 								% get the last/most recent word (ex: "am\n")
        Last = {String.tokens End &\n} 							% split/removes newline (ex: "am") /!\ adds [] around so Last must be called Last.1
        
		% TODO % func that searches in tree and returns a list of all words following 'Last' in database and their frequencies

		{OutputText tk(insert p(1 0) 'end')}
	end


	%%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
	%%% Les threads de parsing envoient leur resultat au port Port
	proc {LaunchThreads Port N}
		for X in 1..N do File ThreadReader ThreadParser ThreadSaver L P in
			File = {GetFilename X}
			thread ThreadReader = {Reader File} L=1 end
			thread {Wait L} ThreadParser = {ParseAllLines ThreadReader} P=1 end
			{Port.send Port ThreadParser}
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
	% 	case L of nil then skip
	% 	[] H|T then
	% 		{Browse {String.toAtom H}}
	% 		{ListAllFiles T}
	% 	end
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
		
		local NbThreads InputText OutputText Description Window SeparatedWordsStream SeparatedWordsPort in
		{Property.put print foo(width:1000 depth:1000)}  % for stdout siz

		
		% Creation de l interface graphique
		Description=td(
			title: "Text predictor"
			lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:Press))
			text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
			action:proc{$}{Application.exit 0} end % quitte le programme quand la fenetre est fermee
			)
		
		% Creation de la fenetre
		Window={QTk.build Description}
		{Window show}
		
		{InputText tk(insert 'end' "Loading... Please wait.")}
		{InputText bind(event:"<Control-s>" action:Press)} % You can also bind events
		
		% On lance les threads de lecture et de parsing
		SeparatedWordsPort = {NewPort SeparatedWordsStream}
		NbThreads = 208
		% {LaunchThreads SeparatedWordsPort NbThreads}
		{InputText set(1:"")}
		{OutputText set(1:"haha")}
		end
	end

	% Appelle la procedure principale
	{Main}

	local ListLine ListParsed Tree in
		ListLine = {Reader {GetFilename 1}}
		ListParsed = {ParseAllLines ListLine}
		Tree = {CreateTree {Dictionary.new} ListParsed}
	end
end
