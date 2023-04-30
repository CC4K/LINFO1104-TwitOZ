functor
import
    Function at 'function.ozf'
    Interface at 'interface.ozf'
export
    ProposeAllTheWords
define

    proc {ProposeAllTheWords List_MostProbableWords Frequency Probability LocationText}
        local
            proc {ProposeAllTheWords_Aux List_MostProbableWords LastPos}
                case List_MostProbableWords
                of nil then {Interface.insertText_Window LocationText 1 LastPos none " ]\n"}
                [] H|T then
                    {Interface.insertText_Window LocationText 1 LastPos none 32|{Atom.toString H}}
                    {ProposeAllTheWords_Aux T LastPos+1+{Length {Atom.toString H}}}
                end
            end
        in
            {Interface.setText_Window LocationText "The most probable word(s) : ["}
            {ProposeAllTheWords_Aux List_MostProbableWords 30}
            {DisplayFreq_And_Probability LocationText 2 Frequency Probability}
        end
    end

    proc {DisplayFreq_And_Probability LocationText Row Frequency Probability}
        local Str_Frequency Str_Probability in

            if {Float.is Frequency} == true then
                Str_Frequency = {Float.toString Frequency}
            else
                Str_Frequency = {Int.toString Frequency}
            end

            if {Float.is Probability} == true then
                Str_Probability = {Float.toString Probability}
            else
                Str_Probability = {Int.toString Probability}
            end

            {Interface.insertText_Window LocationText Row 0 none {Append "The frequency of the/these word(s) is : " {Append Str_Frequency "\n"}}}
            {Interface.insertText_Window LocationText Row+1 0 none {Append "The probability of the/these word(s) is : " Str_Probability}}
        end
    end

end