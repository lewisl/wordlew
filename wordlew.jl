# module wordlew
using StatsBase
using DelimitedFiles
using InteractiveUtils

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
    There is no 'b'; There is one 'o' in a different place; 
    There is only one 'f' so this one is wrong; 
    Because the second 'f' you guessed is in the right place; 
    There is only one 'o' so we showed the first 'o' as in the secret word
    and the second one as wrong. The one 'o' could be anywhere 
    except where the preceding correct 'f' is.

    """
    return helpstring
end


function ask_guess()
    not_ok = true
    while not_ok
        print("Enter a 5 letter word to guess: ")

        guess = chomp(readline())
        if length(guess) > 5
            println("Oops! Your word must be five letters.")
            continue
        elseif notaword(guess, wordbase)
            println("You need to guess a real word.")
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


function score_guess(guess, trueword, n=5)
    ret = zeros(UInt8, n)
    wordmap = countmap(trueword)

    for i in eachindex(guess)
        guesschar = guess[i]
        if guesschar  == trueword[i]
            ret[i] = right
            if wordmap[guesschar] == 1
                delete!(wordmap, guesschar)
            else
                wordmap[guesschar] -= 1
            end
        elseif haskey(wordmap, guesschar)
            ret[i] = inword
            if wordmap[guesschar] == 1
                delete!(wordmap, guesschar)
            else
                wordmap[guesschar] -= 1
            end
        else
            ret[i] = wrong
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

function overprint(str)  
    print("\e[2K") # clear whole line
    print("\u1b[0F")  #Moves cursor to beginning of the line n (default 1) lines up   
    print(str)   #prints the new line

    #    print("\u1b[0K") 
    # clears  part of the line.
    #If n is 0 (or missing), clear from cursor to the end of the line. 
    #If n is 1, clear from cursor to beginning of the line. 
    #If n is 2, clear entire line. 
    #Cursor position does not change. 

    # println() #prints a new line, i really don't like this arcane codes
end

#####################################################################
# using interactively
# > julia -i wordlew.jl "frame"
#
#####################################################################

if isinteractive()
    play(ARGS[1])
    exit()
end