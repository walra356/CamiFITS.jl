# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                          fits_objects.jl
#                      Jook Walraven 15-03-2023
# ------------------------------------------------------------------------------

# ========================== FITS_HDU Objects ==================================

"""
    FITS_HDU{T,V}

Object to hold a single "Header and Data Unit" (HDU).

The fields are
* `.filename`:  name of the corresponding FITS file (`::String`)
* `.hduindex:`:  identifier (a file may contain more than one HDU) (`:Int`)
* `.header`:  the header object where T=FITS_header (`::T`)
* `.dataobject`:  the data object where V=FITS_data (`::V`)

NB. An empty data block (`.dataobject = nothing`) conforms to the standard.
"""
struct FITS_HDU{T,V}

    filename::String
    hduindex::Int
    header::T        #FITS_header
    dataobject::V    #FITS_data

end

# ------------------------------------------------------------------------------
#                            FITS_name
# ------------------------------------------------------------------------------

# ..............................................................................
function _err_FITS_name(filnam::String)

    nl = Base.length(filnam)      # nl: length of file name including extension
    ne = Base.findlast('.', filnam)              # ne: first digit of extension

    if nl == 0
        err = 1 # filename required
    else
        if Base.isnothing(ne)
            err = 2  # filnam lacks mandatory '.fits' extension
        elseif ne == 1
            err = 3  # filnam lacks mandatory filename
        else
            strExt = Base.rstrip(filnam[ne:nl])
            strExt = Base.Unicode.lowercase(strExt)
            if strExt == ".fits"
                err = 0  # no error
            else
                err = 2  # filnam lacks mandatory '.fits' extension
            end
        end
    end

    return err

end

# ..............................................................................
@doc raw"""
    FITS_name

FITS object to hold the decomposed name of a .fits file.

The fields are:
* `     .name`:  for 'p#.fits' this is 'p#.fits' (`::String`)
* `   .prefix`:  for 'p#.fits' this is 'p' (`::String`)
* `.numerator`:  for 'p#.fits' this is '#', a serial number (e.g., '3') or a range (e.g., '3-7') (`::String`)
* `.extension`:  for 'p#.fits' this is '.fits' (`::String`)
"""
struct FITS_name

    name::String
    prefix::String
    numerator::String
    extension::String

end

# ------------------------------------------------------------------------------
#                            isvalid_FITS_name(filnam)
# ------------------------------------------------------------------------------

# ..............................................................................
@doc raw"""
    isvalid_FITS_name(filnam::String; msg=true)

Decompose the FITS filename 'filnam.fits' into its name, prefix, numerator and extension.
#### Examples:
```
julia> isvalid_FITS_name("example.fits")
true
```
"""
function isvalid_FITS_name(filnam::String; msg=true)

    err = _err_FITS_name(filnam)
    str = get(dictErrors, err, nothing)

    msg && !isnothing(str) && println("Error: " * str)

    return err > 0 ? false : true

end
function isvalid_FITS_name(; msg=true)

    return isvalid_FITS_name(""; msg)

end

"""
    cast_FITS_name(str::String)

Decompose the FITS filename 'filnam.fits' into its name, prefix, numerator and extension.
#### Examples:
```
strExample = "T23.01.fits"
f = cast_FITS_name(strExample)
FITS_name("T23.01", "T23.", "01", ".fits")

f.name, f.prefix, f.numerator, f.extension
("T23.01", "T23.", "01", ".fits")
```
"""
function cast_FITS_name(filnam::String)

    isvalid_FITS_name(filnam; msg=false) || error("Error: '$(filnam)' not a valid FITS_name")

    nl = Base.length(filnam)      # nl: length of file name including extension
    ne = Base.findlast('.', filnam)              # ne: first digit of extension

    strNam = filnam[1:ne-1]
    strExt = Base.rstrip(filnam[ne:nl])
    strExt = Base.Unicode.lowercase(strExt)

    n = ne - 1                         # n: last digit of numerator (if existent)

    if !isnothing(n)
        strNum = ""
        while Base.Unicode.isdigit(filnam[n])
            strNum = filnam[n] * strNum
            n -= 1
        end
        strPre = filnam[1:n]
    else
        strPre = strNam
        strNum = " "
    end

    return FITS_name(strNam, strPre, strNum, strExt)

end
function cast_FITS_name1(str::String)

    Base.length(Base.strip(str)) == 0 && error("FitsError: filename required")

    ne = Base.findlast('.', str)                                     # ne: first digit of extension
    nl = Base.length(str)                                           # ne: length of file name including extension

    hasextension = isnothing(ne) ? false : true

    if hasextension
        strNam = str[1:ne-1]
        strExt = Base.rstrip(str[ne:nl])
        strExt = Base.Unicode.lowercase(strExt)
        isfits = strExt == ".fits" ? true : false
        n = Base.Unicode.isdigit(str[ne-1]) ? ne - 1 : nothing        # n: last digit of numerator (if existent)
    else
        isfits = false
        n = Base.Unicode.isdigit(str[nl]) ? nl : nothing            # n: last digit of numerator (if existent)
    end

    isfits || error("FitsError: '$(str)': incorrect filename (lacks mandatory '.fits' extension)")

    if !isnothing(n)
        strNum = ""
        while Base.Unicode.isdigit(str[n])
            strNum = str[n] * strNum
            n -= 1
        end
        strPre = str[1:n]
    else
        strPre = strNam
        strNum = " "
    end

    return FITS_name(strNam, strPre, strNum, strExt)

end

# ........................................... FITS_header Object..........................................................

"""
    FITS_header

Object to hold the header information of a [`FITS_HDU`](@ref).

The fields are:
* `.hduindex`:  identifier (a file may contain more than one HDU) (`::Int`)
* `.records`:  the header formated as an array of strings of 80 ASCII characters (`::Array{String,1}`)
* `.keys`:  `keys[i]` - key corresponding to `records[i]` (record of index `i`)  (`::Array{String,1}`)
* `.values`:  `value[i]` - corresponding to `records[i]`  (`::Array{Any,1}`)
* `.comments`:  `comments[i]` - comment corresponding to `records[i]` (`::String`)
* `.dict`:  Dictionary `key[i] => value[i]` (`::Dict{String,Any}`)
* `.maps`:  Dictionary `key[i] => i` (`::Dict{String,Int}`)
"""
struct FITS_header

    hduindex::Int
    records::Array{String,1}
    keys::Array{String,1}
    values::Array{Any,1}
    comments::Array{String,1}
    dict::Dict{String,Any}
    maps::Dict{String,Int}

end

# ........................................... FITS_data Object ...................................................

"""
    FITS_data

Object to hold the data of the [`FITS_HDU`](@ref) of given `hduindex` and
`hdutype`.

The fields are:
* `.hduindex`:  identifier (a file may contain more than one HDU) (`::Int`)
* `.hdutype`:  accepted types are 'PRIMARY', 'IMAGE' and 'TABLE' (`::String`)
* `.data`:  in the from appropriate for the `hdutype` (::Any)
"""
struct FITS_data

    hduindex::Int
    hdutype::String
    data

end

# ........................................... FITS_table Object ..........................................................

"""
    FITS_table

Object to hold the data of a `TABLE HDU` (a [`FITS_HDU`](@ref) for ASCII
tables). It contains the data in the form of records (rows) of ASCII strings.

The fields are:
* `.hduindex`:  identifier (a file may contain more than one HDU) (`::Int`)
* `.rows`:  the table formated as an array of rows of ASCII strings (`::Array{String,1}`)
"""
struct FITS_table

    hduindex::Int
    rows::Array{String,1}

end