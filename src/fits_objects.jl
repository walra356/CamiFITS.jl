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
* `.hdutype`:  accepted types are 'PRIMARY', 'IMAGE' and 'TABLE' (`::String`)
* `.data`:  in the from appropriate for the `hdutype` (::Any)
"""
struct FITS_data

    hdutype::String
    data::Any
end

# ------------------------------------------------------------------------------
#                    cast_FITS_data(hdutype, data)
# ------------------------------------------------------------------------------

@doc raw"""
    cast_FITS_data(hdutype::String, data)

Create the [`FITS_data`](@ref) object for given `hduindex` constructed from 
the `data` in accordance to the specified `hdutype`: *PRIMARY*, 
*IMAGE*, *ARRAY*, *TABLE* (ASCII table) or *BINARRAY* (binary array).
#### Example:
```
julia> record = [rpad("r$i",8) * ''' * rpad("$i",70) * ''' for i=1:36];

julia> h = cast_FITS_header(record);

julia> data = [11,21,31,12,22,23,13,23,33];

julia> data = reshape(data,(3,3,1));

julia> d = dataobject = cast_FITS_data("'IMAGE   '", data)
FITS_data("'IMAGE   '", [11 12 13; 21 22 23; 31 23 33;;;])

julia> d.data
3×3×1 Array{Int64, 3}:
[:, :, 1] =
 11  12  13
 21  22  23
 31  23  33

julia> d.hdutype
"'IMAGE   '"
```
"""
function cast_FITS_data(hdutype::String, data)

    hdutype = _format_hdutype(hdutype)

    if (hdutype == "'TABLE   '") & (eltype(data) ≠ Vector{String})
        println("string data")
        # data input as Any array of table COLUMNS
        cols = data 
        ncols = length(cols)
        nrows = length(cols[1])
        w = [maximum([length(string(cols[i][j])) + 1 for j = 1:nrows]) for i = 1:ncols]
        # w = required widths of fits data fields
        data = [[rpad(string(cols[i][j]), w[i]) for i = 1:ncols] for j = 1:nrows]
        # data output as Vector{String} of table ROWS (of equal size fields)
        # NB. the table has been transposed
    end
    
    return FITS_data(hdutype, data)

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

Create the [`FITS_card`](@ref) object for `record` with index `cardindex`.
#### Example:
```
julia> record = "SIMPLE  =                    T / file does conform to FITS standard             ";

julia> card = cast_FITS_card(1, record);

julia> card.cardindex, card.keyword, card.value, card.comment
(1, "SIMPLE", true, "file does conform to FITS standard             ")
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

# ==============================================================================
#                       cast_FITS_header()
# ------------------------------------------------------------------------------
@doc raw"""
    cast_FITS_header(dataobject::FITS_data)

Create the [`FITS_header`](@ref) object from the dataobject. The 
dataobject-input mode is used by [`fits_create`](@ref) to ceate the header
object as part of creating the [`FITS`](@ref) obhectstarting from Julia data 
input.
"""
function cast_FITS_header(dataobject::FITS_data)

    hdutype = dataobject.hdutype

    record = hdutype == "'PRIMARY '" ? _header_record_primary(dataobject) :
             hdutype == "'GROUPS  '" ? _header_record_groups(dataobject) :
             hdutype == "'IMAGE   '" ? _header_record_image(dataobject) :
             hdutype == "'ARRAY   '" ? _header_record_array(dataobject) :
             hdutype == "'TABLE   '" ? _header_record_table(dataobject) :
             hdutype == "'BINTABLE'" ? _header_record_bintable(dataobject) :
             Base.throw(FITSError(msgErr(25))) # hdutype not recognized

    return cast_FITS_header(record::Vector{String})

end
@doc raw"""
    cast_FITS_header(record::Vector{String})

Create the [`FITS_header`](@ref) object from a block of 36 single-record 
strings (of 80 printable ASCII characters). The record-input mode is used
by [`fits_read`](@ref) after reading the header records from disk.
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

Create the [`FITS_HDU`](@ref) object from given `hduindex`, `header` and `data`.

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
function cast_FITS_HDU(hduindex::Int, header::FITS_header, dataobject::FITS_data)

    return FITS_HDU(hduindex, header, dataobject)

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

Create the [`FITS_filnam`](@ref) object to decompose `filnam` into its `name`, 
`prefix`, `numerator` and `extension`.
#### Example:
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
    FITS(filnam::String, hdu::Vector{FITS_HDU})

Object to hold a single `.fits` file.

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

Create the [`FITS`](@ref) object to hold a single `.fits` file.
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

# ------------------------------------------------------------------------------
#                 _primary_header_records(dataobject)
# ------------------------------------------------------------------------------

function _header_record_primary(dataobject::FITS_data)

    hdutype = dataobject.hdutype
    hdutype == "'PRIMARY '" || Base.throw(FITSError(msgErr(26)))
    data = dataobject.data

    T = Base.eltype(data)

    ndims = Base.ndims(data)
    ndims ≤ 3 || Base.throw(FITSError(msgErr(38)))
    dims = Base.size(data)
    nbyte = T ≠ Any ? Base.sizeof(T) : 8
    nbits = 8 * nbyte
    bzero = T ∉ [Int8, UInt16, UInt32, UInt64, UInt128] ? 0.0 :
            T == Int8 ? -128.0 : 2^(nbits - 1)
    bitpix = T <: AbstractFloat ? -abs(nbits) : nbits

    bitpix = Base.lpad(bitpix, 20)
    naxis = Base.lpad(ndims, 20)
    dims = [Base.lpad(dims[i], 20) for i ∈ eachindex(dims)]
    bzero = Base.lpad(bzero, 20)

    r::Vector{String} = []

    Base.push!(r, "SIMPLE  =                    T / file does conform to FITS standard             ")
    Base.push!(r, "BITPIX  = " * bitpix * " / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   = " * naxis * " / number of data axes                            ")
    for i = 1:ndims
        Base.push!(r, "NAXIS$i  = " * dims[i] * " / length of data axis " * rpad(i, 27))
    end
    Base.push!(r, "BZERO   = " * bzero * " / offset data range to that of unsigned integer  ")
    Base.push!(r, "BSCALE  =                  1.0 / default scaling factor                         ")
    Base.push!(r, "EXTEND  =                    T / FITS dataset may contain extensions            ")
    Base.push!(r, "COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/                     ")
    Base.push!(r, "END                                                                             ")

    _append_blanks!(r)

    return r

end

# ------------------------------------------------------------------------------
#                 _header_record_groups(dataobject)
# ------------------------------------------------------------------------------

function _header_record_groups(dataobject::FITS_data)

    hdutype = dataobject.hdutype
    hdutype == "'GROUPS   '" || Base.throw(FITSError(msgErr(27)))
    ndims = dataobject.naxis
    dims = dataobject.dims
    nbyte = dataobject.nbyte
    bzero = dataobject.bzero
    T = dataobject.eltype

    nbits = 8 * nbyte
    bitpix = T <: AbstractFloat ? -abs(nbits) : nbits

    hdutype = Base.rpad(hdutype, 20)
    bitpix = Base.lpad(bitpix, 20)
    naxis = Base.lpad(ndims, 20)
    dims = [Base.lpad(dims[i], 20) for i ∈ eachindex(dims)]
    bzero = Base.lpad(bzero, 20)

    r::Vector{String} = []

    Base.push!(r, "SIMPLE  =                    T / file does conform to FITS standard             ")
    Base.push!(r, "BITPIX  = " * bitpix * " / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   = " * naxis * " / number of data axes                            ")
    Base.push!(r, "NAXIS1  =             0 / length of data axis                                   ")
    [Base.push!(r, "NAXIS$i  = " * dims[i] * " / length of data axis " * rpad(i, 27)) for i = 2:ndims]
    Base.push!(r, "BZERO   = " * bzero * " / offset data range to that of unsigned integer  ")
    Base.push!(r, "BSCALE  =                  1.0 / default scaling factor                         ")
    Base.push!(r, "GROUPS  =                    T / random groups present                          ")
    Base.push!(r, "PCOUNT  =                    0 / number of parameters per group                 ")
    Base.push!(r, "GCOUNT  =                    1 / number of groups                               ")
    Base.push!(r, "END                                                                             ")

    _append_blanks!(r)

    return r

end

# ------------------------------------------------------------------------------
#                 _header_record_image(dataobject)
# ------------------------------------------------------------------------------

function _header_record_image(dataobject::FITS_data)

    hdutype = dataobject.hdutype
    hdutype == "'IMAGE   '" || Base.throw(FITSError(msgErr(28)))
    data = dataobject.data

    T = Base.eltype(data)

    ndims = Base.ndims(data)
    ndims ≤ 3 || Base.throw(FITSError(msgErr(38)))
    dims = Base.size(data)
    nbyte = T ≠ Any ? Base.sizeof(T) : 8
    nbits = 8 * nbyte
    bzero = T ∉ [Int8, UInt16, UInt32, UInt64, UInt128] ? 0.0 :
            T == Int8 ? -128.0 : 2^(nbits - 1)
    bitpix = T <: AbstractFloat ? -abs(nbits) : nbits

    hdutype = Base.rpad(hdutype, 20)
    bitpix = Base.lpad(bitpix, 20)
    naxis = Base.lpad(ndims, 20)
    dims = [Base.lpad(dims[i], 20) for i ∈ eachindex(dims)]
    bzero = Base.lpad(bzero, 20)

    r::Vector{String} = []

    Base.push!(r, "XTENSION= " * hdutype * " / FITS standard extension                        ")
    Base.push!(r, "BITPIX  = " * bitpix * " / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   = " * naxis * " / number of data axes                            ")
    for i = 1:ndims
        Base.push!(r, "NAXIS$i  = " * dims[i] * " / length of data axis " * rpad(i, 27))
    end
    Base.push!(r, "PCOUNT  =                    0 / number of parameters per group                 ")
    Base.push!(r, "GCOUNT  =                    1 / number of groups                               ")
    Base.push!(r, "BZERO   = " * bzero * " / offset data range to that of unsigned integer  ")
    Base.push!(r, "BSCALE  =                  1.0 / default scaling factor                         ")
    Base.push!(r, "END                                                                             ")

    _append_blanks!(r)

    return r

end

# ------------------------------------------------------------------------------
#                 _header_record_array(dataobject)
# ------------------------------------------------------------------------------

function _header_record_array(dataobject::FITS_data)

    hdutype = dataobject.hdutype
    hdutype == "'ARRAY   '" || Base.throw(FITSError(msgErr(29)))
    data = dataobject.data

    T = Base.eltype(data)

    ndims = Base.ndims(data)
    ndims ≤ 999 || Base.throw(FITSError(msgErr(21)))
    dims = Base.size(data)
    nbyte = T ≠ Any ? Base.sizeof(T) : 8
    nbits = 8 * nbyte
    bzero = T ∉ [Int8, UInt16, UInt32, UInt64, UInt128] ? 0.0 :
            T == Int8 ? -128.0 : 2^(nbits - 1)
    bitpix = T <: AbstractFloat ? -abs(nbits) : nbits

    hdutype = Base.rpad(hdutype, 20)
    bitpix = Base.lpad(bitpix, 20)
    naxis = Base.lpad(ndims, 20)
    dims = [Base.lpad(dims[i], 20) for i ∈ eachindex(dims)]
    bzero = Base.lpad(bzero, 20)

    r::Vector{String} = []

    Base.push!(r, "XTENSION= " * hdutype * " / FITS standard extension                        ")
    Base.push!(r, "BITPIX  = " * bitpix * " / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   = " * naxis * " / number of data axes                            ")
    for i = 1:ndims
        Base.push!(r, "NAXIS$i  = " * dims[i] * " / length of data axis " * rpad(i, 27))
    end
    Base.push!(r, "PCOUNT  =                    0 / number of parameters per group                 ")
    Base.push!(r, "GCOUNT  =                    1 / number of groups                               ")
    Base.push!(r, "BZERO   = " * bzero * " / offset data range to that of unsigned integer  ")
    Base.push!(r, "BSCALE  =                  1.0 / default scaling factor                         ")
    Base.push!(r, "END                                                                             ")

    _append_blanks!(r)

    return r

end

# ==============================================================================
#                  _header_record_table(dataobject)
# ------------------------------------------------------------------------------

function _table_data_types(dataobject::FITS_data)

    data = dataobject.data
    nrows = length(data)
    ncols = length(data[1])

    fmtsp = Array{String,1}(undef, ncols)  # format specifier Xw.d

    for col ∈ eachindex(fmtsp)
        T = eltype(data[1][col])
        x = T <: Integer ? "I" : T <: Real ? "E" : T == Float64 ? "D" : T <: Union{String,Char} ? "A" : "X"
        w = string(maximum([length(string(data[row][col])) for row = 1:nrows]))
println("w = $w")

        if T <: Union{Char,String}
            isascii(join(data[1])) || Base.throw(FITSError(msgErr(36)))
        end

        if T <: Union{Float16,Float32,Float64}
            v = string(data[row][1])
            x = (('e' ∉ v) & ('p' ∉ v)) ? 'F' : x
            v = 'e' ∈ v ? split(v, 'e')[1] : 'p' ∈ v ? split(v, 'p')[1] : v
            d = !isnothing(findfirst('.', v)) ? string(length(split(v, '.')[2])) : '0'
        end

        fmtsp[col] = T <: Union{Float16,Float32,Float64} ? (x * w * '.' * d) : x * w
    end

    return fmtsp

end

function _header_record_table(dataobject::FITS_data) # input array of table columns

    hdutype = dataobject.hdutype
    hdutype == "'TABLE   '" || Base.throw(FITSError(msgErr(30)))
    data = dataobject.data
    ndims = eltype(data) == String ? 1 : Base.ndims(eltype(data))
    ndims += Base.ndims(data)
    ndims == 2 || Base.throw(FITSError(msgErr(39)))
    nrows = length(data)
    ncols = length(data[1])
    nbits = 8
    
    pcols = 1  # pointer to starting position of column in table row
    ncols > 0 || Base.throw(FITSError(msgErr(34)))
    ncols ≤ 999 || Base.throw(FITSError(msgErr(32)))
    lcols = [length(data[row]) for row = 1:nrows] # length of columns (number of rows)
    pass = sum(lcols .- ncols) == 0               # equal colum length test
    pass || Base.throw(FITSError(msgErr(33)))

    w = [length(string(data[1][col])) for col = 1:ncols]
    tbcol = [sum(w[1:i-1])+1 for i=1:ncols]
    lrows = sum([length(string(data[1][col])) for col = 1:ncols])

    tform = _table_data_types(dataobject)

    tform = ["'" * Base.rpad(tform[i], 8) * "'" for i = 1:ncols]
    tform = [Base.rpad(tform[i], 20) for i = 1:ncols]
    ttype = ["HEAD$i" for i = 1:ncols]
    ttype = ["'" * Base.rpad(ttype[i], 18) * "'" for i = 1:ncols]          # default column headers

    hdutype = Base.rpad(hdutype, 20)
    bitpix = Base.lpad(nbits, 20)
    naxis = Base.lpad(ndims, 20)
    naxis1 = Base.lpad(lrows, 20) 
    naxis2 = Base.lpad(nrows, 20)
    tfields = Base.lpad(ncols, 20)
    tbcol = [Base.lpad(tbcol[i], 20) for i ∈ eachindex(tbcol)]

    r::Array{String,1} = []

    Base.push!(r, "XTENSION= " * hdutype * " / FITS standard extension                        ")
    Base.push!(r, "BITPIX  = " * bitpix * " / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   = " * naxis * " / number of data axes                            ")
    Base.push!(r, "NAXIS1  = " * naxis1 * " / number of bytes/row                            ")
    Base.push!(r, "NAXIS2  = " * naxis2 * " / number of rows                                 ")
    Base.push!(r, "PCOUNT  =                    0 / number of bytes in supplemetal data area       ")
    Base.push!(r, "GCOUNT  =                    1 / data blocks contain single table               ")
    Base.push!(r, "TFIELDS = " * tfields * " / number of data fields (columns)                ")
    Base.push!(r, "COLSEP  =                    1 / number of spaces in column separator           ")
    for i = 1:ncols
        Base.push!(r, "TTYPE$i  = " * ttype[i] * " / header of column " * rpad(i, 30))
        Base.push!(r, "TBCOL$i  = " * tbcol[i] * " / pointer to column " * rpad(i, 29))
        Base.push!(r, "TFORM$i  = " * tform[i] * " / data type of column " * rpad(i, 27))
        Base.push!(r, "TDISP$i  = " * tform[i] * " / data type of column " * rpad(i, 27))
    end
    Base.push!(r, "END                                                                             ")

    pass = sum(length.(r) .- 80) == false

    pass || println([length.(r)])

    _append_blanks!(r)

    return r

end
function _header_record_bintable(dataobject::FITS_data) # input array of table columns

    hdutype = dataobject.hdutype
    hdutype == "'BINTABLE'" || Base.throw(FITSError(msgErr(30)))
    cols = dataobject.data
    ndims = eltype(cols) == String ? 1 : Base.ndims(eltype(cols))
    ndims += Base.ndims(cols)
    ndims == 2 || Base.throw(FITSError(msgErr(39)))
    ncols = length(cols)
    nrows = length(cols[1])
    nbits = 8

    pcols = 1  # pointer to starting position of column in table row
    ncols > 0 || Base.throw(FITSError(msgErr(34)))
    ncols ≤ 999 || Base.throw(FITSError(msgErr(32)))
    lcols = [length(cols[i]) for i = 1:ncols] # length of columns (number of rows)
    pass = (sum(.!(lcols .== fill(nrows, ncols))) == 0) # equal colum length test
    pass || Base.throw(FITSError(msgErr(33)))

    w = [maximum([length(string(cols[i][j])) + 1 for j = 1:nrows]) for i = 1:ncols]
    data = [join([rpad(string(cols[i][j]), w[i])[1:w[i]] for i = 1:ncols]) for j = 1:nrows]

    tbcol = [pcols += w[i] for i = 1:(ncols-1)] # field pointers (first column)
    tbcol = prepend!(tbcol, 1)
    tbcol = [Base.lpad(tbcol[i], 20) for i = 1:ncols]

    tform = _table_data_types(dataobject)

    tform = ["'" * Base.rpad(tform[i], 8) * "'" for i = 1:ncols]
    tform = [Base.rpad(tform[i], 20) for i = 1:ncols]
    ttype = ["HEAD$i" for i = 1:ncols]
    ttype = ["'" * Base.rpad(ttype[i], 18) * "'" for i = 1:ncols]          # default column headers

    hdutype = Base.rpad(hdutype, 20)
    bitpix = Base.lpad(nbits, 20)
    naxis = Base.rpad(ndims, 20)
    naxis1 = Base.lpad(sum(w), 20)
    naxis2 = Base.lpad(nrows, 20)
    tfields = Base.lpad(ncols, 20)

    r::Array{String,1} = []

    Base.push!(r, "XTENSION= " * hdutype * " / FITS standard extension                        ")
    Base.push!(r, "BITPIX  = " * bitpix * " / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   = " * naxis * " / number of data axes                            ")
    Base.push!(r, "NAXIS1  = " * naxis1 * " / number of bytes/row                            ")
    Base.push!(r, "NAXIS2  = " * naxis2 * " / number of rows                                 ")
    Base.push!(r, "PCOUNT  =                    0 / number of bytes in supplemetal data area       ")
    Base.push!(r, "GCOUNT  =                    1 / data blocks contain single table               ")
    Base.push!(r, "TFIELDS = " * tfields * " / number of data fields (columns)                ")
    Base.push!(r, "COLSEP  =                    1 / number of spaces in column separator           ")
    for i = 1:ncols
        Base.push!(r, "TTYPE$i  = " * ttype[i] * " / header of column " * rpad(i, 30))
    end
    for i = 1:ncols
        Base.push!(r, "TBCOL$i  = " * tbcol[i] * " / pointer to column " * rpad(i, 29))
    end
    for i = 1:ncols
        Base.push!(r, "TFORM$i  = " * tform[i] * " / data type of column " * rpad(i, 27))
    end
    for i = 1:ncols
        Base.push!(r, "TDISP$i  = " * tform[i] * " / data type of column " * rpad(i, 27))
    end
    Base.push!(r, "END                                                                             ")

    _append_blanks!(r)

    return r

end

