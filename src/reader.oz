functor
import 
    Open
    Browser

    Parser at 'parser.ozf'
export
    GetFilename Reader
define

    class TextFile
        from Open.file Open.text
    end

    %%%
    % Creates a list of all the lines of a file given its filename
    % In : "tweets/part_1.txt"
    % Out : ["Congress must..." "..." "..." "..." "..."]
    %
    % @Filename : a string being the path to the file we want to read
    % @return : a list of all the lines of in the file
    %%%
    fun {Reader Filename}
        fun {GetLine TextFile}
            Line = {TextFile getS($)}
        in
            if Line == false then
                {TextFile close}
                nil
            else
                {Parser.cleanUp Line}|{GetLine TextFile}
            end
        end
    in
        {GetLine {New TextFile init(name:Filename flags:[read])}}
    end

    %%%
    % Creates a filename from the nth filename in a list of filenames and the name of a folder
    % In : "tweets" ["part_1.txt" "part_2.txt"] 2
    % Out : "tweets/part_2.txt"
    %
    % @TweetsFolder_Name : a string being the name of a folder
    % @List_PathName : a list of filenames
    % @Idx : an index
    % @return : the Idxth filename in the list preceded by the folder name
    %%%
    fun {GetFilename TweetsFolder_Name List_PathName Idx}
        local PathName in
            PathName = {List.nth List_PathName Idx}
            {Append {Append TweetsFolder_Name "/"} PathName}
        end
    end

end