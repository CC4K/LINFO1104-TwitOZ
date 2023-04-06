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
	%%% Pour ouvrir les fichiers
	class TextFile
		from Open.file Open.text
	end

	proc {Browse Buf}
		{Browser.browse Buf}
	end

	% Create the filename "tweets/part_N.txt" where N is given in argument.
	fun {GetFilename N}
		local F1 F2 in
			F1 = "tweets/part_"
			F2 = {Append F1 {Int.toString N}}
			{Append F2 ".txt"}
		end
	end

	% Create a list with all line of the file named "Filename"
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
	
	fun {ParseAllLines List}
		case List
		of nil then nil
		[] H|T then {ParseLine H} | {ParseAllLines T}
		end
	end

	fun {ParseLine Line}
		case Line
		of 46|T then % If it's a dot ('.')
			skip
			%TODO
		[] 32|T then % If it's a space (' ')
			skip
			%TODO
		[] 44|T then % If it's a comma (',')
			skip
			%TODO
		[] 45|T then % If it's a hyphen-minus ('-')
			skip
			%TODO
		[] 58|T then % If it's a colon (':')
			skip
			%TODO
		[] 59|T then % If it's a semicolon (';')
			skip
			%TODO
		[] 63|T then % If it's a question mark ('?')
			skip
			%TODO
		[] 33|T then % If it's a exclamation mark ('!')
			skip
			%TODO
		[] 95|T then % If it's an underscore ('_')
			skip
			%TODO
		[] 35|T then % If it's an hashtag ('#')
			skip
			%TODO
		[] 36|T then % If it's an dollar ('$')
			skip
			%TODO
		[] 37|T then % If it's an per cent sign ('%')
			skip
			%TODO
		[] 38|T then % If it's an ampersand ('&')
			skip
			%TODO
		[] 39|T then % If it's a single quote (''')
			skip
			%TODO
		[] 34|T then % If it's a double quotes ('"')
			skip
			%TODO
		[] 10|T then % If it's a line Feed ('"')
			skip
			%TODO
		[] 13|T then % If it's a carriage return ('\n') # NOT SURE
			skip
			%TODO

		%%%%%% % CAN ADD MORE % %%%%%%
		%%%%%% % CAN ADD MORE % %%%%%%
		%%%%%% % CAN ADD MORE % %%%%%%

		[] H|T then % If it's a normal letter
			local New_H in
				if H < 97 then % If it's a capital letter
					New_H = H + (97 - 65)
				else
					New_H = H
				end
				%TODO
			end
		[] nil then
			skip
			%TODO
		end
	end

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
		% TODO
		0
	end

	%%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
	%%% Les threads de parsing envoient leur resultat au port Port
	proc {LaunchThreads Port N}
		% TODO
		skip
	end

	%%% Ajouter vos fonctions et procédures auxiliaires ici


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
		
		% TODO
		
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
		NbThreads = 4
		{LaunchThreads SeparatedWordsPort NbThreads}
		
		{InputText set(1:"")}
		end
	end
	% Appelle la procedure principale
	local List in
		ListLine = {Reader {GetFilename 1}}
		{ParseAllLines ListLine}
		% {Browse ListLine}
	end
	{Main}
end
