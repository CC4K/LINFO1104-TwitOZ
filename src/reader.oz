functor
import 
    Open
    Parser at 'parser.ozf'
    Function at 'function.ozf'
export
    getfilename:GetFilename
    read:Read
define

    %%%
    % Class used to open the files, read it and close it.
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
        fun {GetLine TextFile ListLine}
            Line = {TextFile getS($)}
        in
            if Line == false then
                {TextFile close}
                ListLine
            else
                % {Browse {String.toAtom Line}}
                % {Browse {String.toAtom {CleanUp Line fun {$ LineStr} {RemovePartList LineStr [226 128] 32 true} end}}}

                % [226 128] is a character that is not recognised by UTF-8 (the follow char too). That's why the last argument is set to true.
                {GetLine TextFile {Parser.cleanUp Line fun {$ LineStr} {Parser.removePartList LineStr [226 128] 32 true} end}|ListLine}
            end
        end
    in
        {GetLine {New TextFile init(name:Filename flags:[read])} nil}
    end
    

    %%%
    % Creates a filename by combining the name of a folder and the nth filename in a list of filenames
    %
    % Example usage:
    % In: "tweets" ["part_1.txt" "part_2.txt"] 2
    % Out: "tweets/part_2.txt"
    %
    % @param TweetsFolder_Name: a string representing the name of a folder
    % @param List_PathName: a list of filenames
    % @param Idx: an index representing the position of the desired filename in List_PathName
    % @return: a string representing the desired filename (the Idxth filename in the list) preceded by the folder name + "/"
    %%%
    fun {GetFilename TweetsFolder_Name List_PathName Idx}
        {Function.append_List TweetsFolder_Name 47|{Function.nth_List List_PathName Idx}}
    end

end