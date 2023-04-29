functor 
export
    InsertText_Window 
    SetText_Window
define

    %%%
    % Inserts a text into the tk window.
    %
    % @param Location_Text: the location where inserts the text (InputText or OutputText)
    % @param Row: a positive number representing the row where to inserts the text
    % @param Col: a positive number representing the column where to inserts the text
    % @param Special_Location: = 'end' or none if no special location
    % @param Text: the text to inserts
    % @return: /
    %%%
    proc {InsertText_Window Location_Text Row Col Special_Location Text}
        if Special_Location == none then
            {Location_Text tk(insert p(Row Col) Text)}
        else
            {Location_Text tk(insert Special_Location Text)}
        end
    end


    %%%
    % Set a text into the tk window (and delete all before).
    %
    % @param Location_Text: the location where set the text (InputText or OutputText)
    % @param Text: the text to sets
    % @return: /
    %%%
    proc {SetText_Window Location_Text Text}
        {Location_Text set(Text)}
    end

end