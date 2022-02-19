using DelimitedFiles

function createcluefile(wordbasefile, outfilename)
    rawwords = readlines(wordbasefile)
    cryptwords = bulkcrypt(rawwords,mappings,:enc)
    writedlm(outfilename, cryptwords)
end


"""
    simplecrypt(intxt::Vector{Char}, mappings, mode=:enc) 
    simplecrypt(intxt::String, mappings, mode=:enc)

This is a TOTALLY insecure cipher easily broken. Use only for 
casually hiding data for non-secure purposes!

The first method accepts and returns a vector of chars.
The second method accepts and returns a string.

Create the mappings with prepsimplecrypt(key=Char[]). The key
is a vector of 26 chars in some random order. It returns
a named tuple with 4 mappings. Now you can see how 
bad this is: it is a substitution cipher. What was good enough
for Julias Caesar is not good enough for anyone else.
"""
function simplecrypt(intxt::Vector{Char}, mappings, mode=:enc)
    
    ret = Vector{Char}(UndefInitializer(), length(intxt))

    if mode==:enc
        ltr2num = mappings.alphaltr2num
        num2ltr = mappings.keynum2ltr
    elseif mode==:dec
        ltr2num = mappings.keyltr2num
        num2ltr = mappings.alphanum2ltr
    else
        throw(ArgumentError("mode must be :enc or :dec. Got :$mode"))
    end

    for i in eachindex(intxt)
        a = intxt[i]
        n = ltr2num[a]
        c = num2ltr[n]
        ret[i] = c
    end

    return ret
end


function simplecrypt(intxt::String, mappings, mode=:enc)
    String(simplecrypt(collect(intxt), mappings, mode))
end

function bulkcrypt(wordarray::Vector{String}, mappings, mode=:enc)
    for i in eachindex(wordarray)
        wordarray[i] = simplecrypt(wordarray[i], mappings, mode)
    end
    return wordarray
end


function prepsimplecrypt(key=Char[])

    alphabet = "abcdefghijklmnopqrstuvwxyz"

    if isempty(key)
        key = ['i', 's', 'q', 'a', 'x', 'm', 'h',
               'd', 'j', 'o', 'b', 'v', 'k', 'l',
               'e', 'u', 'c', 'f', 'n', 'p', 'w',
               'z', 'r', 't', 'y', 'g']
    end

    alphaltr2num = Dict(k=>v for (v, k) in enumerate(alphabet))
    alphanum2ltr = Dict(k=>v for (v,k) in alphaltr2num)
    keynum2ltr = Dict(k=>v for (k,v) in enumerate(key))
    keyltr2num = Dict(k=>v for (v,k) in keynum2ltr)

    mappings = (
        alphaltr2num = alphaltr2num,
        alphanum2ltr = alphanum2ltr,
        keynum2ltr = keynum2ltr,
        keyltr2num = keyltr2num    
    )
    
end

mappings = prepsimplecrypt()