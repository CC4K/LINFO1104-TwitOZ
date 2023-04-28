functor
import 
    Open
    Parser at 'parser.ozf'
export
    getfilename:GetFilename
    findprefix:FindPrefix
define

    %%%
    % Class used to open the files, read it and close it.
    %%%
    class TextFile
        from Open.file Open.text
    end

    %%%
    % Removes the first Nth elements from a list
    %
    % Example usage:
    % In: [83 97 108 117 116] 3
    % Out: [117 116]
    %
    % @param List: a list
    % @param Nth: a positive integer representing the number of elements to remove from the beginning of the list
    % @return: a new list with the first Nth elements removed from the original list.
    %          If Nth is greater than the length of the list, an empty list is returned.
    %%%
    fun {RemoveFirstNthElements List Nth}
        case List
        of nil then nil
        [] H|T then
            if Nth == 1 then T
            else
                {RemoveFirstNthElements T Nth-1}
            end
        end
    end

    %%%
    % Checks if a list is a prefix of another list
    %
    % Example usage:
    % In1: [83 97 108 117 116] [83 97]
    % Out1: true
    % In2: [83 97 108 117 116] [97 108]
    % Out2: false
    %
    % @param List: the list to search in
    % @param List_Prefix: the prefix list
    % @return: true if 'List_Prefix' is a prefix of  'List', false otherwise
    %%%
    fun {FindPrefix List List_Prefix}
        case List_Prefix
        of nil then true
        [] H|T then
            if List == nil then false
            else
                if H == List.1 then {FindPrefix List.2 T}
                else false end
            end
        end
    end

    %%%
    % Remove a specified sublist from a given list
    %
    % Example usage:
    % In1: "Jeui ui suis okuiui et je suis louisuiuiuiui" "ui" true
    % Out1: "Jes oket je s lo"
    % In2: "    Je suis   ok  et je  suis louis    " " " false
    % Out2: "Je suis ok et je suis louis"
    %
    % @param SubList: a list from which to remove the specified sublist
    % @param Length_SubList: the sublist to remove from the 'List'
    % @param NextCharRemoveToo: boolean indicating whether to remove the next character
    %                           after the substring if it is found in the 'List'
    % @return: a new list with all instances of the specified sublist removed
    %          (and their next character too if 'removeNextChar' is set to true)
    %%%
    fun {RemovePartList List SubList NextCharRemoveToo}
        local
            Length_SubList
            fun {RemovePartList_Aux List SubList Length_SubList NextCharRemoveToo}
                case List
                of nil then nil
                [] H|T then
                    if {FindPrefix T SubList} == true then
                        if NextCharRemoveToo == true then
                            %%% Si on veut separer comme ceci : "didn't" en "didn t" et pas en "didnt", il faut faire
                            %%% H | 32 | {RemovePartList_Aux {RemoveFirstNthElements T Length_SubList+1} SubList Length_SubList NextCharRemoveToo}
                            %%% A la place de la ligne en-dessous
                            H | {RemovePartList_Aux {RemoveFirstNthElements T Length_SubList+1} SubList Length_SubList NextCharRemoveToo}
                        else
                            H | {RemovePartList_Aux {RemoveFirstNthElements T Length_SubList} SubList Length_SubList NextCharRemoveToo}
                        end
                    else
                        H | {RemovePartList_Aux T SubList Length_SubList NextCharRemoveToo}
                    end
                end
            end
        in
            Length_SubList = {Length SubList}
            if {FindPrefix List SubList} == true then
                if NextCharRemoveToo == true then
                    %%% Si on veut separer comme ceci : "didn't" en "didn t" et pas en "didnt", il faut faire
                    %%% H | 32 | {RemovePartList_Aux {RemoveFirstNthElements T Length_SubList+1} SubList Length_SubList NextCharRemoveToo}
                    %%% A la place de la ligne en-dessous
                    {RemovePartList_Aux {RemoveFirstNthElements List Length_SubList+1} SubList Length_SubList NextCharRemoveToo}
                else
                    {RemovePartList_Aux {RemoveFirstNthElements List Length_SubList} SubList Length_SubList NextCharRemoveToo}
                end
            else
                {RemovePartList_Aux List SubList Length_SubList NextCharRemoveToo}
            end
        end
    end

    %%%
    % Applies a cleaning function to a string
    %
    % Example usage:
    % If Cleaner = fun {$ LineStr} {RemovePartList LineStr [226 128] true} end
    % In1: "Jeui ui suis okuiui et je suis louisuiuiuiui" "ui" true
    % Out1: "Jes oket je s lo"
    % In2: "    Je suis   ok  et je  suis louis    " " " false
    % Out2: "Je suis ok et je suis louis"
    %
    % @param LineStr: a string to be cleaned
    % @param Cleaner: a function that takes as input a string and returns a cleaned string
    % @return: a new string that has been cleaned by the function 'Cleaner'
    %%%
    fun {CleanUp LineStr Cleaner}
        {Cleaner LineStr}
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
    fun {Reader Filename}
        fun {GetLine TextFile}
            Line = {TextFile getS($)}
        in
            if Line == false then
                {TextFile close}
                nil
            else
                local FirstCleanLine in
                    % [226 128] is a character that is not recognised by UTF-8 (the follow char too). That's why the last argument is set to true.
                    FirstCleanLine = {CleanUp Line fun {$ LineStr} {RemovePartList LineStr [226 128] true} end}
                    {FoldR {String.tokens FirstCleanLine 39} fun {$ L1 L2} {Append L1 L2} end [32]} | {GetLine TextFile}
                end
            end
        end
    in
        {GetLine {New TextFile init(name:Filename flags:[read])}}
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
        local PathName in
            PathName = {Nth List_PathName Idx}
            {Append {Append TweetsFolder_Name "/"} PathName}
        end
    end

end