# module wordlew
using StatsBase
using DelimitedFiles
using InteractiveUtils
using Printf

include("wordcrypt.jl")

wrong = 0x00
right = 0x01
inword = 0x10

function wordlew(wordfile)
    truewords = readdlm(wordfile)
end

function play(trueword; n_guesses = 6)
    notdone = true
    turn = 1
    share = Vector{String}()

    print(how_to_play())

    print("   |.............| ")
    while notdone
        guess = ask_guess()
        score = score_guess(guess, trueword)
        wordscored, sharable = word_score(guess, score)
        push!(share, String(sharable))

        # this is the game display--move to another function
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

function how_to_play()
    helpstring = """
    You will be asked to enter a five letter word to guess the secret word.
    You will get 6 guesses.
    Each guess will be scored to give you clues. The score will show:
    - an upper case letter if you have the right letter in the right place
    - a lower case letter if you have a letter that is in the secret word
    - an X if you have a letter that is not in the secret word (or you guessed
    the same letter too many times)

    Here's an example of scoring the guess "boffo":
    Your guess:      b o f f o
    Score:           X o X F X
    There is no 'b'. There is one 'o' in a different place.
    There is only one 'f' so the first 'f' is wrong.
    The second 'f' you guessed is in the right place; 
    There is only one 'o' so the first 'o' scored as in the secret word
    and the second 'o' is wrong. The one 'o' could be anywhere 
    except where the preceding correct 'f' is.

    """
    return helpstring
end


function ask_guess()
    not_ok = true
    while not_ok
        print("Enter a 5 letter word to guess: ")
        guess = chomp(readline())
        lg = length(guess)

        if lg > 5
            correction_msg("Oops! Your word must be five letters.")
            continue
        elseif notaword(guess, wordbase)
            correction_msg("You need to guess a real word.")
            continue
        else
            not_ok = false
        end
    end
    guess = lowercase(guess)
    return guess
end


function correction_msg(txt)
    uplines(1)          
    cursorto(20)
    print(txt)
    clearline(:curs)    
    sleep(2)
    cursorto(20)           
    clearline(:curs)    
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


function makewordbase(wordtxtfilename="words5base.txt")
    wordbase = readdlm(wordtxtfilename, String)
    sort!(wordbase, dims=1)
    return wordbase
end

wordbase = makewordbase()

#####################################################################
# terminal movement based on ANSI terminal codes
#####################################################################

function uplines(n=1)
    @printf("\e[%dA", n)
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
    n = if pos == :curs
            0
        elseif pos == :all
            2
        elseif pos == :beg
            1
        else
            throw(DomainError("Position must be :curs, :all, or :beg"))
        end
    clearline(n)
end

function clearline(n::Int)
    @printf("\e[%dK", n)
end

#####################################################################
# using interactively
# > julia -i wordlew.jl "frame"
#
#####################################################################

if isinteractive() & !isempty(ARGS)
    play(ARGS[1])
    exit()
end