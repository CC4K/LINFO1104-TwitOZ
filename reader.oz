functor
import 
    Open
    Browser

    Parser at 'parser.ozf'
define

    class TextFile
        from Open.file Open.text
    end

    %%% Create a list with all line of the file named "Filename"
    fun {Reader Filename}
        fun {GetLine TextFile}
            Line = {TextFile getS($)}
        in
            if Line == false then
                {TextFile close}
                nil
            else
                {Parser.CleanUp Line} | {GetLine TextFile}
            end
        end
    in
        {GetLine {New TextFile init(name:Filename flags:[read])}}
    end
    % {Browse {Reader {GetFilename 1}}} % une liste avec ttes les lignes du fichier 1


    %%% Create the filename "tweets/part_N.txt" where N is given in argument
    fun {GetFilename List_PathName Idx}
        {List.nth List_PathName Idx}
    end
    % {Browse {String.toAtom {GetFilename 1}}} % "tweets/part_1.txt"
end