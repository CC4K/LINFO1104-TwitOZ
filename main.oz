functor
import 
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    OS
    Property
    Browser

    Reader at 'bin/reader.ozf'
    Parser at 'bin/parser.ozf'
    Tree at 'bin/tree.ozf'
define

    % Global variables
	InputText OutputText TweetsFolder_Name List_PathName_Tweets Main_Tree Tree_Over NberFiles NbThreads SeparatedWordsStream SeparatedWordsPort

    %%%
    % Procedure used to display some datas
    %
    % Example usage:
    % In: 'hello there, please display me'
    % Out: Display on a window : 'hello there, please display me'
    %
    % @param Buf: The data that we want to display on a window.
    %             The data can be a list, a string, an atom,...
    % @return: /
    %%%
    proc {Browse Buf}
        {Browser.browse Buf}
    end

    %%%
    % Concatenates a list of strings from a stream associated with a port
    %
    % Example usage:
    % In: ['i am good and you']|['i am very good thanks']|['wow this is a port']|_ 
    % Out: ['i am good and you i am very good thanks wow this is a port']
    %
    % @param Stream: a stream associated with a port that contains a list of parsed lines
    % @return: a list with all the elements of the stream concatenated together
    %%%
    fun {Get_ListFromPortStream Stream}
        local
            fun {Get_ListFromPortStreamAux Stream}
                case Stream
                of nil|T then nil
                [] H|T then
                    {Append H {Get_ListFromPortStreamAux T}}
                end
            end
        in
            {Send SeparatedWordsPort nil}
            {Get_ListFromPortStreamAux Stream}
        end
    end

    %%%
    % Function called when the user pressed the button 'predict'.
    % Call the function {Press} to get the most probable word to predict and display it on the window.
    %
    % @param: /
    % @return: /
    %%%
	proc {CallPress}
		local ResultPress ProbableWords MaxFreq in
            
            % But de Tree_Over : bloquer le programme le temps que la structure soit cree
            if Tree_Over == true then

                ResultPress = {Press}
                % {Browse ResultPress}

                if ResultPress == none then
                    {OutputText set("You must write minimum 2 words.")}
                else
                    ProbableWords = ResultPress.1
                    MaxFreq = ResultPress.2.1

                    % {Browse ProbableWords}
                    % {Browse MaxFreq}

                    if ProbableWords == nil then
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



    %%% ================================================================================ %%%
    %%% /! Fonction testee /!  %%% /! Fonction testee /! %%% /! Fonction testee /! %%%
    %%% /! Fonction testee /!  %%% /! Fonction testee /! %%% /! Fonction testee /! %%%
    %%% /! Fonction testee /!  %%% /! Fonction testee /! %%% /! Fonction testee /! %%%
    %%% ================================================================================ %%%

    %%%
    % Displays the most likely prediction of the next word based on the last two entered words.
    %
    % @pre: The threads are "ready".
    % @post: Function called when the prediction button is pressed.
    %
    % @param: /
    % @return: Returns a list containing the most probable word(s) list accompanied by the highest probability/frequency.
    %          The return value must take the form:
    %               <return_val> := <most_probable_words> '|' <probability/frequency> '|' nil
    %               <most_probable_words> := <atom> '|' <most_probable_words> | nil
    %               <probability/frequency> := <int> | <float>
    %%%
    fun {Press}
		
		local ProbableWords_Probability TreeMaxFreq SplittedText BeforeLast Last Key Tree_Value in
            
			SplittedText = {String.tokens {InputText getText(p(1 0) 'end' $)} & }
            
            if {Length SplittedText} < 2 then % Pourrait optimise pour ne pas devoir appele {Length List}
                none
            else
                Last = {String.tokens {List.last SplittedText} &\n}.1
                BeforeLast = {Nth SplittedText {Length SplittedText} - 1}

                Key = {String.toAtom {Append {Append BeforeLast [32]} Last}}
                Tree_Value = {Tree.lookingup Main_Tree Key}
                
                % {System.show Tree_Value}

                if Tree_Value == notfound then
                    ProbableWords_Probability = {Tree.traversetogetprobability leaf}
                else
                    ProbableWords_Probability = {Tree.traversetogetprobability Tree_Value}
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%% To remove if we sure that we do with probability and not frequency %%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                %%% To have frequence and not the probability %%%

                % TreeMaxFreq = {Tree.getTreeMaxFreq Tree_Value}

                % if TreeMaxFreq == leaf then
                %     [nil 0]
                % else
                %     {Browse TreeMaxFreq.value}
                %     {Browse TreeMaxFreq.key}
                %     [TreeMaxFreq.value TreeMaxFreq.key]
                % end

            end
		end
    end

    %%%
    % Launches N reading and parsing threads that will read and process all the files.
    % The parsing threads send their results to the Port.
    %
    % @param Port: a port structure to store the results of the parser threads
    % @param N: the number of threads used to read and parse all files
    % @return: /
    %%%
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
                        %% Permet de repartir le mieux possible le travail entre les threads ! Formule trouve par de la logique
                        Start = Rest_Nber_Iter * (Current_Nber_Iter1 + 1) + (X - 1 - Rest_Nber_Iter) * Current_Nber_Iter1 + 1
                    end

                    End = Start + Current_Nber_Iter1 - 1

                    for Y in Start..End do

                        local File ThreadReader ThreadParser L P in
                            File = {Reader.getfilename TweetsFolder_Name List_PathName_Tweets Y}
                            thread ThreadReader = {Reader File} L=1 end
                            thread {Wait L} ThreadParser = {Parser.parsealllines ThreadReader fun {$ Str_Line} {Parser.removeemptyspace {Parser.parseline Str_Line}} end} P=1 end
                            {Wait P}
                            {Send Port ThreadParser}
                        end
                        
                    end
                end
            end
        end
    end

    %%%
    % Fetches Tweets Folder specified in the command line arguments
    %
    % @param: /
    % @return: the Tweets folder specified in the command line arguments
    %%%
    fun {GetSentenceFolder}
        Args = {Application.getArgs record('folder'(single type:string optional:false))}
    in
        Args.'folder'
    end

    %%%
    % Main procedure that creates the Qtk window and calls differents functions/procedures to make the program functional.
    %
    % This procedure creates a GUI window using the Qt toolkit and sets up event handlers to interact with user inputs.
    % It then calls other functions/procedures to parse data files, build data structures, and make predictions based on user inputs.
    %
    % @param: /
    % @return: /
    %%%
    proc {Main}
        
        TweetsFolder_Name = {GetSentenceFolder}
        List_PathName_Tweets = {OS.getDir TweetsFolder_Name}

        NberFiles = {Length List_PathName_Tweets}
        NbThreads = 5

        local List_Line_Parsed Window Description in

            {Property.put print foo(width:1000 depth:1000)}  % for stdout siz

            % Creation de l'interface graphique
            Description=td(
                title: "Text predictor"
                lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:CallPress))
                text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
                action:proc{$} {Application.exit 0} end % Quitte le programme quand la fenetre est fermee
                )
            
            % Creation de la fenÃªtre
            Window = {QTk.build Description}
            {Window show}
            
            {InputText tk(insert 'end' "Loading... Please wait.")}
            {InputText bind(event:"<Control-s>" action:CallPress)} % You can also bind events
            {OutputText set("You must wait until the database is parsed.\nA message will notify you.\nDon't press the 'predict' button until the message appears!\n")}

            %%% On creer le Port %%%
            SeparatedWordsPort = {NewPort SeparatedWordsStream}
            
            %%% On lance les threads de lecture et de parsing %%%
            {LaunchThreads SeparatedWordsPort NbThreads}

            %%% On recupere les informations dans le Stream du Port %%%
            List_Line_Parsed = {Get_ListFromPortStream SeparatedWordsStream}

            {OutputText tk(insert p(6 0) "Step 1 Over : Reading + Parsing\n")} % Pour la position, c'est du test essais-erreur
            
            %%% On creer l'arbre principale avec tout les sous-arbres en valeur %%%
            Main_Tree = {Tree.traverseandchange {Tree.createtree List_Line_Parsed} fun {$ Tree Key Value} {Tree.insert Tree Key {Tree.createsubtree Value}} end}
            Tree_Over = true % CallPress can work now

            {OutputText tk(insert p(7 0) "Step 2 Over : Stocking datas\n")} % Pour la position, c'est du test essais-erreur
            {OutputText tk(insert p(9 0) "The database is now parsed.\nYou can write and predict!")} % Pour la position, c'est du test essais-erreur
            
            if {Reader.findprefix {InputText getText(p(1 0) 'end' $)} "Loading... Please wait."} then
                {InputText tk(delete p(1 0) p(1 23))} % Remove the first 23 characters (= "Loading... Please wait.")
            else
                {InputText set("")} % Remove all because the user add some texts between or before the line : "Loading... Please wait."
            end
        end
        %%ENDOFCODE%%
    end

    % Appelle la procedure principale
    {Main}

end