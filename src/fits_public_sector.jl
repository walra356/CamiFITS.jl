# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                          fits_public_sector.jl
#                         Jook Walraven 21-03-2023
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                   fits_info(f::FITS, hduindex=1; msg=true)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_info(f::FITS [, hduindex=1 [; msg=true]])

Metafinformation and data as loaded from `f.hdu[hduindex]`; i.e.,
*after casting of the FITS object*.

* `hduindex`: HDU index (::Int - default: `1` = `primary hdu`)
* `msg`: print message (::Bool)
#### Example:
```
julia> filnam = "minimal.fits";

julia> f = fits_create(filnam; protect=false);

julia> fits_info(f)
File: minimal.fits
hdu: 1
hdutype: PRIMARY
DataType: Any
Datasize: (0,)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
BITPIX  =                   64 / number of bits per data pixel
NAXIS   =                    1 / number of data axes
NAXIS1  =                    0 / length of data axis 1
BZERO   =                  0.0 / offset data range to that of unsigned integer  
BSCALE  =                  1.0 / default scaling factor
EXTEND  =                    T / FITS dataset may contain extensions
COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/
END

Any[]

julia> rm(filnam); f = nothing
```
    fits_info(filnam::String [, hduindex=1 [; nr=true [, msg=true]]])

Metafinformation of the specified FITS HDU as loaded from `filnam`; i.e., 
*without casting of the FITS object*.

* `hduindex`: HDU index (::Int - default: `1` = `primary hdu`)
* `nr`: include cardindex (::Bool - default: `true`)
* `msg`: print message (::Bool)
#### Example:
```
julia> filnam = "minimal.fits";

julia> fits_info(filnam)

File: minimal.fits
hdu: 1

nr  Metainformation:
1   SIMPLE  =                    T / file does conform to FITS standard
2   BITPIX  =                   64 / number of bits per data pixel
3   NAXIS   =                    1 / number of data axes
4   NAXIS1  =                    0 / length of data axis 1
5   BZERO   =                  0.0 / offset data range to that of unsigned integer
6   BSCALE  =                  1.0 / default scaling factor
7   EXTEND  =                    T / FITS dataset may contain extensions
8   COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/
9   END
10
11
12
⋮
34
35
36

julia> rm(filnam); f = nothing
```
"""
function fits_info(f::FITS, hduindex=1; msg=true)

    str = "\nFile: " * f.filnam.value
    msg && println(str)

    return fits_info(f.hdu[hduindex]; msg)

end
function fits_info(hdu::FITS_HDU; msg=true)

    typeof(hdu) <: FITS_HDU || error("FitsWarning: FITS_HDU not found")

    strDataType = Base.string(Base.eltype(hdu.dataobject.data))
    strDatasize = Base.string(Base.size(hdu.dataobject.data))

    str = [
        "hdu: " * Base.string(hdu.hduindex),
        "hdutype: " * hdu.dataobject.hdutype,
        "DataType: " * strDataType,
        "Datasize: " * strDatasize,
        "\r\nMetainformation:"
    ]

    card = hdu.header.card

    records = [card[i].record for i ∈ eachindex(card)]

    _rm_blanks!(records)

    Base.append!(str, records)

    msg && println(Base.join(str .* "\r\n"))

    return hdu.dataobject.data

end
function fits_info(filnam::String, hduindex=1; nr=true, msg=true)

    o = IORead(filnam)

    Base.seekstart(o)

    record = _read_header(o, hduindex)

    Base.seekstart(o)

    str = "\nFile: " * filnam * "\n"
    str *= "hdu: " * string(hduindex) * "\n\n"
    str *= nr ? "nr  " : ""
    str *= "Metainformation:\n"
    for i ∈ eachindex(record.card)
        str *= nr ? rpad("$i", 4) : ""
        str *= record.card[i].record * "\n"
    end

    msg && println(str)

    dataobject = _read_data(o, hduindex)

    return dataobject.data

end

# ------------------------------------------------------------------------------
#       fits_record_dump(filnam::String, hduindex=0; hdr=true, dat=true, nr=true)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_record_dump(filnam [, hduindex=0 [; hdr=true [, dat=true [, nr=true]]]])

Metafinformation and data as loaded from `f.hdu[hduindex]`; i.e.,
*after casting of the FITS object*.

* `hduindex`: HDU index (::Int - default: `1` = `primary hdu`)
* `hdr`: show header (::Bool - default: true)
* `dat`: show data (::Bool - default: true)
* `nr`: include record numbers (::Bool - default: true)
#### Example:
```
julia> filnam = "minimal.fits";

julia> data = [0x0000043e, 0x0000040c, 0x0000041f];

julia> fits_create(filnam, data; protect=false);

julia> fits_record_dump(filnam; dat=false)
36-element Vector{Any}:
 (1, "SIMPLE  =                    T / file does conform to FITS standard             ")
 (2, "BITPIX  =                   32 / number of bits per data pixel                  ")
 (3, "NAXIS   =                    1 / number of data axes                            ")
 (4, "NAXIS1  =                    3 / length of data axis 1                          ")
 (5, "BZERO   =           2147483648 / offset data range to that of unsigned integer  ")
 (6, "BSCALE  =                  1.0 / default scaling factor                         ")
 (7, "EXTEND  =                    T / FITS dataset may contain extensions            ")
 (8, "COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/                     ")
 (9, "END                                                                             ")
 (10, "                                                                                ")
 (11, "                                                                                ")
 (12, "                                                                                ")
 ⋮
 (34, "                                                                                ")
 (35, "                                                                                ")
 (36, "                                                                                ")

julia> fits_record_dump(filnam; hdr=false)
36-element Vector{Any}:
 (37, "\x80\0\x04>\x80\0\x04\f\x80\0\x04\x1f\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0")
 (38, "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0")
 (39, "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0")
 (40, "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0")
 ⋮
 (70, "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0")
 (71, "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0")
 (72, "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0")

julia> rm(filnam); f = nothing
```
"""
function fits_record_dump(filnam::String, hduindex=0; hdr=true, dat=true, nr=true)

    o = IORead(filnam)

    hduval = hduindex
    ptrhdu = _hdu_pointer(o)
    ptrdat = _data_pointer(o)
    ptrend = _end_pointer(o)

    record = []
    for hduindex ∈ eachindex(ptrhdu)
        if (hduindex == hduval) ⊻ iszero(hduval)
            if hdr
                Base.seek(o, ptrhdu[hduindex])
                for ptr = (ptrhdu[hduindex]÷80+1):(ptrdat[hduindex]÷80)
                    str = String(Base.read(o, 80))
                    rec = nr ? (ptr, str) : str
                    push!(record, rec)
                end
            end
            if dat
                Base.seek(o, ptrdat[hduindex])
                for ptr = (ptrdat[hduindex]÷80+1):(ptrend[hduindex]÷80)
                    str = String(Base.read(o, 80))
                    rec = nr ? (ptr, str) : str
                    push!(record, rec)
                end
            end
        end
    end

    record = record == [] ? nothing : record
    
    return record

end

# ------------------------------------------------------------------------------
#                 fits_create(filnam [, data [; protect=true]])
# ------------------------------------------------------------------------------

@doc raw"""
    fits_create(filnam [, data [; protect=true]])

Create `.fits` file of given filnam and return Array of HDUs.
Key:
* `data`: data primary hdu (::DataType)
* `protect`: overwrite protection (::Bool)
#### Examples:
```
julia> data = [11,21,31,12,22,23,13,23,33];

julia> data = reshape(data,(3,3,1))
3×3×1 Array{Int64, 3}:
[:, :, 1] =
 11  12  13
 21  22  23
 31  23  33

julia> f = fits_create("minimal.fits", data; protect=false);

julia> fits_info(f)

File: minimal.fits
hdu: 1
hdutype: PRIMARY
DataType: Int64
Datasize: (3, 3, 1)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
BITPIX  =                   64 / number of bits per data pixel
NAXIS   =                    3 / number of data axes
NAXIS1  =                    3 / length of data axis 1
NAXIS2  =                    3 / length of data axis 2
NAXIS3  =                    1 / length of data axis 3
BZERO   =                  0.0 / offset data range to that of unsigned integer
BSCALE  =                  1.0 / default scaling factor
EXTEND  =                    T / FITS dataset may contain extensions
COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/
END

3×3×1 Array{Int64, 3}:
[:, :, 1] =
 11  12  13
 21  22  23
 31  23  33

julia> rm("minimal.fits"); f = nothing
```
"""
function fits_create(filnam::String, data=[]; protect=true)

    if Base.Filesystem.isfile(filnam) & protect
        Base.throw(FITSError(msgErr(4)))
    end

    hduindex = 1
    dataobject = cast_FITS_data("'PRIMARY '", data)
    header = cast_FITS_header(dataobject)
    hdu = cast_FITS_HDU(hduindex, header, dataobject)

    f = cast_FITS(filnam, [hdu])

    fits_save(f)

    return f

end

# ------------------------------------------------------------------------------
#                     fits_read(filnam::String)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_read(filnam::String)

Read `.fits` file and return Array of `FITS_HDU`s
#### Example:
```
julia> filnam = "minimal.fits";

julia> fits_create(filnam; protect=false);

julia> f = fits_read(filnam);

julia> fits_info(f)
hdu: 1
hdutype: PRIMARY
DataType: Any
Datasize: (0,)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
BITPIX  =                   64 / number of bits per data pixel
NAXIS   =                    1 / number of data axes
NAXIS1  =                    0 / length of data axis 1
BZERO   =                  0.0 / offset data range to that of unsigned integer
BSCALE  =                  1.0 / default scaling factor
EXTEND  =                    T / FITS dataset may contain extensions
COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/
END

Any[]

julia> rm(filnam); f = nothing
```
"""
function fits_read(filnam::String)

    o = IORead(filnam)

    nhdu = _hdu_count(o)

    Base.seekstart(o)

    rec = [_read_header(o::IO, i) for i = 1:nhdu]
    
    Base.seekstart(o)
    
    dat = [_read_data(o, i) for i = 1:nhdu]
    hdu = [cast_FITS_HDU(i, rec[i], dat[i]) for i = 1:nhdu]

    f = cast_FITS(filnam, hdu)

    return f

end

# ------------------------------------------------------------------------------
#           fits_extend!(f::FITS, data_extend [; hdutype="IMAGE"])
# ------------------------------------------------------------------------------

@doc raw"""
    fits_extend!(f::FITS, data_extend; hdutype="IMAGE")

Extend the `.fits` file of given filnam with the data of `hdutype` from `data_extend`  and return Array of HDUs.
#### Examples:
```
julia> filnam = "test_example.fits";

julia> data = [0x0000043e, 0x0000040c, 0x0000041f];

julia> f = fits_create(filnam, data; protect=false);

julia> a = Float16[1.01E-6,2.0E-6,3.0E-6,4.0E-6,5.0E-6];

julia> b = [0x0000043e, 0x0000040c, 0x0000041f, 0x0000042e, 0x0000042f];

julia> c = [1.23,2.12,3.,4.,5.];

julia> d = ['a','b','c','d','e'];

julia> e = ["a","bb","ccc","dddd","ABCeeaeeEEEEEEEEEEEE"];

julia> data = [a,b,c,d,e];

julia> fits_extend!(f, data; hdutype="TABLE")


julia> f.hdu[2].dataobject.data
  5-element Vector{String}:
   "1.0e-6 1086 1.23 a a                    "
   "2.0e-6 1036 2.12 b bb                   "
   "3.0e-6 1055 3.0  c ccc                  "
   "4.0e-6 1070 4.0  d dddd                 "
   "5.0e-6 1071 5.0  e ABCeeaeeEEEEEEEEEEEE "

rm(strExample); f = data = a = b = c = d = e = nothing
```
"""
function fits_extend!(f::FITS, data_extend; hdutype="IMAGE")

    hdutype = _format_hdutype(hdutype)
    hduindex = length(f.hdu) + 1
    dataobject = cast_FITS_data(hdutype, data_extend)
    header = cast_FITS_header(dataobject)

    push!(f.hdu, cast_FITS_HDU(hduindex, header, dataobject))

    fits_save(f)

    return f

end

# ------------------------------------------------------------------------------
#              fits_add_key!(f, hduindex, key, val, com)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_add_key!(f::FITS, hduindex::Int, key::String, val::Any, com::String)

Add a header record of given 'key, value and comment' to 'HDU[hduindex]' of file with name 'filnam'
#### Example:
```
julia> filnam = "minimal.fits";

julia> f = fits_create(filnam; protect=false);

julia> fits_add_key!(f, 1, "KEYNEW1", true, "FITS dataset may contain extension");

julia> fits_info(f)

File: minimal.fits
hdu: 1
hdutype: 'PRIMARY '
DataType: Any
Datasize: (0,)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
BITPIX  =                   64 / number of bits per data pixel
NAXIS   =                    1 / number of data axes
NAXIS1  =                    0 / length of data axis 1
BZERO   =                  0.0 / offset data range to that of unsigned integer
BSCALE  =                  1.0 / default scaling factor
EXTEND  =                    T / FITS dataset may contain extensions
COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/
KEYNEW1 =                    T / FITS dataset may contain extension
END

Any[]
```
"""
function fits_add_key!(f::FITS, hduindex::Int, key::String, val::Any, com::String)

    k = get(f.hdu[hduindex].header.map, _format_keyword(key), 0)
    k > 0 && Base.throw(FITSError(msgErr(7)))        # " keyword in use

    k = get(f.hdu[hduindex].header.map, "END", 0)
    k > 0 || Base.throw(FITSError(msgErr(13)))       # "END keyword not found

    n = f.hdu[hduindex].header.card[end].cardindex

    rec = _format_record(key, val, com)
    nrec = length(rec)
    nadd = (nrec - n + k + 35) ÷ (36)

    if nadd > 0
        blanks = repeat(' ', 80)
        block = [cast_FITS_card(n + i, blanks) for i = 1:(36*nadd)]
        append!(f.hdu[hduindex].header.card, block)
    end

    for i = 0:nrec-1
        card = cast_FITS_card(k + i, rec[1+i])
        f.hdu[hduindex].header.card[k+i] = card
    end
    endrec = "END" * repeat(' ', 77)
    f.hdu[hduindex].header.card[k+nrec] = cast_FITS_card(k + nrec, endrec)

    card = f.hdu[hduindex].header.card
    map = Dict([card[i].keyword => i for i ∈ eachindex(card)])

    dataobject = f.hdu[hduindex].dataobject
    header = FITS_header(card, map)
    f.hdu[hduindex] = cast_FITS_HDU(hduindex, header, dataobject)

    fits_save(f)

    return f

end

# ------------------------------------------------------------------------------
#                  fits_delete_key!(f, hduindex, key)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_delete_key!(f::FITS, hduindex::Int, key::String)

Delete a header record of given `key`, `value` and `comment` to `FITS_HDU[hduindex]` of file with name  'filnam'
#### Examples:
```
julia> filnam = "minimal.fits";

julia> f = fits_create(filnam; protect=false);

julia> fits_add_key!(f, 1, "KEYNEW1", true, "this is record 5");

julia> cardindex = get(f.hdu[1].header.map,"KEYNEW1", nothing)
9

julia> keyword = f.hdu[1].header.card[cardindex].keyword
"KEYNEW1"

julia> cardindex = get(f.hdu[1].header.map,"KEYNEW1", nothing)
9

julia> fits_delete_key!(f, 1, "KEYNEW1");

julia> cardindex = get(f.hdu[1].header.map,"KEYNEW1", nothing)

julia> fits_delete_key!(f, 1, "NAXIS");
ERROR: FITSError: 17 - illegal keyword deletion (mandatory keyword)
Stacktrace:
 [1] fits_delete_key!(f::FITS, hduindex::Int64, key::String)
   @ CamiFITS c:\Users\walra\.julia\dev\CamiFITS.jl\src\fits_public_sector.jl:495
 [2] top-level scope
   @ REPL[24]:1
```
"""
function fits_delete_key!(f::FITS, hduindex::Int, key::String)

    keyword = _format_keyword(key)

    k = get(f.hdu[hduindex].header.map, keyword, 0)
    k > 0 || Base.throw(FITSError(msgErr(18)))        # keyword not found

    abrkey = _format_keyword(key; abr=true)
    ismandatory = abrkey ∈ fits_mandatory_keyword(f.hdu[hduindex])
    ismandatory && Base.throw(FITSError(msgErr(17)))

    card = f.hdu[hduindex].header.card
    nrec = length(card)

    n = k
    while (card[n].keyword == keyword) | (card[n].keyword == "CONTINUE")
        n += 1
    end
    n -= k

    for i=k:nrec-n
        f.hdu[hduindex].header.card[i] = card[i+n]
    end

    card = f.hdu[hduindex].header.card
    map = Dict([card[i].keyword => i for i ∈ eachindex(card)])

    dataobject = f.hdu[hduindex].dataobject
    header = FITS_header(card, map)
    f.hdu[hduindex] = cast_FITS_HDU(hduindex, header, dataobject)

    fits_save(f)

    return f
end

# ------------------------------------------------------------------------------
#              fits_edit_key!(f, hduindex, key, val, com)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_edit_key!(f::FITS, hduindex::Int, key::String, val::Any, com::String)

Edit a header record of given 'key, value and comment' to 'HDU[hduindex]' of file with name 'filnam'
#### Example:
```
data = DateTime("2020-01-01T00:00:00.000")
strExample="minimal.fits"
fits_create(strExample; protect=false)
fits_add_key!(strExample, 1, "KEYNEW1", true, "this is record 5")
fits_edit_key!(strExample, 1, "KEYNEW1", data, "record 5 changed to a DateTime type")

fits_info(f[1])

  File: minimal.fits
  hdu: 1
  hdutype: PRIMARY
  DataType: Any
  Datasize: (0,)

  Metainformation:
  SIMPLE  =                    T / file does conform to FITS standard
  NAXIS   =                    0 / number of data axes
  EXTEND  =                    T / FITS dataset may contain extensions
  COMMENT    Primary FITS HDU    / http://fits.gsfc.nasa.gov
  KEYNEW1 = '2020-01-01T00:00:00' / record 5 changed to a DateTime type
  END

  Any[]
```
"""
function fits_edit_key!(f::FITS, hduindex::Int, key::String, val::Any, com::String)

    fits_delete_key!(f, hduindex, key)
    fits_add_key!(f, hduindex, key, val, com)

    fits_save(f)

    return f

end

# ------------------------------------------------------------------------------
#            fits_rename_key!(filnam, hduindex, keyold, keynew)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_rename_key!(filnam::String, hduindex::Int, keyold::String, keynew::String)

Rename the key of a header record of file with name 'filnam'
#### Example:
```
julia> filnam="minimal.fits";

julia> f = fits_create(filnam; protect=false);

julia> fits_add_key!(f, 1, "KEYNEW1", true, "this is a new record");

julia> fits_rename_key!(f, 1, "KEYNEW1",  "KEYNEW2");

julia> fits_info(f.hdu[1])
hdu: 1
hdutype: 'PRIMARY '
DataType: Any
Datasize: (0,)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
BITPIX  =                   64 / number of bits per data pixel
NAXIS   =                    1 / number of data axes
NAXIS1  =                    0 / length of data axis 1
BZERO   =                  0.0 / offset data range to that of unsigned integer
BSCALE  =                  1.0 / default scaling factor
EXTEND  =                    T / FITS dataset may contain extensions
COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/
KEYNEW2 =                    T / this is a new record
END

Any[]
```
"""
function fits_rename_key!(f::FITS, hduindex::Int, keyold::String, keynew::String)

    keyold = _format_keyword(keyold)
    keynew = _format_keyword(keynew)

    k = get(f.hdu[hduindex].header.map, keyold, 0)
    k > 0 || Base.throw(FITSError(msgErr(18)))        # keyword not found

    abrkey = _format_keyword(keyold; abr=true)
    ismandatory = abrkey ∈ fits_mandatory_keyword(f.hdu[hduindex])
    ismandatory && Base.throw(FITSError(msgErr(19)))

    card = f.hdu[hduindex].header.card[k]
    record = rpad(keynew, 8) * card.record[9:80]

    f.hdu[hduindex].header.card[k] = cast_FITS_card(k, record)

    card = f.hdu[hduindex].header.card
    map = Dict([card[i].keyword => i for i ∈ eachindex(card)])

    dataobject = f.hdu[hduindex].dataobject
    header = FITS_header(card, map)
    f.hdu[hduindex] = cast_FITS_HDU(hduindex, header, dataobject)

    fits_save(f)

    return f

end

# ------------------------------------------------------------------------------
#                 fits_copy(filnam1 [, filnam2="" [; protect=true[, msg=true]]])
# ------------------------------------------------------------------------------

@doc raw"""
    fits_copy(filnam1 [, filnam2="" [; protect=true]])

Copy `filnam1` to `filnam2` (with mandatory `.fits` extension)
Key:
* `protect::Bool`: overwrite protection
* `msg::Bool`: allow status message
#### Examples:
```
fits_copy("T01.fits")
  'T01.fits' was saved as 'T01 - Copy.fits'

fits_copy("T01.fits", "T01a.fits")
  strError: 'T01a.fits' in use (set ';protect=false' to lift overwrite protection)

fits_copy("T01.fits", "T01a.fits"; protect=false)
  'T01.fits' was saved as 'T01a.fits'
```
"""
function fits_copy(filnam1::String, filnam2=" "; protect=true, msg=true)

    f = fits_read(filnam1)

    filnam2 = filnam2 == " " ? "$(f.filnam.name) - Copy.fits" : filnam2

    Base.Filesystem.isfile(filnam2) && Base.throw(FITSError(msgErr(1)))

    n = cast_FITS_filnam(filnam2)
    f.filnam.value = n.value
    f.filnam.name = n.name
    f.filnam.prefix = n.prefix
    f.filnam.numerator = n.numerator
    f.filnam.extension = n.extension

    # fits_save_as(f, filnam2; protect)

    #f = fits_read(filnam2)

    msg && println("'$(filnam1)' was copied under the name '$(filnam2)'")

    fits_save(f)

    return f

end

# ------------------------------------------------------------------------------
#                 fits_collect(strA, strB [; protect=true])
# ------------------------------------------------------------------------------

@doc raw"""
    fits_collect(fileStart::String, fileStop::String [; protect=true[], msg=true]])

Combine "fileStart" with "fileStop" (with mandatory ".fits" extension)

Key:
* `protect::Bool`: overwrite protection
* `msg::Bool`: allow status message
#### Example:
```
julia> f = fits_collect("T1.fits", "T5.fits"; protect=false);
'T1-T5.fits': file created

julia> fits_info(f);
File: T1-T5.fits
hdu: 1
hdutype: PRIMARY
DataType: UInt32
Datasize: (512, 512, 5)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
BITPIX  =                   32 / number of bits per data pixel
NAXIS   =                    3 / number of data axes
NAXIS1  =                  512 / length of data axis 1
NAXIS2  =                  512 / length of data axis 2
NAXIS3  =                    5 / length of data axis 3
BZERO   =           2147483648 / offset data range to that of unsigned integer
BSCALE  =                  1.0 / default scaling factor
EXTEND  =                    T / FITS dataset may contain extensions
COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/
END
```
"""
function fits_collect(fileStart::String, fileStop::String; protect=true, msg=true)

    # Base.Filesystem.isfile(fileStart) || Base.throw(FITSError(msgErr(1)))
    # Base.Filesystem.isfile(fileStop) || Base.throw(FITSError(msgErr(1)))

    nam1 = cast_FITS_filnam(fileStart)
    strPre1 = nam1.prefix
    strNum1 = nam1.numerator
    strExt1 = nam1.extension
    valNum1 = parse(Int, strNum1)
    numLeadingZeros = length(strNum1) - length(string(valNum1))

    nam2 = cast_FITS_filnam(fileStop)
    strPre2 = nam2.prefix
    strNum2 = nam2.numerator
    strExt2 = nam2.extension
    valNum2 = parse(Int, strNum2)
    numLeadingZeros2 = length(strNum2) - length(string(valNum2))

    if strPre1 ≠ strPre2
        error(strPre1 * " ≠ " * strPre2 * " (prefixes must be identical)")
    elseif strExt1 ≠ strExt2
        error(strExt1 * " ≠ " * strExt2 * " (file extensions must be identical)")
    elseif uppercase(strExt1) ≠ ".FITS"
        error("file extension must be '.fits'")
    end

    numFiles = 1 + valNum2 - valNum1
    f = fits_read(fileStart)
    dataA = f.hdu[1].dataobject.data  # read an image from disk
    t = typeof(f.hdu[1].dataobject.data[1, 1, 1])
    s = size(f.hdu[1].dataobject.data)

    dataStack = Array{t,3}(undef, s[1], s[2], numFiles)

    itr = valNum1:valNum2
    filnamNext = fileStart
    for i ∈ itr
        l = length(filnamNext)
        filnamNext = strPre1 * "0"^numLeadingZeros * string(i) * ".fits"
        if l < length(filnamNext)
            numLeadingZeros = numLeadingZeros - 1
            filnamNext = strPre1 * "0"^numLeadingZeros * string(i) * ".fits"
        end
        f = fits_read(filnamNext)
        dataNext = f.hdu[1].dataobject.data           # read an image from disk
        dataStack[:, :, i] = dataNext[:, :, 1]
    end

    filnamOut = strPre1 * strNum1 * "-" * strPre1 * strNum2 * strExt1

    f = fits_create(filnamOut, dataStack; protect)

    msg && println("'$filnamOut': file created")

    return f

end
# ------------------------------------------------------------------------------
#                    parse_FITS_TABLE(hdu::FITS_HDU)
# ------------------------------------------------------------------------------

@doc raw"""
    parse_FITS_TABLE(hdu::FITS_HDU)

Parse `FITS_TABLE` (ASCII table) into a Vector of its columns for further
processing by the user. Default formatting in ISO 2004 FORTRAN data format
specified by keys "TFORMS1" - "TFORMSn"). Display formatting in ISO 2004
FORTRAN data format ("TDISP1" - "TDISPn") prepared for user editing.
#### Example:
```
strExample = "example.fits"
data = [10, 20, 30]
fits_create(strExample, data; protect=false)

t1 = Float16[1.01E-6,2.0E-6,3.0E-6,4.0E-6,5.0E-6]
t2 = [0x0000043e, 0x0000040c, 0x0000041f, 0x0000042e, 0x0000042f]
t3 = [1.23,2.12,3.,4.,5.]
t4 = ['a','b','c','d','e']
t5 = ["a","bb","ccc","dddd","ABCeeaeeEEEEEEEEEEEE"]
data = [t1,t2,t3,t4,t5]
fits_extend(strExample, data, "TABLE")

f = fits_read(strExample)
d = f[2].header.dict
d = [get(d,"TFORM\$i",0) for i=1:5]; println(strip.(d))
  SubString{String}["'E6.1    '", "'I4      '", "'F4.2    '", "'A1      '", "'A20     '"]

f[2].dataobject.data                            # this is the table hdu
  5-element Vector{String}:
   "1.0e-6 1086 1.23 a a                    "
   "2.0e-6 1036 2.12 b bb                   "
   "3.0e-6 1055 3.0  c ccc                  "
   "4.0e-6 1070 4.0  d dddd                 "
   "5.0e-6 1071 5.0  e ABCeeaeeEEEEEEEEEEEE "

parse_FITS_TABLE(f[2])
  5-element Vector{Vector{T} where T}:
   [1.0e-6, 2.0e-6, 3.0e-6, 4.0e-6, 5.0e-6]
   [1086, 1036, 1055, 1070, 1071]
   [1.23, 2.12, 3.0, 4.0, 5.0]
   ["a", "b", "c", "d", "e"]
   ["a                   ", "bb                  ", "ccc                 ", "dddd                ", "ABCeeaeeEEEEEEEEEEEE"]
```
"""
function parse_FITS_TABLE(hdu::FITS_HDU)

    dict = hdu.header.map
    thdu = Base.strip(Base.get(dict, "XTENSION", "UNKNOWN"), ['\'', ' '])

    thdu == "TABLE" || return error("Error: $thdu is not an ASCII TABLE HDU")

    ncols = Base.get(dict, "TFIELDS", 0)
    nrows = Base.get(dict, "NAXIS2", 0)
    tbcol = [Base.get(dict, "TBCOL$n", 0) for n = 1:ncols]
    tform = [Base.get(dict, "TFORM$n", 0) for n = 1:ncols]
    ttype = [cast_FORTRAN_format(tform[n]).Type for n = 1:ncols]
    tchar = [cast_FORTRAN_format(tform[n]).TypeChar for n = 1:ncols]
    width = [cast_FORTRAN_format(tform[n]).width for n = 1:ncols]
    itr = [(tbcol[k]:tbcol[k]+width[k]-1) for k = 1:ncols]

    data = hdu.dataobject.data
    data = [[data[i][itr[k]] for i = 1:nrows] for k = 1:ncols]
    data = [tchar[k] == 'D' ? Base.join.(Base.replace!.(Base.collect.(data[k]), 'D' => 'E')) : data[k] for k = 1:ncols]
    Type = [ttype[k] == "Aw" ? (width[k] == 1 ? Char : String) : ttype[k] == "Iw" ? Int : Float64 for k = 1:ncols]
    data = [ttype[k] == "Aw" ? data[k] : parse.(Type[k], (data[k])) for k = 1:ncols]

    return data

end