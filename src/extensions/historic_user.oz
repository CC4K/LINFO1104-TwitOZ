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
    Create_Updated_Tree_Aux
    Update_SubTree
    Get_List_Value
    AddElemToList_InTree
    RemoveElemOfList
    Clean_UserHistoric
    Delete_HistoricFiles
    Get_Nber_HistoricFile
    LaunchThreads_HistoricUser
define


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% ====== 4eme EXTENSION ====== %%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%% DATABASE ADDER SENTENCES IMPLEMENTATION  %%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%
    % Saves an input text from the app window as a text file into the database.
    % The datas will be therefore be used for the next prediction.
    % @param: /
    % @return: /
    %%%
    proc {SaveText_Database}

        % Name folder to stock the historic of user
        PathHistoricFile = "user_historic/user_files/historic_part"
    in
        try
            % Open the file where the number of historic files is stored
            Historic_NberFiles_File_Reading = {New Open.file init(name:"user_historic/nber_historic_files.txt" flags:[read])}

            % Read this file to get the number of historic files incremented of 1
            Nber_HistoricFiles = {String.toInt {Historic_NberFiles_File_Reading read(list:$ size:all)}} + 1

            {Historic_NberFiles_File_Reading close}

            Historic_NberFiles_File_Writing = {New Open.file init(name:"user_historic/nber_historic_files.txt" flags:[write create truncate])}

            % Write the new number of historic files in the file
            {Historic_NberFiles_File_Writing write(vs:{Int.toString Nber_HistoricFiles})}

            % Get the name of the new file to create
            Name_File = {Function.append_List PathHistoricFile {Function.append_List {Int.toString Nber_HistoricFiles} ".txt"}}

            % Open the file
            Historic_File = {New Open.file init(name:Name_File flags:[write create truncate])}

            % Get the contents of the user
            Contents = {Variables.inputText get($)}
        in
            % Close the file where the number of historic files is stored
            {Historic_NberFiles_File_Writing close}

            % Write the datas in the file to save them for the next usage
            {Historic_File write(vs:Contents)}

            % Close the file where the user historic datas are stored
            {Historic_File close}

            % Send the new tree to the port
            {Send_NewTree_ToPort Name_File}
        catch _ then {System.show 'Error when saving the file into the database'} {Application.exit 0} end
    end


    %%%% TODO %%%%
    proc {Send_NewTree_ToPort Name_File}
        local NewTree LineToParsed File_Parsed L P in
            thread _ =
                LineToParsed = {Reader.read Name_File}
                L=1
                {Wait L} 
                File_Parsed = {Parser.parses_AllLines LineToParsed}
                P=1
                {Wait P}
                NewTree = {Create_Updated_Tree {Function.get_Tree} File_Parsed}
                % Send to the port the new update tree with the new datas
                {Send Variables.port_Tree NewTree}
            end
        end
    end

    
    %%%
    % Adds the datas of a text to the main tree.
    %
    % @param Tree: The tree to which we want to add the datas
    % @param TextUserInput: The user text from which we want to add the datas
    % @return: The new main tree updated with the new datas added
    %%%
    fun {Create_Updated_Tree Main_Tree List_UserInput}
        case List_UserInput
        of nil then Main_Tree
        [] H|T then
            {Create_Updated_Tree {Create_Updated_Tree_Aux Main_Tree {N_Grams.n_Grams {Function.tokens_String H 32}}} T}
        end
    end


     %%%% TODO %%%%
    fun {Create_Updated_Tree_Aux New_Tree List_Keys}
        local
            %%%
            % Changes the value with a new specified one at the location of a specified key in a binary tree
            %%%
            fun {Update_Value New_Tree Key List_Keys}
                local Value_to_Insert Tree_Value New_Tree_Value in
                    Value_to_Insert = {String.toAtom {Reverse {Function.tokens_String List_Keys.1 32}}.1}
                    Tree_Value = {Tree.lookingUp New_Tree Key}
                    New_Tree_Value = {Update_SubTree Tree_Value Key Value_to_Insert}
                    {Tree.insert New_Tree Key New_Tree_Value}
                end
            end
        in
            case List_Keys
            of nil then New_Tree
            [] _|nil then New_Tree
            [] H|T then
                {Create_Updated_Tree_Aux {Update_Value New_Tree {String.toAtom H} T} T}
            end
        end
    end


    %%%% TODO %%%%
    fun {Update_SubTree SubTree Key NewValue}
        if SubTree == notfound then {Tree.insert leaf 1 [NewValue]}
        else
            local Updated_SubTree List_Value in
                Updated_SubTree = {Get_List_Value SubTree NewValue}
                if SubTree == Updated_SubTree then
                    List_Value = {Tree.lookingUp SubTree 1}
                    if List_Value == notfound then {Tree.insert SubTree 1 [NewValue]}
                    else {Tree.insert SubTree 1 NewValue|List_Value} end
                else
                    Updated_SubTree
                end
            end
        end
    end


     %%%% TODO %%%%
    fun {Get_List_Value SubTree Value_Word}
        local
            fun {Get_List_Value_Aux SubTree Updated_SubTree}
                case SubTree
                of leaf then Updated_SubTree
                [] tree(key:Key value:Value_List t_left:TLeft t_right:TRight) then
                    local T1 New_List_Value Length_Value_List in
                        if {Function.isInList Value_List Value_Word} == true then
                            Length_Value_List = {Length Value_List}
                            if Length_Value_List == 1 then {Tree.insert_Key Updated_SubTree Key Key+1}
                            else
                                New_List_Value = {RemoveElemOfList Value_List Value_Word}
                                if Length_Value_List == {Length New_List_Value} then {AddElemToList_InTree Updated_SubTree Key+1 Value_Word}
                                else {AddElemToList_InTree {Tree.insert Updated_SubTree Key New_List_Value} Key+1 Value_Word} end
                            end
                        else
                            T1 = {Get_List_Value_Aux TLeft Updated_SubTree}
                            _ = {Get_List_Value_Aux TRight T1}
                        end
                    end
                end
            end
        in
            {Get_List_Value_Aux SubTree SubTree}
        end
    end


     %%%% TODO %%%%
    fun {AddElemToList_InTree SubTree Key Word_Value}
        local Value_List in
            Value_List = {Tree.lookingUp SubTree Key}
            if Value_List == notfound then {Tree.insert SubTree Key [Word_Value]}
            else {Tree.insert SubTree Key Word_Value|Value_List} end
        end
    end


     %%%% TODO %%%%
    fun {RemoveElemOfList Value_List Value_Word}
        local
            fun {RemoveElemOfList_Aux Value_List New_Value_List}
                case Value_List
                of nil then New_Value_List
                [] H|T then
                    if H == Value_Word then {Function.append_List New_Value_List T}
                    else {RemoveElemOfList_Aux T H|New_Value_List} end
                end
            end
        in
            {RemoveElemOfList_Aux Value_List nil}
        end
    end


     %%%% TODO %%%%
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


    %%%% TODO %%%%
    proc {Delete_HistoricFiles}
        {OS.pipe make "clean_user_historic"|nil _ _}
    end



     %%%% TODO %%%%
    fun {Get_Nber_HistoricFile}
        local Historic_NberFiles_File Nber_HistoricFiles in
            Historic_NberFiles_File = {New Open.file init(name:"user_historic/nber_historic_files.txt" flags:[read])}
            Nber_HistoricFiles = {String.toInt {Historic_NberFiles_File read(list:$ size:all)}}
            {Historic_NberFiles_File close}
            Nber_HistoricFiles
        end
    end

     
    %%%% TODO %%%%
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

end