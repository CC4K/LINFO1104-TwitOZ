functor
import 
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    OS
    System
    Property

    Variables at 'variables.ozf'
    Interface at 'interface.ozf'
    Function at 'function.ozf'
    Parser at 'parser.ozf'
    Tree at 'tree.ozf'
    Reader at 'reader.ozf'

    Automatic_prediction at 'extensions/automatic_prediction.ozf'
    Historic_user at 'extensions/historic_user.ozf'
    Interface_improved at 'extensions/interface_improved.ozf'
    N_grams at 'extensions/n_grams.ozf'
    Predict_All at 'extensions/predict_All.ozf'

define

    %%%
    % Displays to the output zone on the window the most likely prediction of the next word based on the N last entered words.
    % The value of N depends of the N-grams asked by the user.
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
            local Input_User Splitted_Text List_Words Key Parsed_Key Tree_Value ResultPress ProbableWords Frequency Probability in

                % Clean the input user and get the N last words (N depends of the N-grams asked by the user)
                Input_User = {Variables.inputText getText(p(1 0) 'end' $)}
                Splitted_Text = {Parser.cleaningUserInput Input_User}
                List_Words = {Function.get_Last_Nth_Word_List Splitted_Text Variables.idx_N_grams}

                if {Length List_Words} >= Variables.idx_N_grams then

                    % Get the subtree representing the value at the key created by the concatenation of the N last words
                    Key = {Function.concatenateElemOfList List_Words 32}
                    Tree_Value = {Tree.lookingUp {Function.get_Last_Elem_Stream Variables.stream_Tree} {String.toAtom Key}}

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
                            _ = {Predict_All.proposeAllTheWords ProbableWords Frequency Probability true}

                            % Return the most probable word(s) and the highest probability/frequency
                            [ProbableWords Probability]

                            %% Basic version %%
                            % {Interface.setText_Window OutputText ProbableWords.1}
                        end
                    end
                else
                    % Not enough words to predict the next one
                    {Interface.setText_Window Variables.outputText {Append "Need at least " {Append {Int.toString Variables.idx_N_grams} " words to predict the next one."}}}
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
            List_Waiting_Threads_1
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
                            File = {Reader.getFilename Start}
                            % File = "tweets/custom.txt"
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
                        {Launch_AllThreads {Function.append_List {Launch_OneThread Start End nil} List_Waiting_Threads} Nber_Threads-1}
                    end
                end

            end
        in 
            % Launch all the threads
            % The parsing files are stocked in the Port
            % The variables to Wait all the threads are stocked in List_Waiting_Threads

            thread List_Waiting_Threads_1 = {Launch_AllThreads nil N} end

            % To also parse the historic user files (Extension)
            thread List_Waiting_Threads_2 = {Historic_user.launchThreads_HistoricUser} end
            
            % Wait for all the threads
            % When a thread have finished, the value P associated to this thread
            % is bind and the program can move on 
            {ForAll {Function.append_List List_Waiting_Threads_1 List_Waiting_Threads_2} proc {$ P} {Wait P} end}
        end
    end


    %%%
    % Get the arguments of the command line for the program and store them in global variables
    % 
    % @param: /
    % @return: /
    %%%
    proc {Get_Arguments}

        UserOptions = {Application.getArgs record('folder'(single type:string optional:false)
                                                  'ext'(single type:string default:none optional:true)
                                                  'idx_n_grams'(single type:int default:2 optional:true)
                                                  'corr_word'(single type:int default:0 optional:true)
                                                  'files_database'(single type:int default:0 optional:true)
                                                  'auto_predict'(single type:int default:0 optional:true))}
    in
        Variables.folder_Name = UserOptions.'folder'
        local N_grams in
            N_grams = UserOptions.'idx_n_grams'
            if N_grams >= 1 then
                Variables.idx_N_grams = N_grams
            else
                {System.show 'The value of idx_n_grams must be greater or equal than 1.'}
                {Application.exit 0}
            end
        end

        if UserOptions.'ext' == "all" then
            Variables.correction_Words = 1
            Variables.files_Database = 1
            Variables.auto_Prediction = 1
        else
            if UserOptions.'corr_word' \= 1 then 
                Variables.correction_Words = 0
            else
                Variables.correction_Words = 1
            end

            if UserOptions.'files_database' \= 1 then 
                Variables.files_Database = 0
            else
                Variables.files_Database = 1
            end

            if UserOptions.'auto_predict' \= 1 then 
                Variables.auto_Prediction = 0
            else
                Variables.auto_Prediction = 1
            end
        end
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

        % Get the arguments of the command line and store them in global variables
        {Get_Arguments}

        % Reset the last prediction file (from the previous execution of the program)
        {Automatic_prediction.reset_LastPrediction_File}

        % Initialization of the global variables used in the program
        Variables.nber_HistoricFiles = {Historic_user.get_Nber_HistoricFile}
        Variables.list_PathName_Tweets = {OS.getDir Variables.folder_Name}
        Variables.nberFiles = {Length Variables.list_PathName_Tweets}
        Variables.nbThreads = Variables.nberFiles
        Variables.port_Tree = {NewPort Variables.stream_Tree}
        Variables.separatedWordsPort = {NewPort Variables.separatedWordsStream}
        Variables.port_Auto_Corr_Threads = {NewPort Variables.stream_Auto_Corr_Threads}
        {Send Variables.port_Auto_Corr_Threads 0}

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

        % Launch all threads to reads and parses the files
        {LaunchThreads Variables.separatedWordsPort Variables.nbThreads}

        % We retrieve the information (parsed lines of the files) from the port's stream
        local List_Line_Parsed Main_Tree in
            {Send Variables.separatedWordsPort nil}
            List_Line_Parsed = {Function.get_ListFromPortStream}

            % Writes some text in the GUI to inform the user
            {Interface.insertText_Window Variables.outputText 6 0 none "Step 1 Over : Reading + Parsing\n"}

            % Creation of the main binary tree (with all subtree as value)
            Main_Tree = {Tree.create_Main_Tree {Tree.create_Basic_Tree List_Line_Parsed}}
            {Send Variables.port_Tree Main_Tree}
        end

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

        % To see the message "The database is now parsed.\nYou can write and predict!" at the beginning of the program
        % during 1.5 second.
        {Time.delay 1500}
        
        % We bound the value 'Variables.tree_Over'
        % => {Press} can work now because the structure is ready
        Variables.tree_Over = true

        if Variables.auto_Prediction == 1 then
            % Launch one thread that will predict the next word every 0.5sec
            % => The user can write and the words will be predicted at the same time!
            thread {Automatic_prediction.automatic_Prediction 500} end
        else skip end

        %%ENDOFCODE%%
    end

    % Call the main procedure to start the program.
    {Main}
end