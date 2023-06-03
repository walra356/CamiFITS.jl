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
function cast_FITS_header(dataobject::FITS_data)

    hdutype = dataobject.hdutype

    record = hdutype == "'PRIMARY '" ? _header_record_primary(dataobject) :
             hdutype == "'GROUPS  '" ? _header_record_groups(dataobject) :
             hdutype == "'IMAGE   '" ? _header_record_image(dataobject) :
             hdutype == "'TABLE   '" ? _header_record_table(dataobject) :
             hdutype == "'BINTABLE'" ? _header_record_bintable(dataobject) :
             Base.throw(FITSError(msgErr(25))) # hdutype not recognized

    return cast_FITS_header(record::Vector{String})

end
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

    hdutype = dataobject.hdutype
    data = dataobject.data

    if (hdutype == "'TABLE   '") & (eltype(data) ≠ Vector{String})
        # data input as array of table COLUMNS
        col = data
        ncols = length(col)
        nrows = length(col[1])
        strcol = [Vector{String}(undef, nrows) for i = 1:ncols]

        # convert data to fortran strings
        for i=1:ncols
            T = typeof(col[i][1])
            T = T == String ? Char : T
            x = FORTRAN_type_char(T)
            if x == 'L'
                strcol[i] = [(col[i][j] ? "T" : "F") for j=1:nrows]
            elseif x == 'E'
                strcol[i] = replace.(string.(col[i]), "e" => "E")
            elseif x == 'D' 
                strcol[i] = replace.(string.(col[i]), "e" => "D")
            else 
                strcol[i] = string.(col[i])
            end
        end

        # w = required widths of fits data fields
        w = [maximum([length(strcol[i][j]) + 1 for j = 1:nrows]) for i = 1:ncols]

        # transpose matrix and join data into vector of strings
        data = [join([lpad(strcol[i][j], w[i]) for i = 1:ncols]) for j = 1:nrows]
        # data output as Vector{String}
        # this is the Vector{String} of table ROWS (equal-size fields)
        dataobject = FITS_data(hdutype, data)
    end

    return FITS_HDU(hduindex, header, dataobject)

end

# ------------------------------------------------------------------------------
#                            FITS_filnam
# ------------------------------------------------------------------------------

@doc raw"""
    FITS_filnam

mutable FITS object to hold the decomposed name of a `.fits` file.

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

    strbitpix = Base.lpad(bitpix, 20)
    strnaxis = Base.lpad(ndims, 20)
    strdims = [Base.lpad(dims[i], 20) for i ∈ eachindex(dims)]
    strbzero = Base.lpad(bzero, 20)

    r::Vector{String} = []

    Base.push!(r, "SIMPLE  =                    T / file does conform to FITS standard             ")
    Base.push!(r, "BITPIX  = " * strbitpix * " / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   = " * strnaxis * " / number of data axes                            ")
    for i = 1:ndims
        Base.push!(r, "NAXIS$i  = " * strdims[i] * " / length of data axis " * rpad(i, 27))
    end
    if !iszero(bzero)
        Base.push!(r, "BZERO   = " * strbzero * " / offset data range to that of unsigned integer  ")
        Base.push!(r, "BSCALE  =                  1.0 / default scaling factor                         ")
    end
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
    hdutype == "'GROUPS   '" && error("hdutype $(hdutype) not implemented")

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
    dims = Base.size(data)
    nbyte = T ≠ Any ? Base.sizeof(T) : 8
    nbits = 8 * nbyte
    bzero = T ∉ [Int8, UInt16, UInt32, UInt64, UInt128] ? 0.0 :
            T == Int8 ? -128.0 : 2^(nbits - 1)
    bitpix = T <: AbstractFloat ? -abs(nbits) : nbits

    strbitpix = Base.lpad(bitpix, 20)
    strnaxis = Base.lpad(ndims, 20)
    strdims = [Base.lpad(dims[i], 20) for i ∈ eachindex(dims)]
    strbzero = Base.lpad(bzero, 20)

    r::Vector{String} = []

    Base.push!(r, "XTENSION= 'IMAGE   '           / FITS standard extension                        ")
    Base.push!(r, "BITPIX  = " * strbitpix * " / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   = " * strnaxis * " / number of data axes                            ")
    for i = 1:ndims
        Base.push!(r, "NAXIS$i  = " * strdims[i] * " / length of data axis " * rpad(i, 27))
    end
    if !iszero(bzero)
        Base.push!(r, "BZERO   = " * strbzero * " / offset data range to that of unsigned integer  ")
        Base.push!(r, "BSCALE  =                  1.0 / default scaling factor                         ")
    end
    Base.push!(r, "END                                                                             ")

    _append_blanks!(r)

    return r

end

# ------------------------------------------------------------------------------
#                      fits_tform(dataobject::FITS_data)
# ------------------------------------------------------------------------------

function _tform_table(tcol::Vector{}, x::Char)

    w = d = 0
    tform = '-'
    if x == 'L'
        tform = "L1"
    elseif x == 'I'
        col = string.(tcol)
        w = maximum(length.(col))
        tform = x * string(w)
    elseif x ∈ ('E', 'D')
        col = string.(tcol)
        x = 'e' ∈ col[1] ? x : 'F'
        for i ∈ eachindex(col)
            if !isnothing(findfirst('.', col[i]))
                a = (length.(split(col[i], '.')))
                w = max(w, a[1])
                d = max(d, a[2])
            end
        end
        tform = x * string(w) * '.' * string(d)
    elseif x == 'A'
        T = eltype(tcol)
        w = T == Char ? 1 : maximum(length.(tcol))
        tform = x * string(w)
    end

    tform ≠ '-' || Base.throw(FITSError(msgErr(40)))

    return tform

end
# ------------------------------------------------------------------------------
function fits_tform(dataobject::FITS_data)

    hdutype = dataobject.hdutype
    data = dataobject.data
    ncols = length(data) # number of columns in table (= rows in input data !)
    nrows = length(data[1]) # number of rows in table (= columns in data !!!!)

    tform = Vector{String}(undef, ncols)  # table format descriptor Xw.d

    tform = String[]
    if hdutype == "'TABLE   '"
        for i ∈ eachindex(data)
            col = data[i]
            T = eltype(col[1])
            x = FORTRAN_type_char(T)
            x = x ∈ ('B', 'I', 'J', 'K') ? 'I' : x
            push!(tform, _tform_table(col, x))
        end
    elseif hdutype == "'BINTABLE'"
    else
    end

    return tform

end

# ==============================================================================
#                  _header_record_table(dataobject)
# ------------------------------------------------------------------------------


function _header_record_table(dataobject::FITS_data)

    hdutype = dataobject.hdutype
    hdutype == "'TABLE   '" || Base.throw(FITSError(msgErr(30)))
    col = dataobject.data

    # data input as Any array of table COLUMNS
    ncols = length(col) # number of columns in table (= rows in data)
    nrows = length(col[1]) # number of rows in table (= columns in data)
    ncols > 0 || Base.throw(FITSError(msgErr(34)))
    ncols ≤ 999 || Base.throw(FITSError(msgErr(32)))
    equal = sum(length.(col) .- nrows) == 0 # equal column length test
    equal || Base.throw(FITSError(msgErr(33)))

    tform = fits_tform(dataobject)
    strcol = [Vector{String}(undef, nrows) for i = 1:ncols]
    # convert data to array of fortran strings
    for i = 1:ncols
        T = typeof(col[i][1])
        T = T == String ? Char : T
        x = FORTRAN_type_char(T)
        if x == 'L'
            strcol[i] = [(col[i][j] ? "T" : "F") for j = 1:nrows]
        elseif x == 'E'
            strcol[i] = replace.(string.(col[i]), "e" => "E")
        elseif x == 'D'
            strcol[i] = replace.(string.(col[i]), "e" => "D")
        else
            strcol[i] = string.(col[i])
        end
    end

    # width = required widths of fits data fields
    width = [maximum([length(strcol[i][j]) + 1 for j = 1:nrows]) for i = 1:ncols]
    tbcol = [sum(width[1:i-1])+1 for i=1:ncols]
    lrows = sum(width[i] for i = 1:ncols)

    tform = ["'" * Base.rpad(tform[i], 8) * "'" for i = 1:ncols]
    tform = [Base.rpad(tform[i], 20) for i = 1:ncols]
    ttype = ["HEAD$i" for i = 1:ncols]
    ttype = ["'" * Base.rpad(ttype[i], 18) * "'" for i = 1:ncols]          # default column headers

    naxis1 = Base.lpad(lrows, 20) 
    naxis2 = Base.lpad(nrows, 20)
    tfields = Base.lpad(ncols, 20)
    tbcol = [Base.lpad(tbcol[i], 20) for i ∈ eachindex(tbcol)]

    r::Array{String,1} = []

    Base.push!(r, "XTENSION= 'TABLE   '           / FITS standard extension                        ")
    Base.push!(r, "BITPIX  =                    8 / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   =                    2 / number of data axes                            ")
    Base.push!(r, "NAXIS1  = " * naxis1 * " / number of bytes/row                            ")
    Base.push!(r, "NAXIS2  = " * naxis2 * " / number of rows                                 ")
    Base.push!(r, "PCOUNT  =                    0 / number of bytes in supplemetal data area       ")
    Base.push!(r, "GCOUNT  =                    1 / data blocks contain single table               ")
    Base.push!(r, "TFIELDS = " * tfields * " / number of data fields (columns)                ")
    Base.push!(r, "COLSEP  =                    1 / number of spaces in column separator           ")
    for i = 1:ncols
        Base.push!(r, rpad("TTYPE$i", 8) * "= " * ttype[i] * " / header of column " * rpad(i, 30))
        Base.push!(r, rpad("TBCOL$i", 8) * "= " * tbcol[i] * " / pointer to column " * rpad(i, 29))
        Base.push!(r, rpad("TFORM$i", 8) * "= " * tform[i] * " / data type of column " * rpad(i, 27))
        Base.push!(r, rpad("TDISP$i", 8) * "= " * tform[i] * " / data type of column " * rpad(i, 27))
    end
    Base.push!(r, "END                                                                             ")

    pass = sum(length.(r) .- 80) == false

    pass || println("length table_data records: ", [length.(r)])

    _append_blanks!(r)

    return r

end

# ==============================================================================
#                  _header_record_bintable(dataobject)
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
function _table_bindata_types(dataobject::FITS_data)

    data = dataobject.data
    ncols = length(data) # number of columns in table (= rows in input data !!)
    nrows = length(data[1]) # number of rows in table (= columns in input data !!!!)

    fmtsp = Array{String,1}(undef, ncols)  # format specifier Xw.d

    for col ∈ eachindex(fmtsp)
        T = eltype(data[col][1])
        x = T <: Integer ? "I" : T <: Real ? "E" :
            T == Float64 ? "D" : T <: Union{String,Char} ? "A" : "X"
        w = string(maximum([length(string(data[col][row])) for row = 1:nrows]))

        if T <: Union{Char,String}
            isascii(join(data[1])) || Base.throw(FITSError(msgErr(36)))
        end

        if T <: Union{Float16,Float32,Float64}
            v = string(data[col][1])
            x = (('e' ∉ v) & ('p' ∉ v)) ? 'F' : x
            v = 'e' ∈ v ? split(v, 'e')[1] : 'p' ∈ v ? split(v, 'p')[1] : v
            d = !isnothing(findfirst('.', v)) ? string(length(split(v, '.')[2])) : '0'
        end

        fmtsp[col] = T <: Union{Float16,Float32,Float64} ? (x * w * '.' * d) : x * w
    end

    return fmtsp

end
# ------------------------------------------------------------------------------

function _header_record_bintable(dataobject::FITS_data) 

    hdutype = dataobject.hdutype
    #hdutype == "'BINTABLE'" && error("hdutype $(hdutype) not implemented")
    hdutype == "'BINTABLE'" || Base.throw(FITSError(msgErr(31)))
    data = dataobject.data

    # data input as Any array of table COLUMNS
    ncols = length(data) # number of columns in table (= rows in data)
    nrows = length(data[1]) # number of rows in table (= columns in data)
    ncols > 0 || Base.throw(FITSError(msgErr(34)))
    ncols ≤ 999 || Base.throw(FITSError(msgErr(32)))
    equal = sum(length.(data) .- nrows) == 0 # equal colum length test
    equal || Base.throw(FITSError(msgErr(33)))
    
    nbyte = 8
    tzero = String[]
    for i = 1:ncols
        T = Base.eltype(data[i][1])
        isfitstype(T) || error("FITSError: $T is not a supported datatype")
        nbyte, bzero = zeroffset(T)
        tzero = push!(tzero, Base.lpad(bzero, 20))
    end

    tform = _table_bindata_types(dataobject)

    tform = ["'" * Base.rpad(tform[i], 8) * "'" for i = 1:ncols]
    tform = [Base.rpad(tform[i], 20) for i = 1:ncols]
    ttype = ["HEAD$i" for i = 1:ncols]
    ttype = ["'" * Base.rpad(ttype[i], 18) * "'" for i = 1:ncols]          # default column headers

    naxis1 = Base.lpad(nbyte, 20) 
    naxis2 = Base.lpad(nrows, 20)
    tfields = Base.lpad(ncols, 20)

    r::Vector{String} = []

    Base.push!(r, "XTENSION= 'TABLE   '           / FITS standard extension                        ")
    Base.push!(r, "BITPIX  =                    8 / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   =                    2 / number of data axes                            ")
    Base.push!(r, "NAXIS1  = " * naxis1 * " / number of bytes/row                            ")
    Base.push!(r, "NAXIS2  = " * naxis2 * " / number of rows                                 ")
    Base.push!(r, "PCOUNT  =                    0 / number of bytes in supplemetal data area       ")
    Base.push!(r, "GCOUNT  =                    1 / data blocks contain single table               ")
    Base.push!(r, "TFIELDS = " * tfields * " / number of data fields (columns)                ")
    for i = 1:ncols
        Base.push!(r, rpad("TTYPE$i", 8) * "= " * ttype[i] * " / header of column " * rpad(i, 30))
        Base.push!(r, rpad("TFORM$i", 8) * "= " * tform[i] * " / data type of column " * rpad(i, 27))
        Base.push!(r, rpad("TDISP$i", 8) * "= " * tform[i] * " / data type of column " * rpad(i, 27))
        Base.push!(r, rpad("TZERO$i", 8) * "= " * tbcol[i] * " / pointer to column " * rpad(i, 29))
    end
    Base.push!(r, "END                                                                             ")

    pass = sum(length.(r) .- 80) == false

    pass || println("length table_data records: ", [length.(r)])

    _append_blanks!(r)

    return r

end

function isfitstype(T::Type)

    fitstype = [Float16, Float32, Float64]
    append!(fitstype, [Bool, Int8, Int16, Int32, Int64])
    append!(fitstype, [UInt8, UInt16, UInt32, UInt64])
    append!(fitstype, [Char, String])

    return T ∈ fitstype

end

function zeroffset(T::Type)

    nbyte = T ≠ Any ? Base.sizeof(T) : 8 # intercept empty array Any[]
    nbits = 8 * nbyte
    bzero = T ∉ [Int8, UInt16, UInt32, UInt64] ? 0.0 :
            T == Int8 ? -128 :
            T == UInt64 ? 9223372036854775808 : 2^(nbits - 1)

    return nbyte, bzero

end

function fmtsp(x)

    data = dataobject.data
    ncols = length(data) # number of columns in table (= rows in input data !!)
    nrows = length(data[1]) # number of rows in table (= columns in input data !!!!)

    fmtsp = Array{String,1}(undef, ncols)  # format specifier Xw.d

    for col ∈ eachindex(fmtsp)
        T = eltype(data[col][1])
        x = T <: Integer ? "I" : T <: Real ? "E" :
            T == Float64 ? "D" : T <: Union{String,Char} ? "A" : "X"
        w = string(maximum([length(string(data[col][row])) for row = 1:nrows]))

        if T <: Union{Char,String}
            isascii(join(data[1])) || Base.throw(FITSError(msgErr(36)))
        end

        if T <: Union{Float16,Float32,Float64}
            v = string(data[col][1])
            x = (('e' ∉ v) & ('p' ∉ v)) ? 'F' : x
            v = 'e' ∈ v ? split(v, 'e')[1] : 'p' ∈ v ? split(v, 'p')[1] : v
            d = !isnothing(findfirst('.', v)) ? string(length(split(v, '.')[2])) : '0'
        end

        fmtsp[col] = T <: Union{Float16,Float32,Float64} ? (x * w * '.' * d) : x * w
    end

    return fmtsp

end