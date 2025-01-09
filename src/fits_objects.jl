# SPDX-License-Identifier: MIT

# Copyright (c) 2024 Jook Walraven <69215586+walra356@users.noreply.github.com> and contributors

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# ------------------------------------------------------------------------------
#                          fits_objects.jl
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

    strNum = ""
    while Base.Unicode.isdigit(filnam[n])
        strNum = filnam[n] * strNum
        n -= 1
    end
    strPre = filnam[1:n]

    return FITS_filnam(filnam, strNam, strPre, strNum, strExt)

end



# ------------------------------------------------------------------------------
#                                  FITS_pointer
# ------------------------------------------------------------------------------

@doc raw"""
    FITS_pointer

Object holding an array of [`HDU_ptr`](@ref) objects.

The fields are:
* `.nblock`     : block count (`::Int`)                 
* `.nhdu`       : hdu count (`::Int`)     
* `.block_start`: start-of-block pointers: (`::Tuple(Vector{Int})`)  
* ` .block_stop`: end-of-block pointers: (`::Tuple(Vector{Int})`)  
* `  .hdu_start`: start-of-hdu pointers: (`::Tuple(Vector{Int})`)  
* `   .hdu_stop`: end-of-hdu pointers: (`::Tuple(Vector{Int})`)  
* `  .hdr_start`: start-of-header pointers: (`::Tuple(Vector{Int})`)  
* `   .hdr_stop`: end-of-header pointers: (`::Tuple(Vector{Int}))`)  
* ` .data_start`: start-of-data pointers: (`::Tuple(Vector{Int})`)  
* `  .data_stop`: end-of-data pointers: (`::Tuple(Vector{Int})`)  
"""
struct FITS_pointer
    
    nblock::Int
    nhdu::Int
    block_start
    block_stop
    hdu_start
    hdu_stop
    hdr_start
    hdr_stop
    data_start
    data_stop
    
end

# ------------------------------------------------------------------------------
#                            cast_FITS_pointer(o)
# ------------------------------------------------------------------------------
@doc raw"""
    cast_FITS_pointer(o::IO)

Prefered method to construct a [`FITS_pointer`](@ref) object.
#### Example:
```
julia> filnam = "kanweg.fits";

julia> data = [0x0000043e, 0x0000040c, 0x0000041f];

julia> f = fits_create(filnam, data; protect=false);

julia> fits_extend(f, data; hdutype="'IMAGE   '");

julia> fits_extend(f, data; hdutype="'IMAGE   '");

julia> o = IORead(filnam);

julia> p = cast_FITS_pointer(o);

 julia> p.nblock, p.nhdu, p.block_start, p.block_stop, p.hdu_start, p.hdr_stop
 (6, 3, (0, 2880, 5760, 8640, 11520, 14400), (2880, 5760, 8640, 11520, 14400, 17280), (0, 5760, 11520), (2880, 8640, 14400))
    
 julia> p.hdr_start, p.hdr_stop, p.data_start, p.data_stop
 ((0, 5760, 11520), (2880, 8640, 14400), (2880, 8640, 14400), (8640, 14400, 17280))
```
"""
function cast_FITS_pointer(o::IO) #; msg=false)

    seekstart(o)

    nbytes = o.size           # number of bytes
    nblock = nbytes ÷ 2880    # number of blocks 
    remain = nbytes % 2880    # remainder (incomplete block)

    remain > 0 && Base.throw(FITSError(msgErr(6)))

    block_start = [(i - 1) * 2880 for i = 1:nblock]
    block_stop = block_start .+ 2880

    b = block_start
    hdu_start = Int[]
    hdr_stop = Int[]       # h: init start-of-data pointers
    data_stop = Int[]
 # ------------------------------------------------------------------------      
    for i ∈ Base.eachindex(b)
        Base.seek(o, b[i])
        key = String(Base.read(o, 8))
        if key ∈ ["SIMPLE  ", "XTENSION"] 
            Base.push!(hdu_start, b[i])
        end
    end

    nhdu = length(hdu_start)
    hdu_stop = [hdu_start[i] for i = 2:nhdu]
    hdu_stop = append!(hdu_stop, nbytes)
    hdr_start = hdu_start
 # ------------------------------------------------------------------------    
    for i ∈ eachindex(b)         # i: start-of-block pointer (36 records/block)
        Base.seek(o, b[i]) 
        [(key = String(Base.read(o, 8));
          key == "END     " ? Base.push!(hdr_stop, b[i] + 2880) : Base.skip(o, 72)) for j = 0:35]
    end
   
    data_start = hdr_stop
    data_stop = [(hdr_stop[i-1] == hdr_start[i] ? data_start[i-1] : hdr_start[i]) for i=2:nhdu]
    data_stop = append!(data_stop, nbytes)    
 # ------------------------------------------------------------------------  
    
    a = nblock
    b = nhdu
    c = block_start
    d = block_stop
    e = hdu_start
    f = hdr_stop
    g = hdr_start
    h = hdr_stop
    i = data_start
    j = data_stop

    return FITS_pointer(a, b, Tuple(c), Tuple(d), Tuple(e), Tuple(f), Tuple(g), Tuple(h), Tuple(i), Tuple(j))

end

# ------------------------------------------------------------------------------
#                                  Ptrs
# ------------------------------------------------------------------------------

@doc raw"""
    Ptrs

Pointer object holding `start`` and `stop`` values for reading/writing `IOStream`.

The fields are:
* `.start`:  start_of_IOStream (`::Int`)
* ` .stop`:   end_of_IOStream (`::Int`)
"""
struct Ptrs

    start::Int
    stop::Int
    
end

# ------------------------------------------------------------------------------
#                                  HDU_ptr
# ------------------------------------------------------------------------------

@doc raw"""
    HDU_ptr

Object holding `header` and `data` [`Ptrs`](@ref) objects.

The fields are:
* `.header`:  IO pointing object (`::Ptrs`)
* `  .data`:  IO data object (`::Ptrs`)
"""
struct HDU_ptr

    header::Ptrs
    data::Ptrs
    
end

# ------------------------------------------------------------------------------
#                                  FITS_ptr
# ------------------------------------------------------------------------------

@doc raw"""
    FITS_ptr

Object holding an array of [`HDU_ptr`](@ref) objects.

It has a single field:
* `.hdu`:  IO pointing object (`::Vector{HDU_ptr}`)
"""
struct FITS_ptr
        
    hdu::Vector{HDU_ptr}

end

# ------------------------------------------------------------------------------
#                            cast_FITS_ptr(o; msg=false)
#                            cast_FITS_ptr(p::FITS_pointer)
# ------------------------------------------------------------------------------

@doc raw"""
    cast_FITS_ptr(o::IO [; msg=false])
    cast_FITS_ptr(p::FITS_pointer)

Prefered method to construct a [`FITS_ptr`](@ref) object.
#### Example:
```
julia> filnam = "kanweg.fits";
julia> data = [0x0000043e, 0x0000040c, 0x0000041f];
julia> f = fits_create(filnam, data; protect=false);
julia> fits_extend(f, data; hdutype="'IMAGE   '");
julia> fits_extend(f, data; hdutype="'IMAGE   '");
julia> o = IORead(filnam);

julia> ptr = cast_FITS_ptr(o; msg=true)
             block count: 6
               hdu count: 3
 start-of-block pointers: [0, 2880, 5760, 8640, 11520, 14400]
   end-of-block pointers: [2880, 5760, 8640, 11520, 14400, 17280]
   start-of-hdu pointers: [0, 5760, 11520]
     end-of-hdu pointers: [5760, 11520, 17280]
start-of-header pointers: [0, 5760, 11520]
  end-of-header pointers: [2880, 8640, 14400]
  start-of-data pointers: [2880, 8640, 14400]
    end-of-data pointers: [8640, 14400, 17280]

FITS_ptr(HDU_ptr[HDU_ptr(Ptrs(0, 2880), Ptrs(2880, 8640)), HDU_ptr(Ptrs(5760, 8640), Ptrs(8640, 14400)), HDU_ptr(Ptrs(11520, 14400), Ptrs(14400, 17280))])

julia> p.hdu[2].header.start, p.hdu[2].data.start
(5760, 8640)
```
"""
function cast_FITS_ptr(o::IO)

    p = cast_FITS_pointer(o)

    return cast_FITS_ptr(p)

end
function cast_FITS_ptr(p::FITS_pointer)

    h1 = p.hdr_start
    h2 = p.hdr_stop
    d1 = p.data_start
    d2 = p.data_stop

    return FITS_ptr( [HDU_ptr( Ptrs(h1[i], h2[i]), Ptrs(d1[i], d2[i]) ) for i=1:p.nhdu] )

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
    val = record[9:10] ≠ "= " ? record[11:31] : _fits_parse(cardindex, record[11:31])
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
* `.size`: length in bytes (`::Int`)
"""
struct FITS_header

    card::Vector{FITS_card}
    map::Dict{String,Int}
    size::Int

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

julia> append!(record, blanks);         # to conform to the FITS standard

julia> h = cast_FITS_header(record);

julia> h.map
Dict{String, Int64} with 4 entries:
  "KEYWORD3" => 3
  "KEYWORD2" => 2
  "KEYWORD1" => 144
  ""         => 36
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

    nbytes = 80length(record)
    remain = nbytes % 2880
 
    # FITSError 8: fails mandatory integer number of blocks
    iszero(remain) || Base.throw(FITSError(msgErr(8)))

    card = [cast_FITS_card(i, record[i]) for i ∈ eachindex(record)]
    map = Dict([Base.strip(record[i][1:8]) => i for i ∈ eachindex(record)])

    return FITS_header(card, map, nbytes)

end
function cast_FITS_header(card::Vector{FITS_card})
    
    map = Dict([card[i].keyword => i for i ∈ eachindex(card)])
    size = 80length(card)

    return FITS_header(card, map, size)

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
    card = header.card

    if (hdutype == "'TABLE   '") & (eltype(data) ≠ Vector{String})

        # data input as array of table COLUMNS
        col = data
        map = header.map
        nrows = length(data)
        tfields = length(data[1])

        # make array of table format descriptors Xw.d
        cardindex = [max(get(map, "TDISP$i", 0), map["TFORM$i"]) for i = 1:tfields]
        tdisp = [strip(card[cardindex[i]].value, ['\'', ' ']) for i = 1:tfields]
        tdisp = string.(tdisp)

        # convert data to array of fortran strings
        strcol = [FORTRAN_fits_table_string(data[i], tdisp) for i = 1:nrows]

        # w = required widths of fits data fields
        w = [maximum([length(strcol[i][j]) + 1 for i = 1:nrows]) for j = 1:tfields]

        # transpose matrix and join data into vector of strings
        data = [join([lpad(strcol[i][j], w[j]) for j = 1:tfields]) for i = 1:nrows]
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
    bzero = fits_zero_offset(T)
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
    if strip(bzero) ≠ "0.0"
        Base.push!(r, "BSCALE  =                  1.0 / default scaling factor                         ")
        Base.push!(r, "BZERO   = " * bzero * " / offset data range to that of unsigned integer  ")
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
    ndims ≤ 3 || Base.throw(FITSError(msgErr(38)))
    dims = Base.size(data)
    nbyte = T ≠ Any ? Base.sizeof(T) : 8
    nbits = 8 * nbyte
    bzero = fits_zero_offset(T)
    bitpix = T <: AbstractFloat ? -abs(nbits) : nbits

    bitpix = Base.lpad(bitpix, 20)
    naxis = Base.lpad(ndims, 20)
    dims = [Base.lpad(dims[i], 20) for i ∈ eachindex(dims)]
    bzero = Base.lpad(bzero, 20)

    r::Vector{String} = []

    Base.push!(r, "XTENSION= 'IMAGE   '           / FITS standard extension                        ")
    Base.push!(r, "BITPIX  = " * bitpix * " / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   = " * naxis * " / number of data axes                            ")
    for i = 1:ndims
        Base.push!(r, "NAXIS$i  = " * dims[i] * " / length of data axis " * rpad(i, 27))
    end
    if strip(bzero) ≠ "0.0"
        Base.push!(r, "BZERO   = " * bzero * " / offset data range to that of unsigned integer  ")
        Base.push!(r, "BSCALE  =                  1.0 / default scaling factor                         ")
    end
    Base.push!(r, "END                                                                             ")

    _append_blanks!(r)

    return r

end

# ------------------------------------------------------------------------------
#                  _fits_table_form(col)
# ------------------------------------------------------------------------------

function _fits_table_form(col::Vector{T}) where {T} 


    x = FORTRAN_eltype_char(T)
    x ≠ '-' || Base.throw(FITSError(msgErr(40)))

    x = x ∈ ('L', 'B', 'I', 'J', 'K') ? 'I' :
        (x ∈ ['E', 'D']) & ('e' ∉ string(col[1])) ? 'F' : x

    if x == 'I' # NB. hdutype 'table' does not accept the 'L' descriptor
        if T == Bool
            tform = "I1"
        else
            strcol = string.(col)
            w = maximum(length.(strcol))
            tform = x * string(w)
        end
    elseif x == 'F'
        strcol = string.(col)
        n = [0, 0]
        for i ∈ eachindex(col)
            k = findfirst('.', strcol[i])
            s = [strcol[i][1:k-1], strcol[i][k+1:end]]
            m = length.(s)
            n = max.(n, m)
        end
        w = 1 + sum(n)
        d = n[2]
        tform = x * string(w) * '.' * string(d)
    elseif x ∈ ('E', 'D')
        strcol = string.(col)
        n = [0, 0, 0]
        for i ∈ eachindex(col)
            k = findfirst('.', strcol[i])
            l = findfirst('e', strcol[i])
            s = [strcol[i][1:k-1], strcol[i][k+1:l-1], strcol[i][l+1:end]]
            m = length.(s)
            n = max.(n, m)
        end
        w = 2 + sum(n)
        d = n[2]
        tform = x * string(w) * '.' * string(d)
    elseif x == 'A'
        strcol = string.(col)
        w = T == Char ? 1 : maximum(length.(strcol))
        tform = x * string(w)
    end

    return tform

end

# ------------------------------------------------------------------------------
#                  _header_record_table(dataobject)
# ------------------------------------------------------------------------------
function _header_record_table(dataobject::FITS_dataobject)

    hdutype = dataobject.hdutype
    hdutype == "'TABLE   '" || Base.throw(FITSError(msgErr(30)))
    data = dataobject.data

    # data input as Any array of table COLUMNS
    nrows = length(data) # number of rows in table
    tfields = length(data[1]) # number of fields in table
    tfields > 0 || Base.throw(FITSError(msgErr(34)))
    tfields ≤ 999 || Base.throw(FITSError(msgErr(32)))

    # test equal row length
    equal = [tfields .== length(data[i]) for i = 1:nrows]
    equal = sum(equal) ÷ nrows == 1
    equal || Base.throw(FITSError(msgErr(33)))

    # test equal row type
    T = [eltype.(data[i]) for i = 1:nrows]
    equal = [T[1] .== T[i] for i = 1:nrows]
    equal = [sum(equal[i]) ÷ tfields for i = 1:nrows]
    equal = sum(equal) ÷ nrows == 1
    equal || Base.throw(FITSError(msgErr(46)))

    # make array of table format descriptors Xw.d
    tform = [_fits_table_form([data[i][j] for i = 1:nrows]) for j = 1:tfields]
    tzero = Any[fits_zero_offset(T[1][j]) for j = 1:tfields]

    # w = required widths of fits data fields
    w = [cast_FORTRAN_format(tform[j]).width .+ 1 for j = 1:tfields]
    tbcol = [sum(w[1:i-1]) + 1 for i = 1:tfields]
    lrow = sum(w[i] for i = 1:tfields)

    tform = ["'" * Base.rpad(tform[i], 8) * "'" for i = 1:tfields]
    tform = [Base.rpad(tform[i], 20) for i = 1:tfields]
    ttype = ["HEAD$i" for i = 1:tfields]
    ttype = ["'" * Base.rpad(ttype[i], 18) * "'" for i = 1:tfields]  # default column headers

    naxis1 = Base.lpad(lrow, 20)
    naxis2 = Base.lpad(nrows, 20)
    tbcol = [Base.lpad(tbcol[i], 20) for i = 1:tfields]
    tzero = [Base.lpad(tzero[i], 20) for i = 1:tfields]

    ncols = Base.lpad(tfields, 20)

    r::Array{String,1} = []

    Base.push!(r, "XTENSION= 'TABLE   '           / FITS standard extension                        ")
    Base.push!(r, "BITPIX  =                    8 / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   =                    2 / number of data axes                            ")
    Base.push!(r, "NAXIS1  = " * naxis1 * " / number of bytes/row                            ")
    Base.push!(r, "NAXIS2  = " * naxis2 * " / number of rows                                 ")
    Base.push!(r, "PCOUNT  =                    0 / number of bytes in supplemetal data area       ")
    Base.push!(r, "GCOUNT  =                    1 / data blocks contain single table               ")
    Base.push!(r, "TFIELDS = " * ncols * " / number of data fields (columns)                ")
    Base.push!(r, "COLSEP  =                    1 / number of spaces in column separator           ")

    for j = 1:tfields
        Base.push!(r, repeat(' ', 80))
        Base.push!(r, rpad("TTYPE$j", 8) * "= " * ttype[j] * rpad(" / field header", 50))
        Base.push!(r, rpad("TBCOL$j", 8) * "= " * tbcol[j] * rpad(" / pointer to field column $j", 50))
        Base.push!(r, rpad("TFORM$j", 8) * "= " * tform[j] * rpad(" / field datatype specifier", 50))
        Base.push!(r, rpad("TDISP$j", 8) * "= " * tform[j] * rpad(" / proposed field display format", 50))
        if strip(tzero[j]) ∉ ("0.0", "nothing")
            Base.push!(r, rpad("TZERO$j", 8) * "= " * tzero[j] * rpad(" / zero offset of field $j", 50))
            Base.push!(r, rpad("TSCAL$j", 8) * "=                  1.0" * rpad(" / scale factor of field $j", 50)) 
        end
    end

    tfields > 0 ? Base.push!(r, repeat(' ', 80)) : false

    Base.push!(r, "END" * repeat(' ', 77))

    pass = sum(length.(r) .- 80) == false

    pass || println("length table_data records: ", [length.(r)])

    _append_blanks!(r)

    return r

end


# ==============================================================================
#                  _header_record_bintable(dataobject)
# ------------------------------------------------------------------------------

struct FITS_array

    value
    length
    byte_offset

end
# ------------------------------------------------------------------------------
function cast_FITS_array(arr::Array)

    value = arr
    length = length(arr)
    offset = sizeof(arr)

    return variable_length_array(value, length, offset)

end
# ------------------------------------------------------------------------------
struct _bintable_field

    value::Any
    type::Type
    eltype::Type
    repeat::Int
    char::Union{Char, String}
    tdisp::Union{Nothing,String}
    nbyte::Int
    tzero::Union{Nothing, Integer}
    dims::Union{Nothing, Tuple}

end
# ------------------------------------------------------------------------------
function cast_bintable_field(field)

    T = typeof(field)
    t = eltype(field)

    if (t == BitVector) ⊻ (T == BitVector)
        r = T == BitVector ? 1 : length(field)
        X = 'X'
        nbyte = sizeof(t)
        tdisp = X * string(r)
        tzero = nothing
        tdims = T <: Tuple ? nothing : r > 1 ? size(field) : nothing 
    elseif t <: Char
        r = length(field)
        X = 'A'
        nbyte = r
        tdisp = X * string(r)
        tzero = nothing
        tdims = T <: Array ? size(field) : nothing
    elseif t <: String
        error("Error: $(field) invalid datatype - use \"$(join(field))\")")
    elseif t <: Tuple{String}
        error("Error: $(field) invalid datatype - use \"$(join(field))\")")
    elseif t <: Integer
        r = length(field)
        X = t == Bool  ? 'L' :
            t == Int8  ? 'B' : t == UInt8 ? 'B' :
            t == Int16 ? 'I' : t == UInt16 ? 'I' :
            t == Int32 ? 'J' : t == UInt32 ? 'J' :
            t == Int64 ? 'K' : t == UInt64 ? 'K' : '-'
        nbyte = r * sizeof(t)
        tdisp = X * string(length(string(typemax(t))))
        tzero = _tzero_value(t)
        tdims = T <: Tuple ? nothing : r > 1 ? size(field) : nothing 
    elseif t <: Real
        r = length(field)
        X = t == Float32 ? 'E' : t == Float64 ? 'D' : '-'
        f = T <: Array{} ? (r > 0 ? field[1] : field) : field
        v = string(f)
        w = string(length(v))
        Y = (('e' ∉ v) & ('p' ∉ v)) ? 'F' : X
        v = 'e' ∈ v ? split(v, 'e')[1] : 'p' ∈ v ? split(v, 'p')[1] : v
        d = !isnothing(findfirst('.', v)) ? string(length(split(v, '.')[2])) : '0'
        nbyte = r * sizeof(t)
        tdisp = Y * w * '.' * d
        tzero = nothing
        tdims = T <: Tuple ? nothing : r > 1 ? size(field) : nothing
    elseif t <: Complex
        r = length(field)
        X = t == ComplexF32 ? 'C' : t == ComplexF64 ? 'M' : '-'
        nbyte = r * sizeof(t)
        tdisp = nothing
        tzero = nothing
        tdims = T <: Tuple ? nothing : r > 1 ? size(field) : nothing
    else
        r = 0
        X = '-'
        nbyte = 0
        tdims = tzero = tdisp = nothing
    end
    
    X ≠ '-' || error("$t: datatype not part of the FITS standard")

    o = _bintable_field(field, T, t, r, X, tdisp, nbyte, tzero, tdims)
   
    return o

end
# ------------------------------------------------------------------------------
function _tzero_value(T::Type)

    T ∈ (Int8, UInt16, UInt32, UInt64) || return nothing

    T == Int8 && return 128
    T == UInt16 && return 32768
    T == UInt32 && return 2147483648
    T == UInt64 && return 9223372036854775808

    # note workaround for InexactError:trunc(Int64, 9223372036854775808)

end
# ------------------------------------------------------------------------------
function _header_record_bintable(dataobject::FITS_dataobject)

    hdutype = dataobject.hdutype
    hdutype == "'BINTABLE'" || Base.throw(FITSError(msgErr(31)))
    data = dataobject.data

    nrows = length(data)
    tfields = length(data[1]) # number of rows in table (= columns in data)
    tfields > 0 || Base.throw(FITSError(msgErr(34)))
    tfields ≤ 999 || Base.throw(FITSError(msgErr(32)))

    ttype = []; tform = []; tdims = []; tdisp = []; tzero = []; nbyte = []
    for j = 1:tfields
        field = cast_bintable_field(data[1][j])
        r = string(field.repeat)
        T = field.type
        X = T <: Tuple ? field.char * "tuple" : field.char
        push!(ttype, "'" * Base.rpad("HEAD$j", 8) * "'")
        push!(tform, "'" * Base.rpad(r * X, 8) * "'")
        push!(tdisp, "'" * Base.rpad(field.tdisp, 8) * "'")
        push!(tdims, "'" * Base.rpad(field.dims, 8) * "'")
        push!(tzero, field.tzero)
        push!(nbyte, field.nbyte)
    end

    for j = 1:tfields
        r = 0
        if typeof(data[1][j]) == String
            for i = 1:nrows
                d = data[i][j]
                ℓ = length(d)
                r = ℓ > r ? ℓ : r
            end
            for i = 1:nrows
                d = data[i][j]
                data[i][j] = lpad(d, r)
            end
            tform[j] = "'" * Base.rpad(string(r) * 'A', 8) * "'"
        end
    end

    tfield = Base.lpad(tfields, 20)
    naxis1 = Base.lpad(sum(nbyte), 20)
    naxis2 = Base.lpad(nrows, 20)

    tform = [Base.rpad(tform[j], 20) for j = 1:tfields]
    tdisp = [Base.rpad(tdisp[j], 20) for j = 1:tfields]
    ttype = [Base.rpad(ttype[j], 20) for j = 1:tfields]
    tzero = [Base.rpad(tzero[j], 20) for j = 1:tfields]
    tdims = [Base.rpad(tdims[j], 20) for j = 1:tfields]

    r = String[]

    Base.push!(r, "XTENSION= 'BINTABLE'           / FITS standard extension                        ")
    Base.push!(r, "BITPIX  =                    8 / number of bits per data pixel                  ")
    Base.push!(r, "NAXIS   =                    2 / number of data axes                            ")
    Base.push!(r, "NAXIS1  = " * naxis1 * " / number of bytes/row                            ")
    Base.push!(r, "NAXIS2  = " * naxis2 * " / number of rows                                 ")
    Base.push!(r, "PCOUNT  =                    0 / number of bytes in supplemetal data area       ")
    Base.push!(r, "GCOUNT  =                    1 / data blocks contain single table               ")
    Base.push!(r, "TFIELDS = " * tfield * rpad(" / number of data fields (columns)", 50))

    for j = 1:tfields
        Base.push!(r, repeat(' ', 80))
        Base.push!(r, rpad("TTYPE$j", 8) * "= " * ttype[j] * rpad(" / field header", 50))
        Base.push!(r, rpad("TFORM$j", 8) * "= " * tform[j] * rpad(" / field datatype specifier", 50))
        if strip(tdisp[j], ['\'', ' ']) ≠ "nothing"
            #Base.push!(r, rpad("TDISP$j", 8) * "= " * tdisp[j] * rpad(" / proposed field display format", 50))
        end
        if strip(tdims[j], ['\'', ' ']) ≠ "nothing"
            Base.push!(r, rpad("TDIM$j", 8) * "= " * tdims[j] * rpad(" / array dimensions of field $j", 50))
        end
        if strip(tzero[j], ['\'', ' ']) ≠ "nothing"
            Base.push!(r, rpad("TZERO$j", 8) * "= " * tzero[j] * rpad(" / zero offset of field $j", 50))
            Base.push!(r, rpad("TSCAL$j", 8) * "=                  1.0" * rpad(" / scale factor of field $j", 50))
        end
    end

    tfields > 0 ? Base.push!(r, repeat(' ', 80)) : false
    
    Base.push!(r, "END" * repeat(' ', 77))

    pass = sum(length.(r) .- 80) == false

    pass || println("length table_data records: ", [length.(r)])

    _append_blanks!(r)

    return r

end