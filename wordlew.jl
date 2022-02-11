
using StatsBase
using DelimitedFiles
using InteractiveUtils
using Printf
using Dates
using JLD2

include("wordcrypt.jl")

# not quite constants for scoring letter positions within a word
wrong = 0x00
right = 0x01
inword = 0x10



#########################################################################
# game frontend
#########################################################################

function wordlew(wordfile, playerfile)

    pdict, cluewords = setup(wordfile, playerfile)

    pn = prompt_playername(pdict)  # or create a new one

    ret = startgame(pn, pdict, cluewords)

    if !isnothing(ret)
        save(playerfile, ret)
    end

end


function setup(wordfile, playerfile)
    pdict = load_playerdata(playerfile)  # TODO one day there will be too much to load all the player data ...not yet
    cluewords = loadwords(wordfile)
    return pdict, cluewords
end

function startgame(pn, pdict, cluewords)
    if isnothing(pn)  # unnamed player
        rowidx = findfirst(cluewords[:, 1] .== today())
        trueword = simplecrypt(cluewords[rowidx,3], mappings, :dec)

        print(how_to_play()) 

        play(trueword)
    else   # we've got a live one
        @assert haskey(pdict, pn) "Key for person $pn not found"
        pdata = pdict[pn]
        if !isa(pdata, Dict) # is it a dict?        
            print(how_to_play())
            worddate = today()  # worddate for new player
        else
            # haskey "lastgame"
            if haskey(pdata, "lastgame")
                worddate = Date(pdata["lastgame"].date)
            else
                worddate = today()
            end
        end
        if worddate < today()
            worddate += Day(1) # if date less than today then add 1
        end
        rowidx = findfirst(cluewords[:, 1] .== worddate)
        if isnothing(rowidx)
            worddate = cluewords[end, 1]  
        end
        playwords = cluewords[cluewords[:, 1] .== worddate, 3]

        # start playing today for 5 words   
        lastclue = 0
        for (i, trueword) in enumerate(playwords)
            play(simplecrypt(trueword, mappings, :dec))   
            lastclue = i
            if trueword != playwords[end]
                playagain = lowercase(prompt_reply("Play again? "))
            else
                playagain = "n"
            end
            if occursin('y', playagain)
                continue
            else
                # no: capture lastgame;
                break
            end
        end
        lg = (date=worddate, clue=lastclue)
        pdata["lastgame"] = lg
        return pdict

    end
end



function how_to_play()
    helpstring = """
    This is a version of the wonderful Wordle game by Josh Wardle.
    We call it Wordlew.
    
    You will be asked to enter a five letter word to guess the secret word.
    You will get 6 guesses.
    Each guess will be scored to give you clues. The score will show:
    - an upper case letter if you have the right letter in the right place
    - a lower case letter if you have a letter that is in the secret word
    - an X if you have a letter that is not in the secret word (or you guessed
    the same letter too many times)

    Here's an example of scoring the guess "boffo":
    Your guess:      b o f f o
    Result:          X o X F X
    What does the result mean? by letter number:
    1. There is no 'b'. 
    2. There is one 'o' in a different place.
    3. There is only one 'f' so the first 'f' is wrong.
    4. The second 'f' you guessed is in the right place. 
    5. There is only one 'o' so the first 'o' scored as in the secret word
    and the second 'o' is wrong. 

    """
    return helpstring
end

function intro()
    helpstring = """
    - You can play as many times in a day as you wish until you run out of
    published words.
    - You can play today's word(s) or if you missed a few days, you play words
    from several days ago.
    """
    return(helpstring)
end

function prompt_playername(pdict)
    tries = 1
    while tries < 4
        pn = lowercase(prompt_reply("Enter your player name: (..or press enter) "))
        if isempty(pn)
            pn = create_playername(pdict)
            return  pn
            break
        else
            if haskey(pdict, pn)  # check for valid player name
                println("\nWelcome ", titlecase(pn), "!")
                return pn
                break
            else
                uplines(1)
                clearline(:all)
                cursorto(1)
                print("Uh, oh--we didn't find your player name. ")
                sleep(2)

                clearline(:all)
                cursorto(1)
                tries += 1
            end
        end
    end
    donew = prompt_reply("Do you want to create a new player name? ")
    if occursin("y", lowercase(donew))
        pn = create_playername(pdict)
    end
    return pn
end
  
    
function create_playername(pdict)
    helpstring = """
    Let's create a player name. We only use your player name to 
    keep track of which word clues you've already played.

    With a player name:
    - You can guess 5 words a day 
    - You can play previous day's words (you skipped a day!?!)

    Or you can skip this and guess one word right now.
    """

    print(helpstring)

    tries = 1
    while tries < 4
        newpn = lowercase(prompt_reply("Enter your new player name: (or hit enter to skip it)> "))
        if isempty(newpn)
            println("Ok. Let's go guess one word.")
            return nothing   # make sure this triggers starting to play
        else
            if haskey(pdict, newpn)
                uplines(1)
                clearline(:all)
                cursorto(1)
                print("Uh, oh--somebody already has that player name. ")
                sleep(2)

                clearline(:all)
                cursorto(1)
                tries += 1
            else
                println("\nWelcome to Wordlew. Your player name is ", titlecase(newpn), "!")
                addnewplayer!(pdict, newpn)
                return newpn  
            end
        end
    end
    println("OK. Enough is enough. Let's go guess one word.")
    return nothing
        
end



function load_playerdata(playerfile)
    pdict = load(playerfile)
end
        
function addnewplayer!(pdict,newpn)
    pdict[newpn] = nothing
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

    print("   |.............| ")
    println()   # go down one line
    forward(19)
    while notdone
        # println()
        guess = ask_guess()
        score = score_guess(guess, trueword)
        wordscored, sharable = word_score(guess, score)
        push!(share, String(sharable))

        # this is the game display--move to another function
        uplines(1)
        show_1_result(wordscored)
        turn += 1
        if all(score .== right)
            println()
            println("You're brilliant. You guessed the word!")
            notdone = false
        elseif turn > n_guesses
            println("\n")
            println("So sorry! You didn't guess the word in $n_guesses tries.")
            println("We can't tell you the word: it's a secret.")
            notdone = false
        else
            println()
            forward(19)
        end
    end
    print("Do you want to share your outcome? (y or Y or yes...) ")
    toclipboard = chomp(readline())
    if occursin("y", lowercase(toclipboard))
        println(show_share(share))
        if Sys.islinux()
            println("Select the results and copy. Then paste somewhere.")
        else
            println("You can paste these results...")
            clipboard(show_share(share))
        end
    end
end



function ask_guess()
    not_ok = true
    while not_ok
        print("Enter a 5 letter word to guess: ")
        guess = chomp(readline())
        lg = length(guess)

        if lg > 5
            uplines(1)
            correction_msg("Oops! Your word must be five letters.")
            continue
        elseif notaword(guess, wordbase)
            uplines(1)
            correction_msg("You need to guess a real word.")
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
    print("    ")
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

# all valid 5 letter words that can be guessed
function makewordbase(wordtxtfilename="words5base.txt")
    wordbase = readdlm(wordtxtfilename, String)
    sort!(wordbase, dims=1)
    return wordbase
end

wordbase = makewordbase()

# clue words
function loadwords(wordfile)
    cluewords = readdlm(wordfile, ',', header=true)
    cluewords = cluewords[1]

    # set types by column
        # 1 is date; 2 is integer, 3 is string
        # actually sets the type of each element in a column, not the column itself
        cluewords[:, 1] .= Date.(cluewords[:, 1])
        cluewords[:, 2] .= Int.(cluewords[:, 2])
        cluewords[:, 3] .= String.(lstrip.(cluewords[:,3]))
    return cluewords
end


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

function cursorto(n)
    @printf("\e[%dG", n)
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
    play(ARGS[1])
    exit()
end