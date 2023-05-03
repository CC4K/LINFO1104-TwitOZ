functor
import 
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    OS
    Open
    Property
    System

    Variables at 'variables.ozf'
    Interface at 'interface.ozf'
    Function at 'function.ozf'
    Parser at 'parser.ozf'
    Tree at 'tree.ozf'
    Reader at 'reader.ozf'

    Automatic_prediction at 'extensions/automatic_prediction.ozf'
    Historic_user at 'extensions/historic_user.ozf'
    Interface_improved at 'extensions/interface_improved.ozf'
    N_Grams at 'extensions/n_Grams.ozf'
    Predict_All at 'extensions/predict_All.ozf'

define

    %%%
    % Displays to the output zone on the window the most likely prediction of the next word based on the N last entered words.
    % The value of N depends of the N-Grams asked by the user.
    % This function is called when the prediction button is pressed.
    %
    % @param: /
    % @return: Returns a list containing the most probable word(s) list accompanied by the highest probability/frequency.
    %          The return value must take the form:
    %
    %               <return_val> := <most_probable_words> '|' <probability/frequency> '|' nil
    %
    %               <most_probable_words> := <atom> '|' <most_probable_words>
    %                                        | nil
    %                                        | <no_word_found>
    %
    %               <no_word_found>         := nil '|' nil
    %
    %               <probability/frequency> := <int> | <float>
    %%%
    fun {Press}
        
        % If the structure to stock all the datas of the database is created
        if Variables.tree_Over == true then
            local InputUser SplittedText List_Words Key Parsed_Key Tree_Value ResultPress ProbableWords Frequency Probability in

                % Clean the input user and get the N last words (N depends of the N-Grams asked by the user)
                InputUser = {Variables.inputText getText(p(1 0) 'end' $)}
                SplittedText = {Parser.cleaningUserInput InputUser}
                List_Words = {Function.get_Last_Nth_Word_List SplittedText Variables.idx_N_Grams}
                

                if {Length List_Words} >= Variables.idx_N_Grams then

                    % Get the subtree representing the value at the key created by the concatenation of the N last words
                    Key = {Function.concatenateElemOfList List_Words 32}
                    Parsed_Key = {String.toAtom {Parser.parseInputUser Key}} % Parses the key to avoid problems with special characters
                    Tree_Value = {Tree.lookingUp {Function.get_Tree} Parsed_Key}

                    if Tree_Value == notfound then
                        {Interface.setText_Window Variables.outputText "No words found."}
                        [[nil] 0] % => no words found
                    elseif Tree_Value == leaf then
                        {Interface.setText_Window Variables.outputText "No words found."}
                        [[nil] 0] % => no words found
                    else

                        % Get the most probable word(s) and the highest probability/frequency
                        ResultPress = {Tree.get_Result_Prediction Tree_Value none}
                        ProbableWords = ResultPress.1
                        Probability = ResultPress.2.1
                        Frequency = ResultPress.2.2.1

                        if ProbableWords == nil then
                            {Interface.setText_Window Variables.outputText "No words found."}
                            [[nil] 0] % => no words found
                        else
                            % Display to the window the most probable word(s) and the highest probability/frequency
                            {Predict_All.proposeAllTheWords ProbableWords Frequency Probability}

                            % Return the most probable word(s) and the highest probability/frequency
                            [ProbableWords Probability]

                            %% Basic version %%
                            % {Interface.setText_Window OutputText ProbableWords.1}
                        end
                    end
                else
                    % Not enough words to predict the next one
                    {Interface.setText_Window Variables.outputText {Append "Need at least " {Append {Int.toString Variables.idx_N_Grams} " words to predict the next one."}}}
                    [[nil] 0]
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
            Basic_Nber_Iter = Variables.nberFiles div N
            Rest_Nber_Iter = Variables.nberFiles mod N
            List_Waiting_Threads
            List_Waiting_Threads_2

            %%%
            % Allows to launch a thread that will read and parse a file
            % and to get the list with the value unbound until the thread has finished its work.
            %
            % @param Start: the number of the file where the thread begins to work (reads and parses)
            % @param End: the number of the file where the thread stops to work (reads and parses)
            % @param List_Waiting_Threads: a list initialized to nil
            % @return: the list containing all the value unbound of all threads.
            %          the value will be bound where the thread has finished its work.
            fun {Launch_OneThread Start End List_Waiting_Threads}

                % If the thread has done (End - Start) files, the list is returned
                if Start == End+1 then List_Waiting_Threads
                else
                    local File_Parsed File LineToParsed L P in
                        % Launches a thread that will read and parse the file
                        % After the work done, the thread will send the result to the port
                        thread _ =
                            % File = {Reader.getFilename Start}
                            File = "tweets/custom.txt"
                            LineToParsed = {Reader.read File}
                            L=1
                            {Wait L} 
                            File_Parsed = {Parser.parses_AllLines LineToParsed}
                            P=1
                            {Send Port File_Parsed}
                        end
                        
                        {Launch_OneThread Start+1 End P|List_Waiting_Threads}
                    end
                end
            end
            
            %%%
            % Allows to launch N threads and to get the list with the value of each thread :
            %     Unbound if the thread has not finished its work
            %     Bound if the thread has finished its work
            %
            % @param List_Waiting_Threads: a list initialized to nil
            % @param Nber_Threads: the number of threads to launch
            % @return: the list containing all the value unbound (until they have finished their work) of all threads.
            fun {Launch_AllThreads List_Waiting_Threads Nber_Threads}
                
                % If all the threads have been launch and all the result list has been get, the list is returned
                if Nber_Threads == 0 then List_Waiting_Threads
                else
                    local Current_Nber_Iter1 Start End in

                        % Those formulas are used to split (= the best way) the work between threads.
                        % Those formulas are complicated to find but the idea is here:
                        % Example : if we have 6 threads and 23 files to read and process, the repartition will be [4 4 4 4 4 3].
                        %           A naive version will do a repartition like this [3 3 3 3 3 8].
                        %           This is a bad version because the last thread will slow down the program
                        %%%
                        if Rest_Nber_Iter - Nber_Threads >= 0 then
                            Current_Nber_Iter1 = Basic_Nber_Iter + 1
                            Start = (Nber_Threads - 1) * Current_Nber_Iter1 + 1
                        else
                            Current_Nber_Iter1 = Basic_Nber_Iter
                            Start = Rest_Nber_Iter * (Current_Nber_Iter1 + 1) + (Nber_Threads - 1 - Rest_Nber_Iter) * Current_Nber_Iter1 + 1
                        end
        
                        End = Start + Current_Nber_Iter1 - 1

                        {Launch_AllThreads {Launch_OneThread Start End nil} Nber_Threads-1}
                    end
                end

            end
        in 

            % Launch all the threads
            % The parsing files are stocked in the Port
            % The variables to Wait all the threads are stocked in List_Waiting_Threads

            thread _ = List_Waiting_Threads = {Launch_AllThreads nil N} end

            % To also parse the historic user files (Extension)
            thread _ = List_Waiting_Threads_2 = {Historic_user.launchThreads_HistoricUser} end
            
            % Wait for all the threads
            % When a thread have finished, the value P associated to this thread
            % is bind and the program can move on 
            {ForAll {Function.append_List List_Waiting_Threads List_Waiting_Threads_2} proc {$ P} {Wait P} end}
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

        Variables.nber_HistoricFiles = {Historic_user.get_Nber_HistoricFile}

        % Initialization of the global variables used in the program
        Variables.idx_N_Grams = 2     
        Variables.tweetsFolder_Name = {GetSentenceFolder}
        Variables.list_PathName_Tweets = {OS.getDir Variables.tweetsFolder_Name}
        Variables.nberFiles = {Length Variables.list_PathName_Tweets}

        % More threads than files is useless in this case.
        % We take the maximum because the threads are 'false' threads.
        % They are not really threads but they are used to split the work between the files.
        % There is no overhead to create more threads.
        Variables.nbThreads = Variables.nberFiles

        Variables.port_Tree = {NewPort Variables.stream_Tree}
    
        {Property.put print foo(width:1000 depth:1000)}

        % Description of the GUI
        Variables.description = {Interface_improved.getDescriptionGUI proc{$} _={Press} end}

        % Creation of the GUI
        Variables.window = {QTk.build Variables.description}
        {Variables.window show}
        
        % Writes some text in the GUI to inform the user
        {Interface.insertText_Window Variables.inputText 0 0 'end' "Loading... Please wait."}
        {Variables.inputText bind(event:"<Control-s>" action:proc {$} _ = {Press} end)} % You can also bind events
        {Interface.insertText_Window Variables.outputText 0 0 'end' "You must wait until the database is parsed.\nA message will notify you.\nDon't press the 'predict' button until the message appears!\n"}

        % Create the Port to communicate between the threads
        Variables.separatedWordsPort = {NewPort Variables.separatedWordsStream}

        % Launch all threads to reads and parses the files
        {LaunchThreads Variables.separatedWordsPort Variables.nbThreads}

        % We retrieve the information (parsed lines of the files) from the port's stream
        local List_Line_Parsed Main_Tree in
            {Send Variables.separatedWordsPort nil}
            List_Line_Parsed = {Function.get_ListFromPortStream}

            % Writes some text in the GUI to inform the user
            {Interface.insertText_Window Variables.outputText 6 0 none "Step 1 Over : Reading + Parsing\n"}

            % Creation of the main binary tree (with all subtree as value)
            Main_Tree = {Tree.updateAll_Tree {Tree.createTree List_Line_Parsed} fun {$ NewTree Key Value}
                {Tree.insert NewTree Key {Tree.createSubTree Value}} end fun {$ _ _} true end _} % The Condition is always true because we want to visit and update all the node of the tree
            {Send Variables.port_Tree Main_Tree}
        end
        
        % We bound the value 'Variables.tree_Over' => {Press} can work now because the structure is ready
        Variables.tree_Over = true

        % Writes some text in the GUI to inform the users
        {Interface.insertText_Window Variables.outputText 7 0 none "Step 2 Over : Stocking datas\n"}
        {Interface.insertText_Window Variables.outputText 9 0 none "The database is now parsed.\nYou can write and predict!"}
        
        % Delete the text "Loading... Please wait." from the GUI or all if the user add some text between or before the line : "Loading... Please wait."
        if {Function.findPrefix_InList {Variables.inputText getText(p(1 0) 'end' $)} "Loading... Please wait."} then
            % Remove the first 23 characters (= "Loading... Please wait.")
            {Variables.inputText tk(delete p(1 0) p(1 23))}
        else
            % Remove all because the user add some texts between or before the line : "Loading... Please wait."
            {Interface.setText_Window Variables.inputText ""}
        end
        
        thread {Automatic_prediction.automatic_Prediction 1000} end

        %%ENDOFCODE%%
    end

    % Call the main procedure
    {Main}
end