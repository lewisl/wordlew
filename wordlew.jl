
using DelimitedFiles
using InteractiveUtils
using Printf
using Dates
using Random

include("wordcrypt.jl")

Base.@kwdef mutable struct Results
    guesses::Vector{String} = fill("", 6)
    scores::Vector{Vector{Symbol}} = [[:none for i in 1:5] for i in 1:6]
    cluesource::String=""
    cluenum::Int=0
end

#########################################################################
# new game design
#########################################################################

menus = ["  [R]andom  [C]hoose  [H]ow?  [Q]uit",
         "  [B]ack  [S]hare  [Q]uit"
        ]

function gameboard(;test = false)
    # named strings
    topborder = repeat(' ', 10) * repeat('_', 30)

    menumsg = "  Enter a menu command by first letter\n"
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

    game = Results() # struct to hold guesses and scores
    game.cluesource = splitext(basename(wordfile))[1]

    menu = 1
    while true
        menu = gamemenu!(game, cluewords, menu)
        if menu == false
            break
        end
    end

end


function gamemenu!(game, cluewords, menu=1)
    goto(3,1)
    clearline(:curs)
    print(menus[menu])
    goto_origin(4)
    still = true
    while still
        goto(4,4)
        clearline(:curs)
        # sleep(2)
        menuchoice = lowercase.(prompt_reply(""))
        if isempty(menuchoice)
            menuchoice = 'r'
        else
            menuchoice = menuchoice[1]   # incase someone accidentally typed more than 1 character
        end
        goto_origin(5); # sleep(2)
        if menuchoice == 'r'      # random
            return(dorandom!(game, cluewords))
        elseif menuchoice == 'c'   # choose
            return(dochoose!(game, cluewords))
        elseif menuchoice == 'h'  # how?
            return(dohow())
        elseif menuchoice == 'b'  # back
            return(clearboard())
        elseif menuchoice == 's'  # capture outcome to share
            return(doshare(game))
        elseif menuchoice == 'q'   # quit out of Julia back to shell
            doquit()
        elseif menuchoice == 'j'  # secret way to quit the game and stay in Julia
            return(dostop())
        else
            # sleep(2)
            domsg("Choose again!")
            continue
        end
    end
end

############################
# menu commands action
############################

function dorandom!(game, cluewords)
    cluenum = rand(1:length(cluewords))
    clue = simplecrypt(cluewords[cluenum], mappings, :dec)
    game.cluenum = cluenum

    play!(game, clue)
    menu=2
    return(menu)
end


function dochoose!(game, cluewords)
    n = length(cluewords)

    goto(6,3)

    pick = parse(Int, prompt_reply("Pick a number between 1 and $n> ")); 
    clue = simplecrypt(cluewords[pick], mappings, :dec)
    game.cluenum = pick

    goto_origin(7)

    play!(game, clue)
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
    # sleep(2) 
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
"\nGuess a 5 letter word, for example: forum" * '\n' *
"Scoring shows: " * backgr_brgreen * 'f' * backgr_bryellow * 'o' * backgr_gray * "rum" * color_reset * '\n' *
"Which means: f is in the right place, o is in the word, "  * '\n' *
"and r,u, and m are not in the word." 
)
    domsg(helpstring, 0)
    menu=1
    return menu
end

function doshare(game)
    show_share(game)
    domsg("\nOn a Mac, press shift-cmd-4 and select\n" *
          "the result squares. Then you can paste them\n" *
          "into a message.",
           0)
    menu=2
    return menu
end

function clearboard(n_guesses = 6)
    currline = 11
    goto(currline,29)
    print("SCORING"); clearline(:curs)
    for i in 1:n_guesses
        downlines(2)
        cursorto(2)
        currline += 2
        clearline(:all)
        layout = (" \u25b6" * (' '^20) * "| " )
        print(layout)
    end
    goto_origin(currline)
    menu = 1
    return menu
end



######################################################################
# game logic
######################################################################

function play!(game, trueword; n_guesses = 6)
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
        renderscored = render_result(guess, score, :score)
        game.guesses[turn] = guess
        game.scores[turn] .= score

        show_1_result(renderscored)
        turn += 1
        if all(score .== :right)
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

function show_share(game::Results)
    guesses = game.guesses
    scores = game.scores

    # show game name
    currline = 11
    goto(currline, 29)
    print(game.cluesource, " ", game.cluenum)
    goto_origin(currline)

    # show results to share
    currline = 11
    goto(currline,2)
    for i in eachindex(guesses)
        guess = guesses[i]
        score = scores[i]
        if score[1] == :none
            break
        end
        rendershare = render_result(guess, score, :share)

        downlines(2)
        currline += 2
        cursorto(27)
        print(rendershare)
    end
    goto_origin(currline)
end


function ask_guess()
    layout = ("  \u25b6" * (' '^20) * "| " * '\n' * (' '^23) * "|")
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


function render_result(guess, score, mode=:score)   # visual rendering for terminal output
    io = IOBuffer()
    if mode == :score
        for i in eachindex(score)
            if score[i] == :wrong
                print(io, wrong(guess[i]), " ")
            elseif score[i] == :inword
                print(io, inword(guess[i]), " ")
            elseif score[i] == :right
                print(io, right(guess[i]), " ")
            else
                throw(DomainError("invalid letter scoring: $(score[i])"))
            end
        end
    elseif mode == :share   # render results without showing actual letters guessed
        for i in eachindex(score)
            if score[i] == :wrong
                print(io, wrong("  "), " ")        #  rendershare[i] = '\u274c'
            elseif score[i] == :inword
                print(io, inword("  "), " ")     # '\u2714'
            elseif score[i] == :right
                print(io, right("  "), " ")  #  rendershare[i] = '\u2705'
            else
                throw(DomainError("invalid letter scoring: $(score[i])"))
            end
        end
 
    else
        throw(DomainError("mode must be :share or :score, got: $mode"))
    end
    return String(take!(io))
end


function show_1_result(renderscored)
    uplines(1)
    cursorto(27)
    print(renderscored)
    # for i in eachindex(renderscored)
    #     print(renderscored[i], "  ")
    # end
end


function score_guess(gw, tw)
    n = length(tw)
    ret = fill(:wrong, n)  # zeros(UInt8, n)
    twarr = collect(tw)

    # find every guess letter in the :inword position
    for i in eachindex(gw)  
        if twarr[i] == gw[i]
            ret[i] = :right
            twarr[i] = ';' # rule it out
        end
    end

    # find every guess letter in the word
    for i in eachindex(gw)
        match = findfirst(gw[i] .== twarr)
        if !isnothing(match)
            ret[i] = :inword
            twarr[match] = ';'  # rule it out
        end
    end

    return ret
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
# functional formatting
#####################################################################

right(c) = backgr_brgreen * c * color_reset
inword(c) = backgr_bryellow * c * color_reset
wrong(c) = backgr_gray * c * color_reset

# c_score(c, scr_c) = if scr_c == :right
#                         right(c)
#                     elseif scr_c == :inword
#                         inword(c)
#                     elseif scr_c == :wrong
#                         wrong(c)
#                     else
#                         c
#                     end


#####################################################################
# using interactively
# > julia -i wordlew.jl "frame"
#
#####################################################################

if isinteractive() & !isempty(ARGS)
    usefile = false
    if isfile(ARGS[1])
        for ln in eachline(ARGS1[1])
            if length(ln) == 5
                wordlew(ARGS[1])
            end
        end
    else
        wordlew()
    end
    exit()
end