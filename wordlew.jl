
using StatsBase
using DelimitedFiles
using InteractiveUtils
using Printf
using Dates
using JLD2
using Random

include("wordcrypt.jl")

# not quite constants for scoring letter positions within a word
wrong = 0x00
right = 0x01
inword = 0x10

#########################################################################
# new game design
#########################################################################

menus = ["  [R]andom  [C]hoose  [H]ow?  [Q]uit",
         "  [B]ack  [S]hare  [Q]uit"
        ]

function gameboard(;test = false)
    # named strings
    topborder = repeat(' ', 10) * repeat('_', 30)

    menumsg = "  Enter a menu command by first letter (press enter for R)\n"
    menuprompt = "  " * solid_arrow
    gamename = "World of Wordlew"

    panelheaders = (' '^10) * "GUESSES" *  (' '^11) * "SCORING\n"

    paneldivider = ("  \u25b6" * (' '^20) * "| " * '\n' *
                    (' '^23) * "|" * '\n'  )
    botborder = repeat('_', 50)  # repeat(' ', 10) * 

    # show it
    line = 0
    Base.run(`clear`)

    showgamename(gamename);         line += 1
    print(menumsg);                 line += 1
    # print(menus[1]);                line += 1
    println();                      line += 1
    println(menuprompt);            line += 1
    println('\n'^5);                line += 5
    println(panelheaders);          line += 1
    for i in 1:6
        print(paneldivider);        line += 2
    end                             
    print(botborder);               line += 1

    uplines(line + 1)  # set cursor to top of game board
    cursorto(1)        # first character

    if test
        print("lines = ", line)
        downlines(line + 2)
    end
end

function showgamename(gamename)
    for i in eachindex(gamename)
        ch = mod(i,3)
        if ch == 1
            print(backgr_gray)
        elseif ch == 2
            print(backgr_bryellow)
        elseif ch == 0
            print(backgr_brgreen)
        end
        print(" ", gamename[i], " ")
    end
    println(color_reset)
end

#########################################################################
# game frontend
#########################################################################

function wordlew(wordfile="cluewords.txt")

    cluewords = loadclues(wordfile)

    gameboard()

    menu = 1
    while true
        menu = gamemenu(cluewords, menu)
        if menu == false
            break
        end
    end

end


function gamemenu(cluewords, menu=1)
    goto(3,1)
    clearline(:curs)
    print(menus[menu])
    goto_origin(4)
    still = true
    while still
        goto(4,4)
        clearline(:curs)
        sleep(2)
        menuchoice = lowercase.(prompt_reply(""))
        if isempty(menuchoice)
            # print("got here")
            menuchoice = 'r'
        else
            menuchoice = menuchoice[1]
            # print("got here, choice = ", menuchoice, " ", typeof(menuchoice))
        end
        goto_origin(5); sleep(2)
        if menuchoice == 'r'
            # goto_origin(5)
            return(dorandom(cluewords))
        elseif menuchoice == 'c'
            # goto_origin(5)
            return(dochoose(cluewords))
        elseif menuchoice == 'h'
            # goto_origin(5)
            return(dohow())
        elseif menuchoice == 'b'
            menu = 1
            clearboard()
            return(menu)
        elseif menuchoice == 'q'
            # goto_origin(5)
            doquit()
        elseif menuchoice == 'j'  # secret way to quit the game and stay in Julia
            return(dostop())
        else
            sleep(2)
            domsg("Choose again!")
            continue
        end
    end
end

############################
# menu commands action
############################

function dorandom(cluewords)
    #=
        get a word

        display the word number
        play with that word
    =#
    clue = simplecrypt(cluewords[rand(1:length(cluewords))], mappings, :dec)
    domsg(" Your word is $clue")
    play(clue)
    menu=2
    return(menu)
end


function dochoose(cluewords)
    n = length(cluewords)

    goto(6,3)

    pick = parse(Int, prompt_reply("Pick a number between 1 and $n> ")); 
    clue = simplecrypt(cluewords[pick], mappings, :dec)

    goto_origin(7)

    play(clue)
    menu = 2
    return(menu)
end


function domsg(msg, wait=2; fromorigin=true)
    nlines = count('\n', msg) + 1
    @assert nlines < 6 "message is too many lines"
    if fromorigin
        goto(5,1)
    end
    for (i,l) in enumerate(split(msg, '\n'))
        print("  ", l)
        if i <= nlines - 1
            print("\n")
        end
    end

    # clear message
    if wait == 0
        print( "  <enter> to continue"); chomp(readline())
        nlines += 1
    else
        sleep(wait)
    end
    for i in 1:nlines
        clearline(:all)
        uplines(1)
    end
    goto_origin(5 + nlines + 1)
    sleep(2) 
end

function doquit()
    domsg("\nBye, bye!")
    exit()
end

function dostop()
    domsg("\nBye, bye!")
    Base.run(`clear`)
    false
end

function dohow()
    helpstring = (
"Guess a 5 letter word, for example: forum" * '\n' *
"Scoring shows: " * backgr_brgreen * 'f' * backgr_bryellow * 'o' * backgr_gray * "rum" * color_reset * '\n' *
"Which means: f is in the right place, o is in the word, "  * '\n' *
"and r,u, and m are not in the word." 
)
    domsg(helpstring, 0)
    menu=1
    return menu
end

function doshare()
    println(show_share(share))
    if Sys.islinux()
        println("Select the results and copy. Then paste somewhere.")
    else
        println("You can paste these results...")
        clipboard(show_share(share))
    end
end

function clearboard(n_guesses = 6)
    currline = 11
    goto(currline,3)
    for i in 1:n_guesses
        downlines(2)
        cursorto(2)
        currline += 2
        clearline(:all)
        layout = (" \u25b6" * (' '^20) * "| " )
        print(layout)
    end
    goto_origin(currline)
end


function correction_msg(txt)
    # display the message in place
    uplines(1)          
    cursorto(20)
    print(txt)
    clearline(:curs)    
    sleep(2)

    # clear the message and set the cursor for the input prompt
    cursorto(20)           
    clearline(:curs)    
end


######################################################################
# game logic
######################################################################

function play(trueword; n_guesses = 6)
    @assert length(trueword) == 5 "Word to guess must be 5 letters"
    notdone = true
    turn = 1
    share = Vector{String}()

    # print(how_to_play())
    goto(11,5)
    currline = 11
    while notdone
        downlines(2)
        cursorto(5)
        currline += 2
        guess = ask_guess()
        score = score_guess(guess, trueword)
        wordscored, sharable = word_score(guess, score)
        push!(share, String(sharable))

        # this is the game display--move to another function
        show_1_result(wordscored)
        turn += 1
        if all(score .== right)
            goto_origin(currline)
            domsg("\nYou're brilliant. You guessed the word!")
            notdone = false
        elseif turn > n_guesses
            goto_origin(currline)
            domsg("\nYou didn't guess the word in $n_guesses tries.")
            notdone = false
        end
    end

end



function ask_guess()
    layout = ("  \u25b6" * (' '^20) * "| " * '\n' *
                    (' '^23) * "|")
    not_ok = true
    while not_ok
        guess = chomp(readline())
        lg = length(guess)

        if lg > 5
            uplines(1)
            cursorto(27)
            print("Must be 5 letters")
            sleep(2)
            cursorto(1)
            clearline(:all)
            print(layout)
            uplines(1)
            cursorto(5)
            continue
        elseif notaword(guess, wordbase)
            uplines(1)
            cursorto(27)
            print("Guess a real word.")
            sleep(2)
            cursorto(1)
            clearline(:all)
            print(layout)
            uplines(1)
            cursorto(5)
            continue
        else
            not_ok = false
        end
    end
    guess = lowercase(guess)
    return guess
end


function word_score(guess, score)
    ret = similar(collect(guess))
    sharable = copy(ret)  # shows accuracy without revealing correct letters
    for i in eachindex(score)
        if score[i] == wrong
            ret[i] = 'X'
            sharable[i] = '\u274c'
        elseif score[i] == inword
            ret[i] = lowercase(guess[i])
            sharable[i] = '\u2714'
        else
            ret[i] = uppercase(guess[i])
            sharable[i] = '\u2705'
        end
    end
    return ret, sharable
end


function show_1_result(wordscored)
    uplines(1)
    cursorto(27)
    for i in eachindex(wordscored)
        print(wordscored[i], "  ")
    end
end

# alternative to score_guess that works (is correct)
    # same performance. different order for inword scores
function score2(gw, tw)
    unscored = Set(1:5)
    unused = Set(1:5)
    ret = fill(wrong, 5)

    # exact matches
    for i in 1:5
        if gw[i] == tw[i]
            ret[i] = right
            delete!(unscored, i)
            delete!(unused, i)
        end
    end

    # in the word
    for gwi in unscored
        for twi in unused
            if gw[gwi] == tw[twi]
                ret[gwi] = inword
                delete!(unused, twi)
                break
            end
        end
    end
    return ret
end


function score_guess(gw, tw)
    n = length(tw)
    ret = fill(wrong, n)  # zeros(UInt8, n)
    twarr = collect(tw)

    # find every guess letter in the right position
    for i in eachindex(gw)  
        if twarr[i] == gw[i]
            ret[i] = right
            twarr[i] = ';' # rule it out
        end
    end

    # find every guess letter in the word
    for i in eachindex(gw)
        match = findfirst(gw[i] .== twarr)
        if !isnothing(match)
            ret[i] = inword
            twarr[match] = ';'  # rule it out
        end
    end

    return ret
end


function show_share(share::Vector{String})

    io = IOBuffer()  # collect output pieces

    for str in share
        for c in str
            if c == '\u2714'
                print(io, "|  ", c, " ")
            else
                print(io, "| ",c, " ")
            end
        end
        print(io, "| \n") # new line
    end
    return String(take!(io))
end


function notaword(guess, wordbase)
    !in(guess, wordbase)
end

############################################################
# processing words
############################################################

function loadclues(cluefile)
    clues = readlines(cluefile)
end

# all valid 5 letter words that can be guessed
function makewordbase(wordtxtfilename="words5base.txt")
    wordbase = readdlm(wordtxtfilename, String)
    sort!(wordbase, dims=1)
    return wordbase
end

wordbase = makewordbase()




#####################################################################
# helper functions
#####################################################################

function prompt_reply(msg)
    print(msg)
    chomp(readline())
end

#####################################################################
# terminal movement based on ANSI terminal codes
#####################################################################

function uplines(n)
    @printf("\e[%dA", n)
end

function downlines(n)
    @printf("\e[%dB", n)
end

function forward(n)
    @printf("\e[%dC", n)
end

function back(n)
    @printf("\e[%dD", n)
end

function cursorto(n)  # within current line
    @printf("\e[%dG", n)
end

function goto(line, pos)  # line and position
    # assumes always starting at origin [1,1]
    downlines(line - 1)
    cursorto(pos)
end

function goto_origin(fromline)
    uplines(fromline - 1)
    cursorto(1)
end

function clearline(pos::Symbol)
    n = if pos == :curs   # cursor to end of line
            0
        elseif pos == :all
            2
        elseif pos == :beg  # beginning of line to cursor
            1
        else
            throw(DomainError(repr(pos), "Position must be :curs, :all, or :beg"))
        end
    clearline(n)
end

function clearline(n::Int)
    @printf("\e[%dK", n)
end

#####################################################################
#  terminal colors, from https://en.wikipedia.org/wiki/ANSI_escape_code#Control_characters
#####################################################################


# foreground colors
#ESC[38;5;⟨n⟩m
foregr_white = "\e[38;5;15m"

# background colors
#ESC[48;5;(n)m
backgr_gray = "\e[48;5;251m"
backgr_bryellow = "\e[48;5;227m"
backgr_brgreen = "\e[48;5;119m"

color_reset = "\e[0m"

####################################################################
# special characters
####################################################################
hollow_arrow = '\u25b7'  # ▷
solid_arrow = '\u25b6'   # ▶


#####################################################################
# using interactively
# > julia -i wordlew.jl "frame"
#
#####################################################################

if isinteractive() & !isempty(ARGS)
    wordlew()
    exit()
end