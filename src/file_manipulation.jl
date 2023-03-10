
"""
    decompose_filnam(str)

Decompose filename into its name (and, if present, extension, prefix and numerator).
#### Examples:
```
strExample = "T23.01.fits"

dict = decompose_filnam(strExample)
Dict{String,String} with 4 entries:
  "Extension" => ".fits"
  "Numerator" => "01"
  "Prefix"    => "T23."
  "Name"      => "T23.01"

get(dict,"Numerator","Numerator: Key absent")
"01"

get(dict,"Wild","Key absent")
"Key absent"
```
"""
function decompose_filnam(str::String)

    ne = Base.findlast('.',str)                # ne: first digit of extension
    nl = length(str)                           # ne: length of file name including extension
    isnothing(ne) ? extension = false : extension = true

    if extension
        strNam = str[1:ne-1]
        strExt = str[ne:nl]
        Base.Unicode.isdigit(str[ne-1]) ? n = ne-1 : n = nothing
        o = [("Name", strNam), ("Extension", strExt)]
    else
        strNam = str[1:ne-1]
        strExt = nothing
        Base.Unicode.isdigit(str[nl]) ? n = nl : n = nothing
        o = [("Name", strNam)]
    end

    if !isnothing(n)
        strNum = ""
        while Base.Unicode.isdigit(str[n])
            strNum = str[n] * strNum
            n -= 1
        end
        strPre = str[1:n]
        Base.append!(o,[("Prefix", strPre),("Numerator", strNum)])
    end

    return Dict(o)

end

"""
    fits_combine(str1, str2 [; info=false])

Combine a series of .fits files into a single .fits file.
#### Example:
```
fits_combine("T01.fits", "T22.fits"; info=false)
T01-T22.FITS: file was created (for more information set info=true)
```
"""
function fits_combine(filnamFirst::String, filnamLast::String; info=false)

    _file_exists(filnamFirst) || return "$filnamFirst: file not found"
    _file_exists(filnamLast) || return "$filnamLast: file not found"

    filnamFirst = uppercase(filnamFirst)
    filnamLast = uppercase(filnamLast)

    d = decompose_filnam(filnamFirst)
    strPre = get(d,"Prefix","Error: no prefix")
    strNum = get(d,"Numerator","Error: no Numerator")
    strExt = get(d,"Extension","Error: no extension")
    valNum = parse(Int,strNum )
    numLeadingZeros = length(strNum) - length(string(valNum))

    d = decompose_filnam(filnamLast)
    strPre2 = get(d,"Prefix","Error: no prefix")
    strNum2 = get(d,"Numerator","Error: no Numerator")
    strExt2 = get(d,"Extension","Error: no extension")
    valNum2 = parse(Int,strNum2 )
    numLeadingZeros2 = length(strNum2) - length(string(valNum2))

    if strPre ≠ strPre2
        error(strPre * " ≠ " * strPre2 * " (prefixes must be identical)")
    elseif strExt ≠ strExt2
        error(strExt * " ≠ " * strExt2 * " (file extensions must be identical)")
    elseif strExt ≠ ".FITS"
        error("file extension must be '.fits'")
    end

    numFiles = 1 + valNum2 - valNum
    fileFirst = FITSIO.FITS(filnamFirst)
    metaInfo = FITSIO.read_header(fileFirst[1])
    dataFirst = Base.read(fileFirst[1])  # read an image from disk
    Base.close(fileFirst)
    t = typeof(dataFirst[1,1,1])
    s = size(dataFirst)
    dataStack =  Array{t,3}(undef, s[1], s[2] , numFiles)

    itr = valNum:valNum2
    filnamNext = filnamFirst
    for i ∈ itr
        l = length(filnamNext)
        filnamNext = strPre * "0"^numLeadingZeros * string(i) * ".fits"
        if l < length(filnamNext)
            numLeadingZeros = numLeadingZeros -1
            filnamNext = strPre * "0"^numLeadingZeros * string(i) * ".fits"
        end
        fileNext = FITS(filnamNext)
        dataNext = Base.read(fileNext[1])  # read an image from disk
        Base.close(fileNext)
        dataStack[:, :,i] = dataNext[:, :,1]
    end

    filnamOut = strPre * strNum * "-" * strPre * strNum2 * strExt
    fileOut = FITSIO.FITS(filnamOut,"w")
    Base.write(fileOut, dataStack) # was incorrect: Base.write(fileOut, dataStack; header=metaInfo)
    if info
        println("Output fileOut:\r\n", fileOut)
        println("\r\nOutput fileOut[1]:\r\n", fileOut[1])
        Base.close(fileOut)
        println("\r\nmetaInformation:\r\n", metaInfo)
    else
        Base.close(fileOut)
        return filnamOut * ": file was created (for more information set info=true)"
    end
end
