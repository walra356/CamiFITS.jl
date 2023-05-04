# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                          fits_objects.jl
#                      Jook Walraven 15-03-2023
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                               FITS_data
# ------------------------------------------------------------------------------

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

    hdutype::String
    data

end

# ------------------------------------------------------------------------------
#                    cast_FITS_data(hduindex, hdutype, data)
# ------------------------------------------------------------------------------

@doc raw"""
    cast_FITS_data(hduindex::Int, hdutype::String, data)

Creates the [`FITS_data`](@ref) object for given `hduindex` constructed from 
the `data` in accordance to the specified `hdutype` (`PRIMARY_HDU`, 
`IMAGE_HDU`, `TABLE_HDU` and `BINARY_HDU`)
#### Example:
```
julia> record = [rpad("r$i",8) * ''' * rpad("$i",70) * ''' for i=1:36];

julia> h = cast_FITS_header(record);

julia> data = [11,21,31,12,22,23,13,23,33];

julia> data = reshape(data,(3,3,1));

julia> d = dataobject = cast_FITS_data("IMAGE", data)
FITS_data("IMAGE", [11 12 13; 21 22 23; 31 23 33;;;])

julia> d.data
3×3×1 Array{Int64, 3}:
[:, :, 1] =
 11  12  13
 21  22  23
 31  23  33

julia> d.hdutype
"IMAGE"
```
"""
function cast_FITS_data(hdutype::String, data)

    return FITS_data(hdutype, data)

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

# ------------------------------------------------------------------------------
#                               FITS_card
# ------------------------------------------------------------------------------

@doc raw"""
    FITS_card

Object to hold the card information of the [`FITS_header`](@ref) object.

The fields are:
* `.cardindex`:  identifier of the header record (`::Int`)
* `.record`:  the full record on the card (`::String`)
* `.keyword`:  name of the corresponding header record (`::String`)
* `.val`:  value  of the corresponding header record (`::Any`)
* `.comment`:  comment on the corresponding header record (`::String`)
"""
struct FITS_card

    cardindex::Int
    record::String
    keyword::String
    value::Any
    comment::String

end

# ------------------------------------------------------------------------------
#                     cast_FITS_card(cardindex, record)
# ------------------------------------------------------------------------------

@doc raw"""
    cast_FITS_card(cardindex::Int, record::String)

Creates the [`FITS_card`](@ref) object for `record` with index `cardindex`.
#### Example:
```
julia> record = "SIMPLE  =                    T / file does conform to FITS standard             ";

julia> card = cast_FITS_card(1, record);

julia> (card.keyword, card.value, card.comment)
("SIMPLE", true, "file does conform to FITS standard             ")
```
"""
function cast_FITS_card(cardindex::Int, record::String)

    key = Base.strip(record[1:8])
    val = record[9:10] ≠ "= " ? record[11:31] : _fits_parse(record[11:31])
    com = record[34:80]

    return FITS_card(cardindex, record, key, val, com)

end

# ------------------------------------------------------------------------------
#                                FITS_header
# ------------------------------------------------------------------------------

@doc raw"""
    FITS_header

Object to hold the header information of a [`FITS_HDU`](@ref).

The fields are:
* `.card`: the array of `cards` (`::Vector{FITS_card}`)
* `.map`:  Dictionary `keyword => recordindex` (`::Dict{String, Int}`)
"""
struct FITS_header

    card::Vector{FITS_card}
    map::Dict{String,Int}

end

# ------------------------------------------------------------------------------
#                    cast_FITS_header(record::Vector{String})
# ------------------------------------------------------------------------------
@doc raw"""
    cast_FITS_header(record::Vector{String})

Generate [`FITS_header`](@ref) from a block of 36 single-record strings of
80 printable ASCII characters.

#### Example:
```
julia> record = [rpad("r$i",8) * ''' * rpad("$i",70) * ''' for i=1:36]
36-element Vector{String}:
 "r1      '1                     " ⋯ 18 bytes ⋯ "                              '"
 "r2      '2                     " ⋯ 18 bytes ⋯ "                              '"
 "r3      '3                     " ⋯ 18 bytes ⋯ "                              '"
 ⋮
 "r34     '34                    " ⋯ 18 bytes ⋯ "                              '"
 "r35     '35                    " ⋯ 18 bytes ⋯ "                              '"
 "r36     '36                    " ⋯ 18 bytes ⋯ "                              '"

julia> h = cast_FITS_header(record);

julia> a35 = h.map["r35"]
35

julia> h.card[35].record
"r35     '35                                                                    '"
```
"""
function cast_FITS_header(record::Vector{String})

    remainder = length(record) % 36

    iszero(remainder) || Base.throw(FITSError(msgErr(8)))
    #                    FITSError 8: fails mandatory integer number of blocks

    card = [cast_FITS_card(i, record[i]) for i ∈ eachindex(record)]
    map = Dict([Base.strip(record[i][1:8]) => i for i ∈ eachindex(record)])

    return FITS_header(card, map)

end

@doc raw"""
    FITS_HDU

Object to hold a single "Header and Data Unit" (HDU).

The fields are
* `.filnam`:  name of the corresponding `.fits` file (`::String`)
* `.hduindex:`:  identifier (a file may contain more than one HDU) (`:Int`)
* `.header`:  the header object (`::FITS_header`)
* `.dataobject`:  the data object (`::FITS_data`)

NB. An empty data block (`.dataobject = nothing`) conforms to the standard.
"""
struct FITS_HDU

    hduindex::Int
    header::FITS_header     # FITS_header
    dataobject::FITS_data   # FITS_data

end
# ------------------------------------------------------------------------------
#             cast_FITS_HDU(hduindex, header, dataobject)
# ------------------------------------------------------------------------------

@doc raw"""
    cast_FITS_HDU(hduindex::Int, header::FITS_header, data::FITS_data)

Generate [`FITS_HDU`](@ref) from given `hduindex`, `header` and `data`.

#### Example:
```
julia> record = [rpad("r$i",8) * ''' * rpad("$i",70) * ''' for i=1:36];

julia> h = cast_FITS_header(record);

julia> data = [11,21,31,12,22,23,13,23,33];

julia> data = reshape(data,(3,3,1));

julia> d = dataobject = cast_FITS_data("IMAGE", data)
FITS_data("IMAGE", [11 12 13; 21 22 23; 31 23 33;;;])

julia> hdu = cast_FITS_HDU(1, h, d);

julia> hdu.header.card[35].record
"r35     '35                                                                    '"

julia> hdu.dataobject.data
3×3×1 Array{Int64, 3}:
[:, :, 1] =
 11  12  13
 21  22  23
 31  23  33
```
"""
function cast_FITS_HDU(hduindex::Int, header::FITS_header, data::FITS_data)

    return FITS_HDU(hduindex, header, data)

end

# ------------------------------------------------------------------------------
#                            FITS_filnam
# ------------------------------------------------------------------------------

@doc raw"""
    FITS_filnam

FITS object to hold the decomposed name of a `.fits` file.

The fields are:
" `    .value`:  for `p#.fits` this is `p#.fits` (`::String`)
* `     .name`:  for `p#.fits` this is `p#` (`::String`)
* `   .prefix`:  for `p#.fits` this is `p` (`::String`)
* `.numerator`:  for `p#.fits` this is `#`, a serial number (e.g., '3') or a range (e.g., '3-7') (`::String`)
* `.extension`:  for `p#.fits` this is `.fits` (`::String`)
"""
mutable struct FITS_filnam

    value::String
    name::String
    prefix::String
    numerator::String
    extension::String

end

# ------------------------------------------------------------------------------
#                      cast_FITS_filnam(filnam; protect=true))
# ------------------------------------------------------------------------------

@doc raw"""
    cast_FITS_filnam(filnam::String)

Generate [`FITS_filnam`](@ref) to decompose `filnam` into its `name`, `prefix`, 
`numerator` and `extension`.
#### Examples:
```
julia> filnam = "T23.01.fits";

julia> nam = cast_FITS_filnam(filnam);

julia> nam = cast_FITS_filnam(filnam)
FITS_filnam("T23.01.fits", "T23.01", "T23.", "01", ".fits")

julia> nam.name, nam.prefix, nam.numerator, nam.extension
("T23.01", "T23.", "01", ".fits")
```
"""
function cast_FITS_filnam(filnam::String)

    filnam = Base.strip(filnam)

    nl = Base.length(filnam)      # nl: length of file name including extension
    ne = Base.findlast('.', filnam)              # ne: first digit of extension

    !isnothing(ne) || Base.throw(FITSError(msgErr(2)))
    !isone(ne) || Base.throw(FITSError(msgErr(3)))

    strExt = filnam[ne:nl]
    strExt = Base.Unicode.lowercase(strExt)

    strExt == ".fits" || Base.throw(FITSError(msgErr(2)))

    strNam = filnam[1:ne-1]

    n = ne - 1                       # n: last digit of numerator (if existent)

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

    return FITS_filnam(filnam, strNam, strPre, strNum, strExt)

end

# ------------------------------------------------------------------------------
#                               FITS
# ------------------------------------------------------------------------------

@doc raw"""
    cast_FITS(filnam::String, hdu::Vector{FITS_HDU})

Object to hold a single `.fits` file .

The fields are
* `.filnam`:  filename of the corresponding `.fits` file (`::String`)
* `.hdu`:  array of [`FITS_HDU`](@ref)s (`::Vector{FITS_HDU}`)
"""
struct FITS

    filnam::FITS_filnam
    hdu::Vector{FITS_HDU}

end

# ------------------------------------------------------------------------------
#                      cast_FITS(filnam, hdu)
# ------------------------------------------------------------------------------
@doc raw"""
    cast_FITS(filnam::String, hdu::Vector{FITS_HDU})

"""
function cast_FITS(filnam::String, hdu::Vector{FITS_HDU})

    nam = cast_FITS_filnam(filnam)

    return FITS(nam, hdu)

end

# ------------------------------------------------------------------------------
#                         FITSError <: Exception
# ------------------------------------------------------------------------------

struct FITSError <: Exception
    msg::String
end

# ------------------------------------------------------------------------------
#                 Base.showerror(io::IO, err::FITSError)
# ------------------------------------------------------------------------------

function Base.showerror(io::IO, err::FITSError)
    print(io, err.msg)
end

# ------------------------------------------------------------------------------
#                             msgErr(err::Int)
# ------------------------------------------------------------------------------

function msgErr(err::Int)

    str = "FITSError: $(err) - "
    str *= Base.get!(dictErr, err, "not found")

    return str

end

function msgError(err::Int)

    str = "FITSError: $(err) - "
    str *= Base.get!(dictError, err, "not found")

    return str

end

# ------------------------------------------------------------------------------
#                             FITS_test 
# ------------------------------------------------------------------------------

mutable struct FITS_test
    index::Int
    err::Int
    name::String
    passed::Bool
    msgpass::String
    msgfail::String
    msgwarn::String
    msghint::String
end

# ------------------------------------------------------------------------------
#                    cast_FITS_test(index::Int)
# ------------------------------------------------------------------------------

function cast_FITS_test(index::Int, err)

    passed = err == 0 ? true : false

    name = get(dictTest, index, "testname not found")
    p = Base.get(dictPass, index, "")
    f = "FITSError: $(err) - " * Base.get(dictFail, index, "")
    w = "FITSWarning: $(index) - " * Base.get(dictWarn, index, "")
    h = "FITSError: $(err) - " * Base.get(dictHint, index, "")

    F = FITS_test(index, err, name, passed, p, f, w, h)

    return F

end