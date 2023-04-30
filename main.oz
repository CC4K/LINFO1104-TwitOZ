functor
import 
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    OS
    Property
    System

    Function at 'function.ozf'
    Interface at 'interface.ozf'
    Extensions at 'extensions.ozf'
    Parser at 'parser.ozf'
    Tree at 'tree.ozf'
    Reader at 'reader.ozf'
    Variables at 'Variables.ozf'

define

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

        if Variables.tree_Over == true then
            local ResultPress ProbableWords Frequency Probability SplittedText List_Words BeforeLast Last Key Parsed_Key Tree_Value in

                % Clean the input user
                SplittedText = {Parser.cleaningUserInput {Function.tokens_String {Variables.inputText getText(p(1 0) 'end' $)} 32}}
                List_Words = {Function.get_Last_Nth_Word_List SplittedText Variables.idx_N_Grams}
                    
                if {Length List_Words} >= Variables.idx_N_Grams then
                    Key = {Function.concatenateElemOfList List_Words 32}
                    Parsed_Key = {String.toAtom {Parser.parseInputUser Key}}
                    
                    Tree_Value = {Tree.lookingUp Variables.main_Tree Parsed_Key}

                    if Tree_Value == notfound then
                        {Interface.setText_Window Variables.outputText "NO WORD FIND!"}
                        [[nil] 0] % => no words found
                    elseif Tree_Value == leaf then
                        {Interface.setText_Window Variables.outputText "NO WORD FIND!"}
                        [[nil] 0] % => no words found
                    else
                        ResultPress = {Tree.traverseToGetProbability Tree_Value}

                        ProbableWords = ResultPress.1
                        Probability = ResultPress.2.1
                        Frequency = ResultPress.2.2.1

                        if ProbableWords == [nil] then
                            {Interface.setText_Window Variables.outputText "No words found."}
                            [[nil] 0] % => no words found
                        else
                            {Extensions.proposeAllTheWords ProbableWords Frequency Probability}
                            [ProbableWords Probability] % => no words found

                            %% Basic version %%
                            % {Interface.setText_Window OutputText ProbableWords.1}
                        end
                    end
                else
                    {Interface.setText_Window Variables.outputText {Append "Need at least " {Append {Int.toString Variables.idx_N_Grams} " words to predict the next one."}}}
                    [[nil] 0] % => no word or one word only
                end
            end
        else
            [[nil] 0] % => no tree created yet
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

                        File = {Reader.getFilename Variables.tweetsFolder_Name Variables.list_PathName_Tweets Start}
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
            Basic_Nber_Iter = Variables.nberFiles div N
            Rest_Nber_Iter = Variables.nberFiles mod N

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

        Variables.idx_N_Grams = 5       
        Variables.tweetsFolder_Name = {GetSentenceFolder}
        Variables.list_PathName_Tweets = {OS.getDir Variables.tweetsFolder_Name}
        Variables.nberFiles = {Length Variables.list_PathName_Tweets}

        % Need to do some tests to see the best number of threads
        if 50 > Variables.nberFiles then
            Variables.nbThreads = Variables.nberFiles
        else
            Variables.nbThreads = 50
        end

        local Window Description List_Line_Parsed SeparatedWordsStream in

            {Property.put print foo(width:1000 depth:1000)}  % for stdout siz

            % Description of the GUI
            Description=td(
                title: "TwitOZ"
                lr( td( text(handle:Variables.inputText width:65 height:12 font:{QTk.newFont font(family:"Verdana")} background:white foreground:black wrap:word tdscrollbar:false)
                        text(handle:Variables.outputText width:65 height:12 font:{QTk.newFont font(family:"Verdana")} background:black foreground:white glue:w wrap:word tdscrollbar:false)
                        )
                    td( %label(image:{QTk.newImage photo(url:"./twit.png")} borderwidth:0 width:275)
                        button(text:"Predict" background:c(29 125 242) borderwidth:2 font:{QTk.newFont font(family:"Verdana" size:14)} foreground:white activebackground:white activeforeground:black cursor:hand2 height:2 glue:we action:proc{$} _={Press} end) % add a reload_tree function on each press (reminder)
                        button(text:"Save file .txt" background:c(29 125 242) borderwidth:2 font:{QTk.newFont font(family:"Verdana" size:14)} foreground:white activebackground:white activeforeground:black cursor:hand2 height:2 glue:we action:Extensions.saveText)
                        button(text:"Save file into the database" background:c(29 125 242) borderwidth:2 font:{QTk.newFont font(family:"Verdana" size:14)} foreground:white activebackground:white activeforeground:black cursor:hand2 height:2 glue:we action:Extensions.saveText_Database)
                        button(text:"Load file as input" background:c(29 125 242) borderwidth:2 font:{QTk.newFont font(family:"Verdana" size:14)} foreground:white activebackground:white activeforeground:black cursor:hand2 height:2 glue:we action:Extensions.loadText)
                        button(text:"Quit" background:c(29 125 242) relief:sunken borderwidth:2 font:{QTk.newFont font(family:"Verdana" size:14)} foreground:white activebackground:white activeforeground:black cursor:hand2 height:2 glue:we action:proc{$} {Application.exit 0} end)
                        )
                    glue:nw
                    background:c(27 157 240)
                )
                action:proc{$} {Application.exit 0} end
                )

            %%% Basic version %%%
            % Description = td(
            %     title: "Text predictor"
            %     lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:proc {$} _ = {Press} end))
            %     text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
            %     action:proc{$} {Application.exit 0} end % Quitte le programme quand la fenetre est fermee
            % )

            % Creation of the GUI
            Window = {QTk.build Description}
            {Window show}

            {Interface.insertText_Window Variables.inputText 0 0 'end' "Loading... Please wait."}
            {Variables.inputText bind(event:"<Control-s>" action:proc {$} _ = {Press} end)} % You can also bind events
            {Interface.insertText_Window Variables.outputText 0 0 'end' "You must wait until the database is parsed.\nA message will notify you.\nDon't press the 'predict' button until the message appears!\n"}

            % Create the Port
            Variables.separatedWordsPort = {NewPort SeparatedWordsStream}

            % Launch all threads to reads and parses the files
            {LaunchThreads Variables.separatedWordsPort Variables.nbThreads}

            % We retrieve the information (parsed lines of the files) from the port's stream
            {Send Variables.separatedWordsPort nil}
            List_Line_Parsed = {Function.get_ListFromPortStream SeparatedWordsStream}
            {Interface.insertText_Window Variables.outputText 6 0 none "Step 1 Over : Reading + Parsing\n"}

            % Creation of the main binary tree (with all subtree as value)
            Variables.main_Tree = {Tree.traverseAndChange {Tree.createTree List_Line_Parsed} fun {$ NewTree Key Value}
                {Tree.insert NewTree Key {Tree.createSubtree Value}}
            end}
            
            % {Press} can work now because the structure is ready
            Variables.tree_Over = true

            % Display and remove some strings
            {Interface.insertText_Window Variables.outputText 7 0 none "Step 2 Over : Stocking datas\n"}
            {Interface.insertText_Window Variables.outputText 9 0 none "The database is now parsed.\nYou can write and predict!"}

            if {Function.findPrefix_InList {Variables.inputText getText(p(1 0) 'end' $)} "Loading... Please wait."} then
                % Remove the first 23 characters (= "Loading... Please wait.")
                {Variables.inputText tk(delete p(1 0) p(1 23))}
            else
                % Remove all because the user add some texts between or before the line : "Loading... Please wait."
                {Interface.setText_Window Variables.inputText ""}
            end
        end
        %%ENDOFCODE%%
    end

    % Call the main procedure
    {Main}
end