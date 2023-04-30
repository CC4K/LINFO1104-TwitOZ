functor
import 
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    OS
    Property
    % System
    % Browser

    Function at 'function.ozf'
    Interface at 'interface.ozf'
    Parser at 'parser.ozf'
    Tree at 'tree.ozf'
    Reader at 'reader.ozf'
define

    % Global variables
	InputText OutputText TweetsFolder_Name List_PathName_Tweets Main_Tree Tree_Over NberFiles NbThreads SeparatedWordsPort

    %%%
    % Function called when the user pressed the button 'predict'.
    % Call the function {Press} to get the most probable word to predict and display it on the window.
    %
    % @param: /
    % @return: /
    %%%
	proc {CallPress}
		local ResultPress ProbableWords MaxFreq in
            
            % Goal of Tree_Over : Block this bloc of instruction until the structure is created.
            % If {CallPress} is called (= if the user pressed the button "predict") and the structure
            % to stock datas is not ready yet, the program wait here because Tree_Over is only bind
            % when the structure is over and ready.
            if Tree_Over == true then

                ResultPress = {Press}
                {Function.browse ResultPress}

                ProbableWords = ResultPress.1
                MaxFreq = ResultPress.2.1

                if ProbableWords == [nil] then
                    {Interface.setText_Window OutputText "NO WORD FIND!"}
                else
                    {Interface.setText_Window OutputText ProbableWords.1}
                end
            else
                skip
            end
		end
	end


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
		local SplittedText List_Words BeforeLast Last Key Parsed_Key Tree_Value in

            % Clean the input user
            SplittedText = {Parser.cleaningUserInput {Function.tokens_String {InputText getText(p(1 0) 'end' $)} 32}}
            List_Words = {Function.get_TwoLastWord_List SplittedText}

            if List_Words \= nil then

                BeforeLast = List_Words.1
                Last = {Function.tokens_String List_Words.2.1 10}.1

                Key = {String.toAtom {Function.append_List BeforeLast 32|Last}}
                Parsed_Key = {String.toAtom {Parser.parseInputUser {Atom.toString Key}}}

                Tree_Value = {Tree.lookingUp Main_Tree Parsed_Key}

                if Tree_Value == notfound then
                    [[nil] 0]
                else
                    {Tree.traverseToGetProbability Tree_Value}
                end
            else % If the user did't write at least two words => return [[nil] 0]
                [[nil] 0] % => no word or one word only
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

        local
            List_Waiting_Threads
            Basic_Nber_Iter
            Rest_Nber_Iter
            fun {Launch_OneThread Start End List_Waiting_Threads}

                if Start == End+1 then List_Waiting_Threads
                else
                    local File_Parsed File LineToParsed Thread_Reader_Parser L P in

                        File = {Reader.getFilename TweetsFolder_Name List_PathName_Tweets Start}
                        % File = "tweets/custom.txt"

                        thread Thread_Reader_Parser =
                            LineToParsed = {Reader.read File}
                            L=1
                            {Wait L} 
                            File_Parsed = {Parser.parseAllLines
                                            LineToParsed
                                            fun {$ Str_Line}
                                                {Parser.removeEmptySpace
                                                    {Parser.parseLine
                                                        {Parser.cleanUp Str_Line
                                                            fun {$ Line_Str} {Parser.removePartList Line_Str [226 128] 32 true} end
                                                        }
                                                    false}
                                                }
                                            end}
                            P=1
                            {Send Port File_Parsed}
                        end
                        
                        {Launch_OneThread Start+1 End P|List_Waiting_Threads}
                    end
                end
            end
                
            fun {Launch_AllThreads List_Waiting_Threads Nber_Iter}
                
                if Nber_Iter == 0 then List_Waiting_Threads
                else
                    local Current_Nber_Iter1 Start End in

                        % Those formulas are used to split (in the best way) the work between threads.
                        % Those formulas are complicated to find but the idea is here:
                        % Example : if we have 6 threads and 23 files to read and process, the repartition will be [4 4 4 4 4 3].
                        %           A naive version will do a repartition like this [3 3 3 3 3 8].
                        %           This is a bad version because the last thread will slow down the program
                        %%%
                        if Rest_Nber_Iter - Nber_Iter >= 0 then
                            Current_Nber_Iter1 = Basic_Nber_Iter + 1
                            Start = (Nber_Iter - 1) * Current_Nber_Iter1 + 1
                        else
                            Current_Nber_Iter1 = Basic_Nber_Iter
                            Start = Rest_Nber_Iter * (Current_Nber_Iter1 + 1) + (Nber_Iter - 1 - Rest_Nber_Iter) * Current_Nber_Iter1 + 1
                        end
        
                        End = Start + Current_Nber_Iter1 - 1

                        {Launch_AllThreads {Launch_OneThread Start End nil} Nber_Iter-1}

                    end
                end

            end
        in 
            % Usefull to do the repartition of the work between threads
            Basic_Nber_Iter = NberFiles div N
            Rest_Nber_Iter = NberFiles mod N

            % Launch all the threads
            % The parsing files are stocked in the Port
            % The variables to Wait all the threads are stocked in List_Waiting_Threads
            List_Waiting_Threads = {Launch_AllThreads nil N}
            
            % Wait for all the threads
            % When a thread have finished, the value P associated to this thread
            % is bind and the program can move on 
            {ForAll List_Waiting_Threads proc {$ P} {Wait P} end}
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

        % Need to do some tests to see the best number of threads
        if 50 > NberFiles then
            NbThreads = NberFiles
        else
            NbThreads = 50
        end

        local Window Description List_Line_Parsed SeparatedWordsStream in

            {Property.put print foo(width:1000 depth:1000)}  % for stdout siz

            % Description of the graphical user interface
            Description = td(
                title: "Text predictor"
                lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:CallPress))
                text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
                action:proc{$} {Application.exit 0} end % Quitte le programme quand la fenetre est fermee
            )

            % Creation of the graphical user interface
            Window = {QTk.build Description}
            {Window show}

            {Interface.insertText_Window InputText 0 0 'end' "Loading... Please wait."}
            {InputText bind(event:"<Control-s>" action:CallPress)} % You can also bind events
            {Interface.insertText_Window OutputText 0 0 'end' "You must wait until the database is parsed.\nA message will notify you.\nDon't press the 'predict' button until the message appears!\n"}

            % Create the Port
            SeparatedWordsPort = {NewPort SeparatedWordsStream}

            % Launch all threads to reads and parses the files
            {LaunchThreads SeparatedWordsPort NbThreads}

            % We retrieve the information (parsed lines of the files) from the port's stream
            {Send SeparatedWordsPort nil}
            List_Line_Parsed = {Function.get_ListFromPortStream SeparatedWordsStream}
            {Interface.insertText_Window OutputText 6 0 none "Step 1 Over : Reading + Parsing\n"}

            % Creation of the main binary tree (with all subtree as value)
            Main_Tree = {Tree.traverseAndChange {Tree.createTree List_Line_Parsed} fun {$ NewTree Key Value}
                                                                                        {Tree.insert NewTree Key {Tree.createSubtree Value}}
                                                                                   end}
            
            % CallPress can work now because the structure is ready
            Tree_Over = true

            % Display and remove some strings
            {Interface.insertText_Window OutputText 7 0 none "Step 2 Over : Stocking datas\n"}
            {Interface.insertText_Window OutputText 9 0 none "The database is now parsed.\nYou can write and predict!"}

            if {Function.findPrefix_InList {InputText getText(p(1 0) 'end' $)} "Loading... Please wait."} then
                % Remove the first 23 characters (= "Loading... Please wait.")
                {InputText tk(delete p(1 0) p(1 23))}
            else
                % Remove all because the user add some texts between or before the line : "Loading... Please wait."
                {Interface.setText_Window InputText ""}
            end
        end
        %%ENDOFCODE%%
    end

    % Call the main procedure
    {Main}
end