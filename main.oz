functor
import 
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    OS
    Property
    Browser

    Reader
    Parser
    Tree
define
    
	InputText OutputText TweetsFolder_List % Global variables

    proc {Browse Buf}
        {Browser.browse Buf}
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
			Tree_Value = {Tree.LookingUp Tree Key}
			
            TreeMaxFreq = {Tree.GetTreeMaxFreq Tree_Value}
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

    % proc {ListAllFiles L}
    %     case L
    %     of nil then skip
    %     [] H|T then
    %         {Browse {String.toAtom H}} {ListAllFiles T}
    %     end
    % end

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
                               
                            File_1 = {Reader.GetFilename TweetsFolder_List Y}
                            File = {Append "tweets/" File_1} %% DE BASE => Ne devrait pas avoir cette ligne je pense
                            thread ThreadReader = {Reader.Reader File} L=1 end
                            thread {Wait L} ThreadParser = {Parser.ParseAllLines ThreadReader} P=1 end
                            {Wait P}
                            {Send Port ThreadParser}

                        end
                    end
                end
            end
        end
    end


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
        List_Port = {Get_Nth_FirstElem_Port SeparatedWordsStream 208}
        FirstTree = {Tree.CreateTree leaf List_Port}
        Tree = {Tree.TraverseAndChange FirstTree FirstTree}
        {Browse 'OVER : Creating Structure'}
        end
    end

    % Appelle la procedure principale
    {Main}
end