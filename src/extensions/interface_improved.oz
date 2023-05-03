functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
    OS
    System
    
    Variables at '../variables.ozf'
    Historic_user at 'historic_user.ozf'
export
    GetDescriptionGUI
    SaveText_UserFinder
    LoadText
define

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% ====== THIRD EXTENSION ====== %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%% ============= IMPROVE GUI  ============= %%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fun {GetDescriptionGUI CallerPress}
        lr( title: "TwitOZ"
            background:c(27 157 240)
            td( text(handle:Variables.inputText height:15 font:{QTk.newFont font(family:"Verdana")} background:white foreground:black insertbackground:black selectbackground:c(13 101 212) wrap:word)
                text(handle:Variables.outputText height:15 font:{QTk.newFont font(family:"Verdana")} background:black foreground:white wrap:word)
                )
            td( %label(image:{QTk.newImage photo(url:"./twit.png")} borderwidth:0 width:290)
                td( button(text:"Predict" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:CallerPress)
                    button(text:"Save as .txt file" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:SaveText_UserFinder)
                    button(text:"Save file in database" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:Historic_user.saveText_Database)
                    button(text:"Clean user historic" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:Historic_user.clean_UserHistoric)
                    button(text:"Load file as input" height:2 width:20 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:LoadText)
                    button(text:"Quit" height:2 width:20 background:c(29 125 242) relief:sunken borderwidth:1 font:{QTk.newFont font(family:"Verdana" size:13)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:proc{$} {Application.exit 0} end)
                    )
                )
            action:proc{$} {Application.exit 0} end
            )
    end


    %%%
    % Saves an input text from the app window as a text file on the user's computer.
    %
    % @param: /
    % @return: /
    %%%
    proc {SaveText_UserFinder}
        Name = {QTk.dialogbox save( defaultextension:"txt"
                                    filetypes:q(q("Txt files" q(".txt")) q("All files" q("*"))) $)}
    in 
        try 
            User_File = {New Open.file init(name:Name flags:[write create truncate])}
            Contents = {Variables.inputText get($)}
        in 
            {User_File write(vs:Contents)}
            {User_File close}
        catch _ then {System.show 'Error when saving the file into the user specified file'} {Application.exit} end 
    end


    %%%
    % Loads a text file in the input section in the app window.
    %
    % @param: /
    % @return: /
    %%%
    proc {LoadText}
        Name = {QTk.dialogbox load(defaultextension:"txt"
                                   filetypes:q(q("Txt files" q(".txt")) q("All files" q("*"))) $)}
        Contents = {Variables.inputText get($)}
    in 
        try
            File = {New Open.file init(name:Name)}
            Contents = {File read(list:$ size:all)}
        in 
            {Variables.inputText set(Contents)}
            {File close}
        catch _ then {System.show 'Error when loading the file into the window'} {Application.exit} end 
    end
end