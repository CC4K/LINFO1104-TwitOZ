functor
import 
    Open
    Application
    System

    Function at 'function.ozf'
    Variables at 'variables.ozf'
export
    GetFilename % Get the filename of the Idxth file in the list of filenames
    Read % Read a text file and return a list of all its lines
define

    %%%
    % Creates a text file object to open and read a text file
    %%%
    class TextFile
        from Open.file Open.text
    end


    %%%
    % Reads a text file (given its filename) and creates a list of all its lines
    %
    % Example usage:
    % In: "tweets/part_1.txt"
    % Out: ["Congress must..." "..." "..." "..." "..."]
    %
    % @param Filename: a string representing the path to the file
    % @return: a list of all lines in the file, where each line is a string
    %%%
    fun {Read Filename}
        local
            Error_Name % Used to display an error message if the file cannot be read
            fun {GetLine Text_File List_Line}
                local Line in
                    % If the file is not empty, read the next line and add it to the list
                    Line = {Text_File getS($)}
                    if Line == false then {Text_File close} List_Line
                    else {GetLine Text_File Line|List_Line} end
                end
            end
        in
            try
                % Read the file and create the list of line and return it
                {GetLine {New TextFile init(name:Filename flags:[read])} nil}
            catch _ then
                % If the file cannot be read, display an error message and exit the program
                Error_Name = {Function.append_List "Error when reading the file named : " Filename}
                {System.show {String.toAtom Error_Name}}
                {Application.exit 0}
                none
            end
        end
    end
    % {Browse {Reader {GetFilename 1}}} % une liste avec ttes les lignes du fichier 1


    %%%
    % Creates a filename by combining the name of a folder and the nth filename in a list of filenames
    %
    % Example usage:
    % In: "tweets" ["part_1.txt" "part_2.txt"] 2
    % Out: "tweets/part_2.txt"
    %
    % @param Idx: an index representing the position of the desired filename in List_PathName
    % @return: a string representing the desired filename (the Idxth filename in the list) preceded by the folder name + "/"
    %%%
    fun {GetFilename Idx}
        local PathName in
            PathName = {Function.nth_List Variables.list_PathName_Tweets Idx}
            if {String.is PathName} then
                {Function.append_List Variables.folder_Name 47|PathName}
            else {Function.append_List Variables.folder_Name 47|{Atom.toString PathName}} end
        end
    end

end