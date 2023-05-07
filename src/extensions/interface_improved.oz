functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
    System
    
    Variables at '../variables.ozf'
    Historic_user at 'historic_user.ozf'
    Correction_prediction at 'correction_prediction.ozf'
export
    GetDescriptionGUI % Creates the GUI's description of the app.
define
    

    %%%
    % Creates the GUI's description of the app.
    %
    % @param: CallerPress: the function to call when the button "Predict" is pressed.
    % @return: the GUI's description.
    %%%
    fun {GetDescriptionGUI CallerPress} 

        local State_Correction State_Database State_Predict in

            if Variables.auto_Prediction == 1 then State_Predict = disabled
            else State_Predict = normal end

            if Variables.files_Database == 1 then State_Database = normal
            else State_Database = disabled end

            if Variables.correction_Words == 1 then State_Correction = normal
            else State_Correction = disabled end

            lr( title: "TwitOZ"
                background:c(27 157 240)
                td( label(width:2 background:c(27 157 240)))
                td( label(height:1 background:c(27 157 240) glue:we)%width:83
                    text(handle:Variables.inputText width:70 height:18 font:{QTk.newFont font(family:"Verdana" size:12)} background:c(52 53 65) foreground:white insertbackground:white selectbackground:c(13 101 212) wrap:word)
                    text(handle:Variables.outputText width:70 height:10 font:{QTk.newFont font(family:"Verdana" size:12)} background:c(68 70 84) foreground:white insertbackground:white selectbackground:c(13 101 212) wrap:word relief:sunken)
                    label(height:1 background:c(27 157 240) glue:we)
                    )
                td( label(width:2 background:c(27 157 240)))
                td( label(height:1 background:c(27 157 240) glue:we)
                    label(image:{QTk.newImage photo(url:"image/TwitOZ_logo.png")} borderwidth:0 glue:we)
                    td( button(text:"Predict" state:State_Predict height:2 width:24 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Arial" size:13 weight:bold)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:CallerPress)
                        lr( text(handle:Variables.correctText height:1 width:16 font:{QTk.newFont font(family:"Verdana" size:12)} background:c(52 53 65) foreground:white insertbackground:white selectbackground:c(13 101 212) wrap:none ipady:10 padx:2)
                            button(text:"Correct\na word" state:State_Correction height:2 width:8 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Arial" size:10)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:proc {$} {Send Variables.port_Auto_Corr_Threads 5000} {Correction_prediction.correctionSentences} end)
                            background:c(27 157 240)
                            glue:we
                            )
                        button(text:"Load file from computer" state:State_Database height:2 width:24 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Arial" size:13 weight:bold)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:LoadText)
                        button(text:"Save on computer" state:State_Database height:2 width:24 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Arial" size:13 weight:bold)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:SaveText_UserFinder)
                        button(text:"Load file into database" state:State_Database height:2 width:24 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Arial" size:13 weight:bold)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:Historic_user.saveFile_Database)
                        button(text:"Save in database" state:State_Database height:2 width:24 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Arial" size:13 weight:bold)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:Historic_user.saveText_Database)
                        button(text:"Clean history" state:State_Database height:2 width:24 background:c(29 125 242) borderwidth:1 font:{QTk.newFont font(family:"Arial" size:13 weight:bold)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:Historic_user.clean_UserHistoric)
                        button(text:"Quit" height:2 width:24 background:c(29 125 242) relief:sunken borderwidth:1 font:{QTk.newFont font(family:"Arial" size:13 weight:bold)} foreground:white activebackground:white activeforeground:black cursor:hand2 action:proc{$} {Application.exit 0} end)
                        )
                    label(height:1 background:c(27 157 240) glue:wen)
                    )
                td( label(width:2 background:c(27 157 240)))
                action:proc{$} {Application.exit 0} end
                )
        end
    end


    %%%
    % Saves an input text from the app window as a text file on the user's computer.
    % 
    % @param: /
    % @return: /
    %%%
    proc {SaveText_UserFinder}
        try
            local Name User_File Contents in
                Name = {QTk.dialogbox save( defaultextension:"txt"
                                            filetypes:q(q("Txt files" q(".txt")) q("All files" q("*"))) $)}
                if Name == nil then skip
                else
                    User_File = {New Open.file init(name:Name flags:[write create truncate])}
                    Contents = {Variables.inputText get($)}
                    {User_File write(vs:Contents)}
                    {User_File close}
                end
            end
        catch _ then {System.show 'Error when saving the file into the user specified file'} {Application.exit 0} end 
    end


    %%%
    % Loads a text file in the input section in the app window.
    %
    % @param: /
    % @return: /
    %%%
    proc {LoadText}
        try
            local Name File Contents in
                Name = {QTk.dialogbox load(defaultextension:"txt"
                                    filetypes:q(q("Txt files" q(".txt")) q("All files" q("*"))) $)}
                if Name == nil then skip
                else
                    File = {New Open.file init(name:Name)}
                    Contents = {File read(list:$ size:all)}
                    {Variables.inputText set(Contents)}
                    {File close}
                end
            end
        catch _ then {System.show 'Error when loading the file into the window'} {Application.exit 0} end 
    end

end