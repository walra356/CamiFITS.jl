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
* `.filnam`:  name of the corresponding FITS file (`::String`)
* `.hduindex:`:  identifier (a file may contain more than one HDU) (`:Int`)
* `.header`:  the header object where T=FITS_header (`::T`)
* `.dataobject`:  the data object where V=FITS_data (`::V`)

NB. An empty data block (`.dataobject = nothing`) conforms to the standard.
"""
struct FITS_HDU{T,V}

    filnam::String
    hduindex::Int
    header::T        #FITS_header
    dataobject::V    #FITS_data

end

# ------------------------------------------------------------------------------
#                            FITS_name
# ------------------------------------------------------------------------------

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

function err_FITS_name(filnam::String; protect=true)

    nl = Base.length(filnam)      # nl: length of file name including extension
    ne = Base.findlast('.', filnam)              # ne: first digit of extension

    if !Base.Filesystem.isfile(filnam)
        err = 1  # file not found
    else
        if Base.isnothing(ne)
            err = 2  # filnam lacks mandatory '.fits' extension
        elseif ne == 1
            err = 3  # filnam lacks mandatory filnam
        else
            strExt = Base.rstrip(filnam[ne:nl])
            strExt = Base.Unicode.lowercase(strExt)
            if strExt ≠ ".fits"
                err = 2  # filnam lacks mandatory '.fits' extension
            else
                if protect
                    err = 4  # creation failed (filnam in use 
                else  # set ';protect=false' to overrule overwrite protection)
                    err = 0  # no error
                end
            end
        end
    end

    return err

end

@doc raw"""
    isvalid_FITS_name(filnam::String; msg=true)::Bool

Validity test of fits filnam.
#### Examples:
```
julia> isvalid_FITS_name("example.fits")
true

julia> isvalid_FITS_name("example")
Error: filnam lacks mandatory '.fits' extension
false
```
"""
function isvalid_FITS_name(filnam::String; msg=true)

    err = err_FITS_name(filnam)
    str = get(dictErrors, err, nothing)

    msg && !isnothing(str) && error("Error $(err): " * str)

    return err > 0 ? false : true

end

# ------------------------------------------------------------------------------
#                            cast_FITS_name(filnam)
# ------------------------------------------------------------------------------

# ..............................................................................
"""
    cast_FITS_name(str::String)

Decompose the FITS filnam 'filnam.fits' into its name, prefix, numerator and extension.
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

    isvalid_FITS_name(filnam) || error("Error: '$(filnam)' not a valid FITS_name")
    #isvalid_FITS_name(filnam; msg=false) || error("Error: '$(filnam)' not a valid FITS_name")

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

# ........................................... cast records into a FITS_header object .................................

function _cast_header(records::Array{String,1}, hduindex::Int)

    records = _rm_blanks(records)         # remove blank records to collect header records data (key, val, comment)
    nrec = length(records)                # number of keys in header with given hduindex

    keys = [Base.strip(records[i][1:8]) for i = 1:nrec]
    vals = [records[i][9:10] ≠ "= " ? records[i][11:31] : _fits_parse(records[i][11:31]) for i = 1:nrec]
    coms = [records[i][34:80] for i = 1:nrec]
    dict = [keys[i] => vals[i] for i = 1:nrec]
    maps = [keys[i] => i for i = 1:nrec]

    return FITS_header(hduindex, records, keys, vals, coms, Dict(dict), Dict(maps))

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