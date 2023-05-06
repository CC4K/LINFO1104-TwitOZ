functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    OS
    Open
    System
    
    Variables at '../variables.ozf'
    Function at '../function.ozf'
    Reader at '../reader.ozf'
    Parser at '../parser.ozf'
    Tree at '../tree.ozf'
    N_grams at 'n_grams.ozf'

export
    LaunchThreads_HistoricUser % Launches a thread for evry historic files of the user
    SaveFile_Database % Saves a file from the app window as a text file into the database (historic user)
    SaveText_Database % Saves an input text from the app window as a text file into the database (historic user)
    Clean_UserHistoric % Deletes all the historic files of the user (historic user)
    Get_Nber_HistoricFile % Get the number of current historic files
define


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
    % Saves a file from the app window as a text file into the database (historic user).
    % The datas will be directly therefore be used for the next prediction.
    % When the user will close the app, the datas won't be deleted.
    %
    % @param: /
    % @return: /
    %%%
    proc {SaveFile_Database}
        try
            local User_File_Name User_File Contents New_Nber_HistoricFiles Historic_NberFiles_File Name_File Historic_File in

                User_File_Name = {QTk.dialogbox load(defaultextension:"txt"
                                filetypes:q(q("Txt files" q(".txt")) q("All files" q("*"))) $)}
                
                if User_File_Name == nil then skip
                else
                    User_File = {New Open.file init(name:User_File_Name flags:[read])}
                    Contents = {User_File read(list:$ size:all)}
                    {User_File close}

                    New_Nber_HistoricFiles = {Get_Nber_HistoricFile} + 1
                    {Write_New_Nber_HistoricFile New_Nber_HistoricFiles}

                    % Get the name of the new file to create and open it
                    Name_File = {Function.append_List "user_historic/user_files/historic_part" {Function.append_List {Int.toString New_Nber_HistoricFiles} ".txt"}}
                    Historic_File = {New Open.file init(name:Name_File flags:[write create truncate])}
                    {Historic_File write(vs:Contents)}
                    {Historic_File close}
                    
                    % Send the new upated tree to a global port
                    {Send_NewTree_ToPort Name_File}
                end
            end
        catch _ then {System.show 'Error when saving the file into the databse'} {Application.exit 0} end 
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
                {Write_New_Nber_HistoricFile New_Nber_HistoricFiles}

                % Get the name of the new file to create and open it
                Name_File = {Function.append_List "user_historic/user_files/historic_part" {Function.append_List {Int.toString New_Nber_HistoricFiles} ".txt"}}
                Historic_File = {New Open.file init(name:Name_File flags:[write create truncate])}
                Contents = {Variables.inputText get($)}
                {Historic_File write(vs:Contents)}
                {Historic_File close}
                
                % Send the new upated tree to a global port
                {Send_NewTree_ToPort Name_File}
            end

        catch _ then {System.show 'Error when saving the user text into the database'} {Application.exit 0} end
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


    %%%
    % Writes the new number of historic files into the file "nber_historic_files.txt".
    %
    % @param New_Nber_HistoricFiles: The new number of historic files
    % @return: /
    %%%
    proc {Write_New_Nber_HistoricFile New_Nber_HistoricFiles}
        local Historic_NberFiles_File in
            Historic_NberFiles_File = {New Open.file init(name:"user_historic/nber_historic_files.txt" flags:[write create truncate])}
            {Historic_NberFiles_File write(vs:{Int.toString New_Nber_HistoricFiles})}
            {Historic_NberFiles_File close}
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
                P=1
                {Wait P}
                NewTree = {Create_Updated_Tree {Function.get_Last_Elem_Stream Variables.stream_Tree} File_Parsed}
                % Send to the port the new update tree with the new datas
                {Send Variables.port_Tree NewTree}
            end
        end
    end

    
    %%%
    % Create the new updated tree with the new datas added.
    %
    % Note: we could probably try to merge some functions with the ones in "tree.oz",
    % but we didn't want to have some extra parameter for nothing for the basic version.
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

            %%%
            % Update one Subtree of the main tree's value.
            %%%
            fun {Update_SubTree SubTree New_Value}
                local
                    Result Value_Key1
                    fun {Update_SubTree_Aux SubTree Updated_SubTree}
                        case SubTree
                        of leaf then [Updated_SubTree false]
                        [] tree(key:Key value:Value_List t_left:TLeft t_right:TRight) then

                            local New_List_Value First_Updated_Tree ValueAtKeySupp in

                                if {Function.isInList Value_List New_Value} == false then
                                    _ = {Update_SubTree_Aux TLeft Updated_SubTree}
                                    _ = {Update_SubTree_Aux TRight Updated_SubTree}
                                else

                                    if {Length Value_List} == 1 then [{Tree.insert_Key Updated_SubTree Key Key+1} true]
                                    else
                                        New_List_Value = {RemoveElemOfList Value_List New_Value}
                                        First_Updated_Tree = {Tree.insert_Value Updated_SubTree Key New_List_Value}
                                        ValueAtKeySupp = {Tree.lookingUp First_Updated_Tree Key+1}
                                        if ValueAtKeySupp == notfound then
                                            [{Tree.insert_Value First_Updated_Tree Key+1 [New_Value]} true]
                                        else
                                            [{Tree.insert_Value First_Updated_Tree Key+1 New_Value|ValueAtKeySupp} true]
                                        end
                                    end
                                end
                            end
                        end
                    end
                in
                    Result = {Update_SubTree_Aux SubTree SubTree}
                    if Result.2.1 == true then Result.1
                    else
                        Value_Key1 = {Tree.lookingUp SubTree 1}
                        if Value_Key1 == notfound then {Tree.insert_Value SubTree 1 [New_Value]}
                        else {Tree.insert_Value SubTree 1 New_Value|Value_Key1} end
                    end
                end
            end
    
            %%%
            % Get the new subtree updated with the new datas added.
            % The key is an element of the n-gram and the value associated is the last word of the next element in the n-gram.
            %%%
            fun {Deal_ListKeys Tree_To_Update List_Keys}
                case List_Keys
                of nil then Tree_To_Update
                [] _|nil then Tree_To_Update
                [] H|T then

                    local Key Value_to_Insert New_Tree_Value Tree_Value Updated_Tree in

                        Key = {String.toAtom H}
                        Value_to_Insert = {String.toAtom {Reverse {Function.tokens_String T.1 32}}.1}
                        Tree_Value = {Tree.lookingUp Tree_To_Update Key}
                        
                        if Tree_Value == notfound then
                            New_Tree_Value = {Tree.insert_Value leaf 1 [Value_to_Insert]}
                        else
                            New_Tree_Value = {Update_SubTree Tree_Value Value_to_Insert}
                        end

                        Updated_Tree = {Tree.insert_Value Tree_To_Update Key New_Tree_Value}
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
                    local List_Keys_N_grams Updated_Tree in
                        List_Keys_N_grams = {N_grams.n_grams {Function.tokens_String H 32}}
                        Updated_Tree = {Deal_ListKeys Main_Tree List_Keys_N_grams}
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