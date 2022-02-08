
"""
    simplecrypt(intxt::Vector{Char}, mappings, mode=:enc) 
    simplecrypt(intxt::String, mappings, mode=:enc)

This is a TOTALLY insecure cipher easily broken. Use only for 
casually hiding data for non-secure purposes!

The first method accepts and returns a vector of chars.
The second method accepts and returns a string.
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