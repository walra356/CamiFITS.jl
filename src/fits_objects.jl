# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                          fits_objects.jl
#                      Jook Walraven 15-03-2023
# ------------------------------------------------------------------------------

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

julia> n = cast_FITS_filnam(filnam);

julia> n.name, n.prefix, n.numerator, n.extension
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
#                               FITS_dataobject
# ------------------------------------------------------------------------------

"""
    FITS_dataobject

Object to hold the data of the [`FITS_HDU`](@ref) of given `hdutype`.

The fields are:
* `.hdutype`:  accepted types are 'PRIMARY', 'IMAGE' and 'TABLE' (`::String`)
* `.data`:  in the from appropriate for the `hdutype` (::Any)
"""
struct FITS_dataobject

    hdutype::String
    data::Any
end

# ------------------------------------------------------------------------------
#                    cast_FITS_dataobject(hdutype, data)
# ------------------------------------------------------------------------------

@doc raw"""
    cast_FITS_dataobject(hdutype::String, data)

Create the [`FITS_dataobject`](@ref) object for given `hduindex` constructed from 
the `data` in accordance to the specified `hdutype`: *PRIMARY*, 
*IMAGE*, *ARRAY*, *TABLE* (ASCII table) or *BINTABLE* (binary table).
#### Example:
```
julia> data = [11,21,31,12,22,23,13,23,33];

julia> data = reshape(data,(3,3));

julia> d = cast_FITS_dataobject("image", data)
FITS_dataobject("'IMAGE   '", [11 12 13; 21 22 23; 31 23 33])

julia> d.data
3×3 Matrix{Int64}:
 11  12  13
 21  22  23
 31  23  33

julia> d.hdutype
"'IMAGE   '"
```
"""
function cast_FITS_dataobject(hdutype::String, data)

    hdutype = _format_hdutype(hdutype)

    return FITS_dataobject(hdutype, data)

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
    cast_FITS_header(dataobject::FITS_dataobject)

Create the [`FITS_header`](@ref) object from the dataobject. The 
dataobject-input mode is used by [`fits_create`](@ref) to ceate the header
object as part of creating the [`FITS`](@ref) object starting from Julia data 
input.
#### Example:
```
julia> data = [11 21 31; 12 22 23; 13 23 33];

julia> d = cast_FITS_dataobject("image", data);

julia> h = cast_FITS_header(d);

julia> h.map
Dict{String, Int64} with 7 entries:
  "BITPIX"   => 2
  "NAXIS2"   => 5
  "XTENSION" => 1
  "NAXIS1"   => 4
  ""         => 36
  "NAXIS"    => 3
  "END"      => 6
```
    cast_FITS_header(record::Vector{String})

Create the [`FITS_header`](@ref) object from a block of (a multiple of) 36 
single-record strings (of 80 printable ASCII characters). The record-input mode
is used by [`fits_read`](@ref) after reading the header records from disk 
(see casting diagram above).
#### Example:
```
julia> record = [rpad("KEYWORD$i",8) * "'" * rpad("$i",70) * "'" for i=1:3];

julia> blanks = [repeat(' ', 80) for i = 1:36-length(record)];

julia> append!(record, blanks);   # to conform to the FITS standard

julia> h = cast_FITS_header(record);

julia> h.map
Dict{String, Int64} with 4 entries:
  "KEYWORD3" => 3
  "KEYWORD2" => 2
  "KEYWORD1" => 1
  ""         => 36                                                                '"
```
"""
function cast_FITS_header(dataobject::FITS_dataobject)

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
* `.dataobject`:  the data object (`::FITS_dataobject`)

NB. An empty data block (`.dataobject = nothing`) conforms to the standard.
"""
struct FITS_HDU

    hduindex::Int
    header::FITS_header     # FITS_header
    dataobject::FITS_dataobject   # FITS_dataobject

end
# ------------------------------------------------------------------------------
#             cast_FITS_HDU(hduindex, header, dataobject)
# ------------------------------------------------------------------------------

function _str_table_column(col::Vector{T}, tform::String) where {T}

    strcol = string.(col)
    fmt = cast_FORTRAN_format(tform)
    x = fmt.char
    w = fmt.width
    d = fmt.ndec

    for j ∈ eachindex(col)
        if x == 'I'
            if eltype(col) == Bool
                strcol[j] = col[j] ? "T" : "F"
            end
        elseif x == 'F'
            n = [w - d - 1, d]
            k = findfirst('.', strcol[j])
            s = [strcol[j][1:k-1], strcol[j][k+1:end]]
            Δ = n .- length.(s)
            if Δ[1] > 0
                s[1] = repeat(' ', Δ[1]) * s[1]
            end
            if Δ[2] > 0
                s[2] = s[2] * repeat('0', Δ[2])
            end
            strcol[j] = s[1] * '.' * s[2]
        elseif x == 'E' 
            k = findfirst('.', strcol[j])
            l = findfirst('e', strcol[j])
            s = [strcol[j][1:k-1], strcol[j][k+1:l-1], strcol[j][l+1:end]]
            Δ = d - length(s[2])
            if Δ > 0
                s[2] = s[2] * repeat('0', Δ)
            end
            strcol[j] = s[1] * '.' * s[2] * 'E' * s[3]
        elseif x == 'D'
            k = findfirst('.', strcol[j])
            l = findfirst('e', strcol[j])
            s = [strcol[j][1:k-1], strcol[j][k+1:l-1], strcol[j][l+1:end]]
            Δ = d - length(s[2])
            if Δ > 0
                s[2] = s[2] * repeat('0', Δ)
            end
            strcol[j] = s[1] * '.' * s[2] * 'D' * s[3]
        else
            strcol[j] = strcol[j]
        end
    end

    return strcol

end

@doc raw"""
    cast_FITS_HDU(hduindex::Int, header::FITS_header, data::FITS_dataobject)

Create the [`FITS_HDU`](@ref) object for given `hduindex`, `header` and `data`.

#### Example:
```
julia> data = [11 21 31; 12 22 23; 13 23 33];

julia> d = cast_FITS_dataobject("image", data);

julia> h = cast_FITS_header(d);

julia> hdu = cast_FITS_HDU(1, h, d);

julia> hdu.dataobject.data
3×3 Matrix{Int64}:
 11  21  31
 12  22  23
 13  23  33
```
"""
function cast_FITS_HDU(hduindex::Int, header::FITS_header, dataobject::FITS_dataobject)

    hdutype = dataobject.hdutype
    data = dataobject.data

    if (hdutype == "'TABLE   '") & (eltype(data) ≠ Vector{String})
        # data input as array of table COLUMNS
        col = data
        ncols = length(col)
        nrows = length(col[1])
        
        # make array of table format descriptors Xw.d
        tform = [FORTRAN_fits_table_tform(col[i]) for i ∈ eachindex(col)] 
        
        # convert data to array of fortran strings
        strcol = [_str_table_column(col[i], tform[i]) for i ∈ eachindex(col)]

        # w = required widths of fits data fields
        w = [maximum([length(strcol[i][j]) + 1 for j = 1:nrows]) for i = 1:ncols]

        # transpose matrix and join data into vector of strings
        data = [join([lpad(strcol[i][j], w[i]) for i = 1:ncols]) for j = 1:nrows]
        # data output as Vector{String}
        # this is the Vector{String} of table ROWS (equal-size fields)
        dataobject = FITS_dataobject(hdutype, data)
    end

    return FITS_HDU(hduindex, header, dataobject)

end

# ------------------------------------------------------------------------------
#                               FITS
# ------------------------------------------------------------------------------

@doc raw"""
    FITS

Object to hold a single `.fits` file.

The fields are
* `.filnam:`:  the `.fits` filename (`:String`)
* `.hdu: the collection of header-data-unit objects (`::Vector{FITS_HDU}`)
"""
struct FITS

    filnam::FITS_filnam
    hdu::Vector{FITS_HDU}

end

# ------------------------------------------------------------------------------
#                      cast_FITS(filnam, hdu)
# ------------------------------------------------------------------------------

@doc raw"""
    FITS(filnam::String, hdu::Vector{FITS_HDU})

Object to hold a single `.fits` file.

The fields are
* `.filnam`:  filename of the corresponding `.fits` file (`::String`)
* `.hdu`:  array of [`FITS_HDU`](@ref)s (`::Vector{FITS_HDU}`)
#### Example:
```
julia> data = [11 21 31; 12 22 23; 13 23 33];

julia> d = cast_FITS_dataobject("image", data);

julia> h = cast_FITS_header(d);

julia> hdu = cast_FITS_HDU(1, h, d);

julia> f = cast_FITS("test.fits", [hdu]);

julia> f.hdu[1].dataobject.data
3×3 Matrix{Int64}:
 11  21  31
 12  22  23
 13  23  33
```
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

function _header_record_primary(dataobject::FITS_dataobject)

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
    Base.push!(r, "END                                                                             ")

    _append_blanks!(r)

    return r

end

# ------------------------------------------------------------------------------
#                 _header_record_groups(dataobject)
# ------------------------------------------------------------------------------

function _header_record_groups(dataobject::FITS_dataobject)

    hdutype = dataobject.hdutype
    hdutype == "'GROUPS   '" && error("hdutype $(hdutype) not implemented")

end

# ------------------------------------------------------------------------------
#                 _header_record_image(dataobject)
# ------------------------------------------------------------------------------

function _header_record_image(dataobject::FITS_dataobject)

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
#                  _header_record_table(dataobject)
# ------------------------------------------------------------------------------

function _header_record_table(dataobject::FITS_dataobject)

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

    # make array of table format descriptors Xw.d
    tform = [FORTRAN_fits_table_tform(col[i]) for i ∈ eachindex(col)]
    
    # w = required widths of fits data fields
    w = [cast_FORTRAN_format(tform[i]).width .+ 1 for i ∈ eachindex(col)]
    #####width = [maximum([length(strcol[i][j]) + 1 for j = 1:nrows]) for i = 1:ncols]
    tbcol = [sum(w[1:i-1]) + 1 for i ∈ eachindex(col)]
    lrow = sum(w[i] for i ∈ eachindex(col))

    tform = ["'" * Base.rpad(tform[i], 8) * "'" for i ∈ eachindex(col)]
    tform = [Base.rpad(tform[i], 20) for i ∈ eachindex(col)]
    ttype = ["HEAD$i" for i ∈ eachindex(col)]
    ttype = ["'" * Base.rpad(ttype[i], 18) * "'" for i ∈ eachindex(col)]       # default column headers

    naxis1 = Base.lpad(lrow, 20) 
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
function _table_bindata_types(dataobject::FITS_dataobject)

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

function _header_record_bintable(dataobject::FITS_dataobject) 

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