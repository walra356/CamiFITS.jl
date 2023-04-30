# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                          fits_public_sector.jl
#                         Jook Walraven 21-03-2023
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                     fits_info(hdu::FITS_HDU)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_info(hdu::FITS_HDU)

Print metafinformation and data of the specified `hdu`. 

Default: `fits_info(f)` => `fits_info(f.hdu[1])` (primary hdu)
#### Example:
```
Julia> filnam = "minimal.fits";

julia> f = fits_create(filnam; protect=false);

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
function fits_info(hdu::FITS_HDU; msg=true)

    typeof(hdu) <: FITS_HDU || error("FitsWarning: FITS_HDU not found")

    strDataType = Base.string(Base.eltype(hdu.dataobject.data))
    strDatasize = Base.string(Base.size(hdu.dataobject.data))

    info = [
        "hdu: " * Base.string(hdu.hduindex),
        "hdutype: " * hdu.dataobject.hdutype,
        "DataType: " * strDataType,
        "Datasize: " * strDatasize,
        "\r\nMetainformation:"
    ]

    card = hdu.header.card

    records = [card[i].record for i ∈ eachindex(card)]

    _rm_blanks!(records)

    Base.append!(info, records)

    msg && println(Base.join(info .* "\r\n"))

    return hdu.dataobject.data

end
function fits_info(f::FITS; msg=true)

    str = "File: " * f.filnam.value
    msg && println(str) 

    return fits_info(f.hdu[1]; msg)

end

# ------------------------------------------------------------------------------
#                 fits_create(filnam [, data [; protect=true]])
# ------------------------------------------------------------------------------

@doc raw"""
    fits_create(filnam [, data [; protect=true]])

Create `.fits` file of given filnam and return Array of HDUs.
Key:
* `protect::Bool`: overwrite protection
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
    hdutype = "PRIMARY"

    dat = cast_FITS_data(hdutype, data) # (hduindex, hdutype, data)
    rec = cast_FITS_header(_PRIMARY_input(dat)) # , hduindex)
    hdu = cast_FITS_HDU(filnam, hduindex, rec, dat)

    f = cast_FITS(filnam, [hdu])

    _fits_save(f)

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

    Base.Filesystem.isfile(filnam) || Base.throw(FITSError(msgErr(1)))

    o = IORead(filnam)

    nhdu = _hdu_count(o)

    Base.seekstart(o)

    rec = [_read_header(o::IO, i) for i = 1:nhdu]
    Base.seekstart(o)

    dat = [_read_data(o, i) for i = 1:nhdu]
    hdu = [cast_FITS_HDU(filnam, i, rec[i], dat[i]) for i = 1:nhdu]

    f = cast_FITS(filnam, hdu)

    return f

end

# ------------------------------------------------------------------------------
#           fits_extend(filnam::String, data_extend [, hdutype="IMAGE"])
# ------------------------------------------------------------------------------

@doc raw"""
    fits_extend!(f::FITS, data_extend, hdutype="IMAGE")

Extend the `.fits` file of given filnam with the data of `hdutype` from `data_extend`  and return Array of HDUs.
#### Examples:
```
Julia> filnam = "test_example.fits";

Julia> data = [0x0000043e, 0x0000040c, 0x0000041f];

Julia> f = fits_create(filnam, data; protect=false);

Julia> a = Float16[1.01E-6,2.0E-6,3.0E-6,4.0E-6,5.0E-6];

Julia> b = [0x0000043e, 0x0000040c, 0x0000041f, 0x0000042e, 0x0000042f];

Julia> c = [1.23,2.12,3.,4.,5.];

Julia> d = ['a','b','c','d','e'];

Julia> e = ["a","bb","ccc","dddd","ABCeeaeeEEEEEEEEEEEE"];

Julia> data = [a,b,c,d,e];

Julia> fits_extend!(f, data, "TABLE")


Julia> f.hdu[2].dataobject.data
  5-element Vector{String}:
   "1.0e-6 1086 1.23 a a                    "
   "2.0e-6 1036 2.12 b bb                   "
   "3.0e-6 1055 3.0  c ccc                  "
   "4.0e-6 1070 4.0  d dddd                 "
   "5.0e-6 1071 5.0  e ABCeeaeeEEEEEEEEEEEE "

rm(strExample); f = data = a = b = c = d = e = nothing
```
"""
function fits_extend!(f::FITS, data_extend, hdutype="IMAGE")

    hdutype = Base.Unicode.uppercase(strip(hdutype))

    hdutype == "IMAGE" ? (records, data) = _IMAGE_input(data_extend) :
    hdutype == "TABLE" ? (records, data) = _TABLE_input(data_extend) :
    hdutype == "BINTABLE" ? (records, data) = _BINTABLE_input(data_extend) :
    Base.throw(FITSError(msgErr(20)))

    filnam = f.filnam.value
    nhdu = f.hdu[end].hduindex + 1

    rec = cast_FITS_header(records)
    dat = cast_FITS_data(hdutype, data)

    push!(f.hdu, cast_FITS_HDU(filnam, nhdu, rec, dat))

    _fits_save(f)

    return f

end

# ------------------------------------------------------------------------------
#              fits_add_key(filnam, hduindex, key, val, com)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_add_key(f::FITS, hduindex::Int, key::String, val::Any, com::String)

Add a header record of given 'key, value and comment' to 'HDU[hduindex]' of file with name 'filnam'
#### Example:
```
strExample="minimal.fits"
f = fits_create(strExample; protect=false)
fits_add_key(f, 1, "KEYNEW1", true, "FITS dataset may contain extension")

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
  KEYNEW1 =                    T / FITS dataset may contain extension
  END

  Any[]
```
"""
function fits_add_key(f::FITS, hduindex::Int, key::String, val::Any, com::String)

    k = get(f.hdu[hduindex].header.map, _format_keyword(key), 0)
    k > 0 && Base.throw(FITSError(msgErr(7)))        # " keyword in use

    k = get(f.hdu[hduindex].header.map, "END", 0)
    k > 0 || Base.throw(FITSError(msgErr(13)))       # "END keyword not found

    remain = (k + 1) % 36
    nblank = 36 - remain

    rec = _format_record(key, val, com)
    nrec = length(rec)

    card = f.hdu[hduindex].header.card
    if nrec > nblank
        block = repeat([repeat(' ', 80)], 36 * nrec ÷ nblank)
        append!(card, block)
    end

    card[k+nrec] = card[k]
    for i = 0:nrec-1
        card[k+i] = cast_FITS_card(k + i, rec[1+i])
        push!(f.hdu[hduindex].header.map, card[k+i].keyword => k + i)
    end

    _fits_save(f)

    return f

end

# ------------------------------------------------------------------------------
#         fits_delete_key(filnam::String, hduindex::Int, key::String)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_delete_key(f::FITS, hduindex::Int, key::String)

Delete a header record of given `key`, `value` and `comment` to `FITS_HDU[hduindex]` of file with name  'filnam'
#### Examples:
```
julia> strExample="minimal.fits";

julia> f = fits_create(strExample; protect=false);

Julia> f = fits_add_key(strExample, 1, "KEYNEW1", true, "this is record 5");

Julia> cardindex = get(f.hdu[1].header.map,"KEYNEW1", nothing)
9

Julia> keyword = f.hdu[1].header.card[cardindex].keyword
"KEYNEW1"

Julia> f = fits_delete_key(strExample, 1, "KEYNEW1");

Julia> cardindex = get(f.hdu[1].header.map,"KEYNEW1", nothing)

Julia> fits_delete_key(strExample, 1, "NAXIS")
 'NAXIS': cannot be deleted (key protected under FITS standard)
```
"""
function fits_delete_key(f::FITS, hduindex::Int, key::String)

    i = hduindex
    keyword = _format_keyword(key)

    k = get(f.hdu[i].header.map, keyword, 0)
    k > 0 || Base.throw(FITSError(msgErr(18)))        # keyword not found

    card = f.hdu[i].header.card
    kend = length(card)

    abrkey = _format_keyword(key; abr=true)
    ismandatory = abrkey ∈ fits_mandatory_keyword(f.hdu[i])

    ismandatory && Base.throw(FITSError(msgErr(17)))

    while (card[k].keyword == keyword) | (card[k].keyword == "CONTINUE")
        push!(f.hdu[i].header.card, cast_FITS_card(kend, repeat(' ', 80)))
        deleteat!(card, k)
    end

    delete!(f.hdu[hduindex].header.map, keyword)

    _fits_save(f)

    return f
end


# ------------------------------------------------------------------------------
#              fits_edit_key(filnam, hduindex, key, val, com)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_edit_key(filnam::String, hduindex::Int, key::String, val::Any, com::String)

Edit a header record of given 'key, value and comment' to 'HDU[hduindex]' of file with name 'filnam'
#### Example:
```
data = DateTime("2020-01-01T00:00:00.000")
strExample="minimal.fits"
fits_create(strExample; protect=false)
fits_add_key(strExample, 1, "KEYNEW1", true, "this is record 5")
fits_edit_key(strExample, 1, "KEYNEW1", data, "record 5 changed to a DateTime type")

f = fits_read(strExample)
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
function fits_edit_key(f::FITS, hduindex::Int, key::String, val::Any, com::String)

    fits_delete_key(f, hduindex, key)
    fits_add_key(f, hduindex, key, val, com)

    _fits_save(f)

    return f

end

# ------------------------------------------------------------------------------
#            fits_rename_key(filnam, hduindex, keyold, keynew)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_rename_key(filnam::String, hduindex::Int, keyold::String, keynew::String)

Rename the key of a header record of file with name 'filnam'
#### Example:
```
strExample="minimal.fits"
fits_create(strExample; protect=false)
fits_add_key(strExample, 1, "KEYNEW1", true, "this is record 5")
fits_rename_key(strExample, 1, "KEYNEW1",  "KEYNEW2")

f = fits_read(strExample)
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
  KEYNEW2 =                    T / this is record 5
  END

  Any[]
```
"""
function fits_rename_key(f::FITS, hduindex::Int, keyold::String, keynew::String)

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
    delete!(f.hdu[hduindex].header.map, keyold)
    push!(f.hdu[hduindex].header.map, keynew => k)

    _fits_save(f)

    return f

end

# ------------------------------------------------------------------------------
#                 fits_copy(filnamA [, filnamB="" [; protect=true]])
# ------------------------------------------------------------------------------

@doc raw"""
    fits_copy(filnamA [, filnamB="" [; protect=true]])

Copy "filnamA" to "filnamB" (with mandatory ".fits" extension)
Key:
* `protect::Bool`: overwrite protection
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
function fits_copy(filnamA::String, filnamB::String=" "; protect=true)

    # err =_err_FITS_filnam(filnamA; protect)
    # err > 1 && Base.throw(FITSError(msgError(err)))

    o = IORead(filnamA)
    f = cast_FITS_filnam(filnamA)

    filnamB = filnamB == " " ? "$(f.name) - Copy.fits" : filnamB

    err = _err_FITS_filnam(filnamB; protect)
    err > 1 && Base.throw(FITSError(msgError(err)))

    _fits_write_IO(o, filnamB)

    return println("'$filnamA' was saved as '$filnamB'")

end

# ------------------------------------------------------------------------------
#                 fits_combine(strA, strB [; protect=true])
# ------------------------------------------------------------------------------

@doc raw"""
    fits_combine(strA, strB [; protect=true])

Combine "filnamA" with "filnamB" (with mandatory ".fits" extension)

Key:
* `protect::Bool`: overwrite protection
#### Example:
```
fits_combine("T01.fits", "T22.fits")
  'T01-T22.fits': file created
```
"""
function fits_combine(filnamA::String, filnamB::String; protect=true)

    err = _err_FITS_filnam(filnamA; protect)
    err > 1 && Base.throw(FITSError(msgError(err)))

    err = _err_FITS_filnam(filnamB; protect)
    err > 1 && Base.throw(FITSError(msgError(err)))

    filnamA = uppercase(filnamA)
    filnamB = uppercase(filnamB)

    nam = cast_FITS_filnam(filnamA)
    strPre = nam.prefix
    strNum = nam.numerator
    strExt = nam.extension
    valNum = parse(Int, strNum)
    numLeadingZeros = length(strNum) - length(string(valNum))

    nam2 = cast_FITS_filnam(filnamB)
    strPre2 = nam2.prefix
    strNum2 = nam2.numerator
    strExt2 = nam2.extension
    valNum2 = parse(Int, strNum2)
    numLeadingZeros2 = length(strNum2) - length(string(valNum2))

    if strPre ≠ strPre2
        error(strPre * " ≠ " * strPre2 * " (prefixes must be identical)")
    elseif strExt ≠ strExt2
        error(strExt * " ≠ " * strExt2 * " (file extensions must be identical)")
    elseif uppercase(strExt) ≠ ".FITS"
        error("file extension must be '.fits'")
    end

    numFiles = 1 + valNum2 - valNum
    f = fits_read(filnamA)
    dataA = f[1].dataobject.data  # read an image from disk
    t = typeof(f[1].dataobject.data[1, 1, 1])
    s = size(f[1].dataobject.data)

    dataStack = Array{t,3}(undef, s[1], s[2], numFiles)

    itr = valNum:valNum2
    filnamNext = filnamA
    for i ∈ itr
        l = length(filnamNext)
        filnamNext = strPre * "0"^numLeadingZeros * string(i) * ".fits"
        if l < length(filnamNext)
            numLeadingZeros = numLeadingZeros - 1
            filnamNext = strPre * "0"^numLeadingZeros * string(i) * ".fits"
        end
        f = fits_read(filnamNext)
        dataNext = f[1].dataobject.data                # read an image from disk
        dataStack[:, :, i] = dataNext[:, :, 1]
    end

    filnamOut = strPre * strNum * "-" * strPre * strNum2 * strExt

    err = _err_FITS_filnam(filnamOut; protect)
    err > 1 && Base.throw(FITSError(msgError(err)))

    fits_create(filnamOut, dataStack; protect)

    return println("'$filnamOut': file created")

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

    dict = hdu.header.dict
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
