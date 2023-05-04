functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
    OS
    System
    
    Variables at '../variables.ozf'
    Function at '../function.ozf'
    Reader at '../reader.ozf'
    Parser at '../parser.ozf'
    Tree at '../tree.ozf'
    N_Grams at 'n_Grams.ozf'

export
    SaveText_Database
    Send_NewTree_ToPort
    Create_Updated_Tree
    Clean_UserHistoric
    Delete_HistoricFiles
    Get_Nber_HistoricFile
    LaunchThreads_HistoricUser
define


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% ====== 4eme EXTENSION ====== %%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%% DATABASE ADDER SENTENCES IMPLEMENTATION  %%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    %%%%
    % Launches a thread for evry historic files of the user.
    % This function is called at the beginning of the program.
    %
    % @param: /
    % @return: a list of waiting threads numbers
    %%%%
    fun {LaunchThreads_HistoricUser}
        local
            fun {LaunchThreads_HistoricUser_Aux Id_Thread List_Waiting_Threads}
                if Id_Thread == Variables.nber_HistoricFiles + 1 then List_Waiting_Threads
                else
                    local File_Parsed File LineToParsed L P in
                        thread _ =
                            File = {Function.append_List "user_historic/user_files/historic_part" {Function.append_List {Int.toString Id_Thread} ".txt"}}
                            LineToParsed = {Reader.read File}
                            L=1
                            {Wait L} 
                            File_Parsed = {Parser.parses_AllLines LineToParsed}
                            P=1
                            {Send Variables.separatedWordsPort File_Parsed}
                        end
                        
                        {LaunchThreads_HistoricUser_Aux Id_Thread+1 P|List_Waiting_Threads}
                    end
                end
            end
        in
            {LaunchThreads_HistoricUser_Aux 1 nil}
        end
    end




    %%%
    % Saves an input text from the app window as a text file into the database (historic user).
    % The datas will be directly therefore be used for the next prediction.
    % When the user will close the app, the datas won't be deleted.
    %
    % @param: /
    % @return: /
    %%%
    proc {SaveText_Database}
        try
            local New_Nber_HistoricFiles Historic_NberFiles_File Name_File Historic_File Contents in

                New_Nber_HistoricFiles = {Get_Nber_HistoricFile} + 1

                % Open the file where the number of historic files is stored
                % And increment the number of historic files by 1
                Historic_NberFiles_File = {New Open.file init(name:"user_historic/nber_historic_files.txt" flags:[write create truncate])}
                {Historic_NberFiles_File write(vs:{Int.toString New_Nber_HistoricFiles})}
                {Historic_NberFiles_File close}

                % Get the name of the new file to create and open it
                Name_File = {Function.append_List "user_historic/user_files/historic_part" {Function.append_List {Int.toString New_Nber_HistoricFiles} ".txt"}}
                Historic_File = {New Open.file init(name:Name_File flags:[write create truncate])}
                Contents = {Variables.inputText get($)}
                {Historic_File write(vs:Contents)}
                {Historic_File close}

                % Send the new upated tree to a global port
                {Send_NewTree_ToPort Name_File}
            end

        catch _ then {System.show 'Error when saving the file into the database'} {Application.exit 0} end
    end


    %%%%
    % Get the number of current historic files.
    %
    % @param: /
    % @return: The number of current historic files
    %%%%
    fun {Get_Nber_HistoricFile}
        local Historic_NberFiles_File Nber_HistoricFiles in
            Historic_NberFiles_File = {New Open.file init(name:"user_historic/nber_historic_files.txt" flags:[read])}
            Nber_HistoricFiles = {String.toInt {Historic_NberFiles_File read(list:$ size:all)}}
            {Historic_NberFiles_File close}
            Nber_HistoricFiles
        end
    end


    %%%%
    % Launch a thread to read and parse a file and
    % send the new updated tree to a global port.
    %
    % @param Name_File: The name of the file to read and parses
    % @return: /
    %%%%
    proc {Send_NewTree_ToPort Name_File}
        local NewTree LineToParsed File_Parsed L P in
            thread _ =
                LineToParsed = {Reader.read Name_File}
                L=1
                {Wait L} 
                File_Parsed = {Parser.parses_AllLines LineToParsed}
                {System.show File_Parsed}
                P=1
                NewTree = {Create_Updated_Tree {Function.get_Tree} File_Parsed}
                % Send to the port the new update tree with the new datas
                {Send Variables.port_Tree NewTree}
            end
        end
    end

    
    %%%
    % Create the new updated tree with the new datas added.
    %
    % @param Main_Tree: The tree to which we want to add the datas
    % @param List_UserInput: The user text parsed
    % @return: The new main tree updated with the new datas added
    %%%
    fun {Create_Updated_Tree Main_Tree List_UserInput}
        local

            %%%
            % Remove an element from a list.
            %%%
            fun {RemoveElemOfList Value_List Value_To_Remove}
                local
                    fun {RemoveElemOfList_Aux Value_List New_Value_List}
                        case Value_List
                        of nil then New_Value_List
                        [] H|T then
                            if H == Value_To_Remove then {Function.append_List New_Value_List T}
                            else {RemoveElemOfList_Aux T H|New_Value_List} end
                        end
                    end
                in
                    {RemoveElemOfList_Aux Value_List nil}
                end
            end

            % Variables usefull to clarrify the code
            Updated_SubTree Current_List_Value

            %%%
            % Update one Subtree of the main tree's value.
            %%%
            fun {Update_SubTree SubTree Key New_Value}
                local 
                    fun {Update_SubTree_Aux SubTree Updated_SubTree}
                        case SubTree
                        of leaf then Updated_SubTree
                        [] tree(key:Key value:Value_List t_left:TLeft t_right:TRight) then

                            local T1 New_List_Value First_Updated_Tree ValueAtKeySupp in

                                if {Function.isInList Value_List New_Value} == false then
                                    T1 = {Update_SubTree_Aux TLeft Updated_SubTree}
                                    _ = {Update_SubTree_Aux TRight T1}
                                else

                                    if {Length Value_List} == 1 then {Tree.insert_Key Updated_SubTree Key Key+1}
                                    else
                                        New_List_Value = {RemoveElemOfList Value_List New_Value}
                                        First_Updated_Tree = {Tree.insert_Value Updated_SubTree Key New_List_Value}

                                        ValueAtKeySupp = {Tree.lookingUp First_Updated_Tree Key+1}
                                        if ValueAtKeySupp == notfound then
                                            {Tree.insert_Value First_Updated_Tree Key+1 [New_Value]}
                                        else
                                            {Tree.insert_Value First_Updated_Tree Key+1 New_Value|ValueAtKeySupp}
                                        end
                                    end
                                end
                            end
                        end
                    end
                in
                    {Update_SubTree_Aux SubTree SubTree}
                end
            end
    
            %%%
            % Get the new subtree updated with the new datas added.
            % The key is an element of the n-gram and the value associated is the last word of the next element in the n-gram.
            %%%
            fun {Deal_ListKeys New_Tree List_Keys}
                case List_Keys
                of nil then New_Tree
                [] _|nil then New_Tree
                [] H|T then
                    local Key Value_to_Insert Tree_Value New_Tree_Value Updated_Tree in
                        Key = {String.toAtom H}
                        Value_to_Insert = {String.toAtom {Reverse {Function.tokens_String T.1 32}}.1}
                        Tree_Value = {Tree.lookingUp New_Tree Key}

                        if Tree_Value == notfound then
                            New_Tree_Value = {Tree.insert_Value leaf 1 [Value_to_Insert]}
                        else
                            New_Tree_Value = {Update_SubTree Tree_Value Key Value_to_Insert}
                        end

                        Updated_Tree = {Tree.insert_Value New_Tree Key New_Tree_Value}
                        {Deal_ListKeys Updated_Tree T}
                    end
                end
            end

            %%%
            % Create the new updated tree with the new datas added.
            %%%
            fun {Create_Updated_Tree_Aux Main_Tree List_UserInput}
                case List_UserInput
                of nil then Main_Tree
                [] H|T then
                    local List_Keys_N_Grams Updated_Tree in
                        List_Keys_N_Grams = {N_Grams.n_Grams {Function.tokens_String H 32}}
                        Updated_Tree = {Deal_ListKeys Main_Tree List_Keys_N_Grams}
                        {Create_Updated_Tree_Aux Updated_Tree T}
                    end
                end
            end

        in
            {Create_Updated_Tree_Aux Main_Tree List_UserInput}
        end
    end



    %%%%
    % Clean the historic of the user.
    % Delete all the files of the historic and reset the number of historic files to 0.
    %
    % @param: /
    % @return: /
    %%%%
    proc {Clean_UserHistoric}
        local Historic_NberFiles_File in
            % Open the file where the number of historic files is stored and reset it to 0
            Historic_NberFiles_File = {New Open.file init(name:"user_historic/nber_historic_files.txt" flags:[write])}
            {Historic_NberFiles_File write(vs:{Int.toString 0})}
            {Historic_NberFiles_File close}

            % Delete all the historic files
            {Delete_HistoricFiles}
        end
    end


    %%%%
    % Delete all the historic files.
    % To do it, we use a pipe to execute a shell command in the MakFile.
    %
    % @param: /
    % @return: /
    %%%%
    proc {Delete_HistoricFiles}
        {OS.pipe make "clean_user_historic"|nil _ _}
    end

end