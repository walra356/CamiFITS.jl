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
#                          fits_public_sector.jl
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                   fits_info(f::FITS, hduindex=1; hdr=true)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_info(f::FITS [, hduindex=1 [; nr=false [, hdr=true]]])
    fits_info(hdu::FITS_HDU; nr=false, hdr=true)

Metafinformation and data of a given [`FITS_HDU`](@ref) object with *optional*
record numbering. 

* `hduindex`: HDU index (::Int - default: `1` = `primary hdu`)
* `nr`: include cardindex (::Bool - default: `false`)
* `hdr`: show header (::Bool)
#### Example:
To demonstrate `fits_info` we first create the fits object `f` for subsequent 
inspection.
```
julia> filnam = "minimal.fits";

julia> f = fits_create(filnam; protect=false);

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
EXTEND  =                    T / FITS dataset may contain extensions
END

Any[]

julia> rm(filnam); f = nothing
```
    fits_info(filnam::String [, hduindex=1 [; nr=true [, hdr=true]]])

Same as above but creating the fits object by reading `filnam` from disc 
and with *default* record numbering.

* `hduindex`: HDU index (::Int - default: `1` = `primary hdu`)
* `nr`: include cardindex (::Bool - default: `true`)
* `hdr`: show header (::Bool)
#### Example:
```
julia> filnam = "minimal.fits";

julia> fits_create(filnam; protect=false);

julia> fits_info(filnam)

File: minimal.fits
hdu: 1
hdutype: 'PRIMARY '
DataType: Any
Datasize: (0,)

  nr | Metainformation:
---------------------------------------------------------------------------------------
   1 | SIMPLE  =                    T / file does conform to FITS standard
   2 | BITPIX  =                   64 / number of bits per data pixel
   3 | NAXIS   =                    1 / number of data axes
   4 | NAXIS1  =                    0 / length of data axis 1
   5 | EXTEND  =                    T / FITS dataset may contain extensions
   6 | END

Any[]

julia> rm(filnam)
```
"""
function fits_info(hdu::FITS_HDU; nr=false, hdr=true)

    typeof(hdu) <: FITS_HDU || error("FitsWarning: FITS_HDU not found")

    hdutype = hdu.dataobject.hdutype
    header = hdu.header
    card = hdu.header.card
    data = hdu.dataobject.data

    str = "hdu: " * Base.string(hdu.hduindex)
    str *= "\nhdutype: " * hdu.dataobject.hdutype
    if (hdutype ≠ "'TABLE   '") & (hdutype ≠ "'BINTABLE'")
        strDatasize = Base.string(Base.size(hdu.dataobject.data))
        strDataType = Base.string(Base.eltype(hdu.dataobject.data))
        str *= "\nDataType: " * strDataType
        str *= "\nDatasize: " * strDatasize
    end
    str *= nr ? "\n\n  nr | " : "\n\n"
    str *= "Metainformation:"
    str *= nr ? '\n' *repeat('-', 87) : ""

    str = [str]

    record = [card[i].record for i ∈ eachindex(card)]

    _rm_blanks!(record)

    record = nr ? [lpad("$i | ", 7) * record[i] for i ∈ eachindex(record)] :
             record

    Base.append!(str, record)

    hdr && println(Base.join(str .* "\r\n"))

    return data

end
# ------------------------------------------------------------------------------
function fits_info(f::FITS, hduindex=1; nr=false, hdr=true)

    str = "\nFile: " * f.filnam.value
    hdr && println(str)

    return fits_info(f.hdu[hduindex]; nr, hdr)

end
# ------------------------------------------------------------------------------
function fits_info(filnam::String, hduindex=1; nr=true, hdr=true)
  
    o = IORead(filnam)

    Base.seekstart(o)

    p = cast_FITS_pointer(o)

    hdu = read_hdu(o, p, hduindex)

    str = "\nFile: " * filnam
    
    hdr && println(str)

    return fits_info(hdu; nr, hdr)

end

# ------------------------------------------------------------------------------
#       fits_record_dump(filnam::String, hduindex=0; hdr=true, dat=true, nr=true)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_record_dump(filnam [, hduindex=0 [; hdr=true [, dat=true [, nr=true [, msg=true]]]])

The file `filnam` as a `Vector{String}` of 80 character strings (records) 
without any further formatting. 

For `msg=true`` it outputs a listing of `filnam` in blocks (2880 bytes) of 36 
(optionally indexed) records. The dump proceeds *without casting of FITS objects*; 
i.e., *without* FITS-conformance testing.

default: `hduindex` = 0 - all blocks
         `hduindex` > 0 - only blocks of given `hduindex`

* `hduindex`: HDU index (::Int - default: `0` all records)
* `hdr`: show header (::Bool - default: true)
* `dat`: show data (::Bool - default: true)
* `nr`: include record index (row number) (::Bool - default: true)
* `msg`: print message (::Bool)

NB. The tool `fits_record_dump` is included for developers to facilitate code analysis of the 
[`CamiFITS`](ref) package (e.g. the correct implementation of `ENDIAN` wraps and zero=offset 
shifting). 

#### Example:
```
julia> filnam = "foo.fits";

julia> data = [typemin(UInt32),typemax(UInt32)];

julia> fits_create(filnam, data; protect=false);

julia> dump = fits_record_dump(filnam; msg=false);

julia> foreach(println,dump[3:8])
   3 | NAXIS   =                    1 / number of data axes
   4 | NAXIS1  =                    2 / length of data axis 1
   5 | BSCALE  =                  1.0 / default scaling factor
   6 | BZERO   =           2147483648 / offset data range to that of unsigned integer
   7 | EXTEND  =                    T / FITS dataset may contain extensions
   8 | END

julia> dump[37]
"  37 | UInt8[0x80, 0x00, 0x00, 0x00, 0x7f, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, ⋯, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]"]"

julia> rm(filnam); f = data = dump = nothing
```
"""
function fits_record_dump(filnam::String, hduindex=0; hdr=true, dat=true, nr=true, msg=false)

    o = IORead(filnam)

    p = cast_FITS_pointer(o)

    hduval = hduindex

    rec = []
    for i = 1:p.nhdu
        if (i == hduval) ⊻ iszero(hduval)
            if hdr
                Base.seek(o, p.hdr_start[i])
                for itr = (p.hdr_start[i]÷80+1):(p.hdr_stop[i]÷80)
                    add = (itr, String(Base.read(o, 80)))
                    push!(rec, add)
                end
            end
            if dat
                Base.seek(o, p.data_start[i])
                for itr = (p.data_start[i]÷80+1):(p.data_stop[i]÷80)
                    add = (itr, "$(Base.read(o, 80))")
                    push!(rec, add)
                end
            end
        end
    end

    record = [rec[i][2] for i ∈ eachindex(rec)]

    record = nr ? [lpad("$(rec[i][1]) | ", 7) * record[i] for i ∈ eachindex(record)] : record

    str = "\nFile: " * filnam * " - bare record dump:\n"

    msg && println(str)

    record = rec == [] ? nothing : record

    return record

end

# ------------------------------------------------------------------------------
#                 fits_create(filnam [, data [; protect=true]])
# ------------------------------------------------------------------------------

@doc raw"""
    fits_create(filnam [, data [; protect=true]])

Create and [`fits_save`](@ref) a `.fits` file of given filnam and return Array of HDUs.
Key:
* `data`: data primary hdu (::DataType)
* `protect`: overwrite protection (::Bool)

NB. For the details of the save procedure (not shown in the flow diagram) see [`fits_save`](@ref).
 
![Image](../assets/fits_create.png)

#### Examples:
```
julia> filnam = "test.fits";

julia> f = fits_create(filnam, data; protect=false);

julia> fits_info(f)

File: test.fits
hdu: 1
hdutype: 'PRIMARY '
DataType: Int64
Datasize: (3, 3)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
BITPIX  =                   64 / number of bits per data pixel
NAXIS   =                    2 / number of data axes
NAXIS1  =                    3 / length of data axis 1
NAXIS2  =                    3 / length of data axis 2
EXTEND  =                    T / FITS dataset may contain extensions
END

3×3 Matrix{Int64}:
 11  21  31
 12  22  23
 13  23  33

julia> rm("minimal.fits"); f = nothing
```
"""
function fits_create(filnam::String, data=[]; protect=true, msg=false)

msg && println("fits_create:")

    hduindex = 1
    dataobject = cast_FITS_dataobject("'PRIMARY '", data)
    header = cast_FITS_header(dataobject)
msg && println("data = ", data)
#   data = fits_apply_offset(data, header) #adapt according to header information
#println("data = ", data)
#   dataobject = cast_FITS_dataobject("'PRIMARY '", data)
msg && println("cast hdu[$(hduindex)]")
    hdu = cast_FITS_HDU(hduindex, header, dataobject)

    f = cast_FITS(filnam, [hdu])

    fits_save(f; protect)

    return f

end

# ------------------------------------------------------------------------------
#           fits_extend(f::FITS, data [; hdutype="IMAGE"])
# ------------------------------------------------------------------------------

function _fits_table_data(data)

    nrows = length(data)
    tfields = length(data[1])

    T = typeof.(data[1])

    for i=1:nrows
        for j=1:tfields
            data[i][j] = T[j] == Bool ? Int(data[i][j] ) : data[i][j] 
        end
    end

    return data

end
# ------------------------------------------------------------------------------
@doc raw"""
    fits_extend(f::FITS, data [; hdutype="IMAGE"])
    fits_extend(filnam::String, data [; hdutype="IMAGE"])

HDU array in which the FITS object `f` or FITS file `filnam` is extended 
with the `data` in the format of the specified `hdutype`. 

NB. For the details of the save procedure (not shown in the flow diagram) see [`fits_save`](@ref).

![Image](../assets/fits_extend.png)

#### Examples:
```
julia> filnam = "example.fits";

julia> fits_create(filnam; protect=false);

julia> table = let
        [true, 0x6c, 1081, 0x0439, 1.23, 1.01f-6, 1.01e-6, 'a', "a", "abc"],
        [false, 0x6d, 1011, 0x03f3, 23.2, 3.01f-6, 3.01e-6, 'b', "b", "abcdef"]
        end;

julia> fits_extend(filnam, table; hdutype="table");

julia> fits_info(filnam, 2; hdr=false)
2-element Vector{String}:
 " 1 108 1081 1081  1.23 1.01E-6 1.01D-6 a a    abc"
 " 0 109 1011 1011 23.20 3.01E-6 3.01D-6 b b abcdef"

julia> rm(filnam)
```
"""
function fits_extend(f::FITS, data=[]; hdutype="IMAGE", msg=false)

    hdutype = _format_hdutype(hdutype)
    hduindex = length(f.hdu) + 1

msg && println("fits extend!: hduindex = ", hduindex)

    if hdutype == "'TABLE   '"
        data = _fits_table_data(data)
    end

    dataobject = cast_FITS_dataobject(hdutype, data)
    header = cast_FITS_header(dataobject)


msg && println("data = ", data)
 #   data = fits_apply_offset(data, header) #adapt according to header information
#println("data = ", data)
#    dataobject = cast_FITS_dataobject(hdutype, data)

    hdu = cast_FITS_HDU(hduindex, header, dataobject)

msg && println("extend hdu with hdu[$(hduindex)]" )
    push!(f.hdu, hdu)

    fits_save(f; protect=false)

    return f

end
function fits_extend(filnam::String, data=[]; hdutype="IMAGE", msg=false)

    Base.Filesystem.isfile(filnam) || return println("file not found")

    f = fits_read(filnam; msg)
    
    o = fits_extend(f, data; hdutype, msg)

    return o

end

# ------------------------------------------------------------------------------
#                     fits_read(filnam::String)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_read(filnam::String)

Read `.fits` file and return Array of `FITS_HDU`s

![Image](../assets/fits_read.png)

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
END

Any[]

julia> rm(filnam); f = nothing
```
"""
function fits_read(filnam::String; msg=false)
    
    o = IORead(filnam)

    p = cast_FITS_pointer(o)
    
    Base.seekstart(o)
        
    hdu = [read_hdu(o, p, i; msg) for i = 1:p.nhdu]
        
    f = cast_FITS(filnam, hdu)
    
    return f
    
end

# ------------------------------------------------------------------------------
#                     fits_pointer(filnam::String)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_pointer(filnam::String)
    fits_pointer(f::FITS) 

[`FITS_pointer`](@ref) object of the file `filnam` or its [`FITS`](@ref) object `f`.

#### Examples:
```
julia> filnam = "foo.fits";

julia> f = fits_create(filnam, data; protect=false);

julia> fits_extend(f; hdutype="'IMAGE   '");

julia> fits_extend(filnam, data; hdutype="'IMAGE   '");

julia> p = fits_pointer(f);

julia> p.nblock
5
```
"""
function fits_pointer(filnam::String)

    Base.Filesystem.isfile(filnam) || return println("file not found")
        
    o = IORead(filnam)
    
    p = cast_FITS_pointer(o)
    
    return p

end
function fits_pointer(f::FITS) 

    filnam = f.filnam.value

    return fits_pointer(filnam)
        
end

# ------------------------------------------------------------------------------
#                     fits_pointers(filnam::String)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_pointers(filnam::String)
    fits_pointers(f::FITS) 

summay of the pointers used by `CamiFITS`

#### Examples:
```
julia> filnam = "foo.fits";

julia> data = [0x0000043e, 0x0000040c, 0x0000041f];

julia> f = fits_create(filnam, data; protect=false);

julia> fits_extend(f);

julia> fits_extend(filnam, data; hdutype="'IMAGE   '");

julia> foreach(println, fits_pointers(filnam))
             block count: 5
               hdu count: 3
 start-of-block pointers: (0, 2880, 5760, 8640, 11520)
   end-of-block pointers: (2880, 5760, 8640, 11520, 14400)
   start-of-hdu pointers: (0, 5760, 8640)
     end-of-hdu pointers: (2880, 8640, 11520)
start-of-header pointers: (0, 5760, 8640)
  end-of-header pointers: (2880, 8640, 11520)
  start-of-data pointers: (2880, 8640, 11520)
    end-of-data pointers: (5760, 8640, 14400)
```
"""
function fits_pointers(filnam::String) 

    p = fits_pointer(filnam)

    str = [  
    "             block count: $(p.nblock)", 
    "               hdu count: $(p.nhdu)",
    " start-of-block pointers: $(p.block_start)",
    "   end-of-block pointers: $(p.block_stop)",
    "   start-of-hdu pointers: $(p.hdu_start)",
    "     end-of-hdu pointers: $(p.hdu_stop)", 
    "start-of-header pointers: $(p.hdr_start)",    
    "  end-of-header pointers: $(p.hdr_stop)" ,   
    "  start-of-data pointers: $(p.data_start)",   
    "    end-of-data pointers: $(p.data_stop)"
    ] 

    return str

end
function fits_pointers(f::FITS) 

    filnam = f.filnam.value

    return fits_pointers(filnam)
        
end    


# ------------------------------------------------------------------------------
#           fits_copy(filnam1 [, filnam2=""] [; protect=true[, msg=true]])
# ------------------------------------------------------------------------------

@doc raw"""
    fits_copy(filnam1 [, filnam2="" [; protect=true]])

Copy `filnam1` to `filnam2` (with mandatory `.fits` extension)
Key:
* `protect::Bool`: overwrite protection
* `msg::Bool`: allow status message
#### Examples:
```
julia> fits_create("test1.fits"; protect=false);

julia> fits_copy("test1.fits", "test2.fits"; protect=false);
'test1.fits' was copied under the name 'test2.fits'

julia> rm.(["test1.fits", "test2.fits"]);
```
"""
function fits_copy(filnam1::String, filnam2=" "; protect=true, msg=true)

    filnam = filnam2 == " " ? (filnam1 * " - Copy.fits") : filnam2

    isprotected = Base.Filesystem.isfile(filnam) & protect
    isprotected && println("Try copy '" * filnam1 * "' to '" * filnam * "'")
    isprotected && Base.throw(FITSError(msgErr(4)))

    o = IORead(filnam1)

    IOWrite(o, filnam)

    return msg && println("'$(filnam1)' was copied to '$(filnam)'")

end

# ------------------------------------------------------------------------------
#                 fits_collect(strA, strB [; protect=true])
# ------------------------------------------------------------------------------

@doc raw"""
    fits_collect(fileStart::String, fileStop::String [; protect=true [, msg=true]])

Combine "fileStart" with "fileStop" (with mandatory ".fits" extension)

Key:
* `protect::Bool`: overwrite protection
* `msg::Bool`: allow status message
#### Example:
```
julia> for i=1:5
           data = [0 0 0; 0 i 0; 0 0 0]
           fits_create("T$i.fits", data; protect=false)
       end

julia> f = fits_collect("T1.fits", "T5.fits"; protect=false);
'T1-T5.fits': file created

julia> fits_info(f)[:,:,2]

File: T1-T5.fits
hdu: 1
hdutype: 'PRIMARY '
DataType: Int64
Datasize: (3, 3, 5)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
BITPIX  =                   64 / number of bits per data pixel
NAXIS   =                    3 / number of data axes
NAXIS1  =                    3 / length of data axis 1
NAXIS2  =                    3 / length of data axis 2
NAXIS3  =                    5 / length of data axis 3
EXTEND  =                    T / FITS dataset may contain extensions
END

3×3 Matrix{Int64}:
 0  0  0
 0  2  0
 0  0  0

julia> for i = 1:5 rm("T$i.fits") end

julia> rm("T1-T5.fits"); f = nothing
```
"""
function fits_collect(fileStart::String, fileStop::String; protect=true, msg=true)

    Base.Filesystem.isfile(fileStart) || Base.throw(FITSError(msgErr(1)))
    Base.Filesystem.isfile(fileStop) || Base.throw(FITSError(msgErr(1)))

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

    nstack = 1 + valNum2 - valNum1
    f = fits_read(fileStart)
    dataA = f.hdu[1].dataobject.data  # read an image from disk
    t = eltype(f.hdu[1].dataobject.data)
    s = size(f.hdu[1].dataobject.data)

    d = ndims(f.hdu[1].dataobject.data)

    dims = d == 1 ? (nstack, s[1]) : d == 2 ? (s[1], s[2], nstack) :
           d == 3 ? (s[1], s[2], nstack) : Base.throw(FITSError(msgErr(38)))

    datastack = Array{t,}(undef, dims)

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
        dataNext = f.hdu[1].dataobject.data       # read an image from disk
        if d == 3
            datastack[:, :, i] = dataNext[:, :, 1]
        elseif d == 2
            datastack[:, :, i] = dataNext[:, :]
        else
            datastack[i, :] = dataNext[:]
        end
    end

    filnamOut = strPre1 * strNum1 * "-" * strPre1 * strNum2 * strExt1

    f = fits_create(filnamOut, datastack; protect)

    msg && println("'$filnamOut': file created")

    return f

end

# ------------------------------------------------------------------------------
#              fits_insert_key!(f, hduindex, nr, key, val, com)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_insert_key!(f::FITS, hduindex::Int, cardindex::Int, key::String, val::Any, com::String)

Insert one or more [`FITS_card`]s for given 'key', 'value' and 'comment' at position `cardindex` 
in `f.hdu[hduindex].header.card`; i.e., into the record stack of the [`FITS_header`](@ref) of the 
[`FITS_HDU`](@ref)`[hduindex]` of the [`FITS`](@ref) object 'f'.

NB. For insert without specification of `cardindex `use [`fits_add_key!`](@ref).
#### Example:
```
julia> filnam = "minimal.fits";

julia> f = fits_create(filnam; protect=false);

julia> fits_insert_key!(f, 1, 3, "KeYNEw1", true, "This is the new key");

julia> fits_info(f;nr=true);

File: minimal.fits
hdu: 1
hdutype: 'PRIMARY '
DataType: Any
Datasize: (0,)

  nr | Metainformation:
---------------------------------------------------------------------------------------
   1 | SIMPLE  =                    T / file does conform to FITS standard
   2 | BITPIX  =                   64 / number of bits per data pixel
   3 | KEYNEW8 =                    T / This is the new key
   4 | NAXIS   =                    1 / number of data axes
   5 | NAXIS1  =                    0 / length of data axis 1
   6 | EXTEND  =                    T / FITS dataset may contain extensions
   7 | END
```
"""
function fits_insert_key!(f::FITS, hduindex::Int, cardindex::Int, key::String, val::Any, com::String)

    dbg = false
    nr = cardindex
    ne = get(f.hdu[hduindex].header.map, "END", 0)
    ne > 0 || Base.throw(FITSError(msgErr(13)))      # END keyword not found
    nr ≤ ne || Base.throw(FITSError(msgErr(48)))     # insert not allowed beyond the END keyword
    f.hdu[hduindex].header.card[nr].keyword ≠ "CONTINUE" || Base.throw(FITSError(msgErr(49)))

    k = get(f.hdu[hduindex].header.map, _format_keyword(key), 0)
    k > 0 && Base.throw(FITSError(msgErr(7)))        # keyword in use

    n = f.hdu[hduindex].header.card[end].cardindex   # cardindex of last card of header

    recnew = _format_record(key, val, com)
    ni = length(recnew) # number of records to insert
    nadd = (ni - n + ne + 35) ÷ (36) # number of blocks to add to header to fit insert 
    
    card = f.hdu[hduindex].header.card

    if nadd > 0
        blanks = repeat(' ', 80)
        block = [cast_FITS_card(n + i, blanks) for i = 1:(36*nadd)]
        append!(card, block)
    end

    for i=ne:-1:nr # shift records down to create space for insert
        rec = card[i].record 
        f.hdu[hduindex].header.card[i+ni] = cast_FITS_card(i+ni, rec)
    end
    
    for i=1:ni # insert new records
        rec = recnew[i]
        f.hdu[hduindex].header.card[nr+i-1] = cast_FITS_card(nr+i-1, rec)
    end

    card = f.hdu[hduindex].header.card

                        dbg && for i ∈ eachindex(card) println(i, " | ", card[i].record) end

    dataobject = f.hdu[hduindex].dataobject
    header = cast_FITS_header(card)
    f.hdu[hduindex] = cast_FITS_HDU(hduindex, header, dataobject)

    fits_save(f; protect=false)

    return f

end

# ------------------------------------------------------------------------------
#              fits_add_key!(f, hduindex, key, val, com)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_add_key!(f::FITS, hduindex::Int, key::String, val::Any, com::String)

Insert one or more [`FITS_card`]s for given 'key', 'value' and 'comment' at 
*non-specified* position in `f.hdu[hduindex].header.card`; i.e., into the record 
stack of the [`FITS_header`](@ref) of the [`FITS_HDU`](@ref)`[hduindex]` of the 
[`FITS`](@ref) object 'f'.      

#### Example:
```
julia> filnam = "minimal.fits";

julia> f = fits_create(filnam; protect=false);

julia> fits_add_key!(f, 1, "KEYNEW1", true, "This is the new key");

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
EXTEND  =                    T / FITS dataset may contain extensions
KEYNEW1 =                    T / This is the new key
END

Any[]
```
"""
function fits_add_key!(f::FITS, hduindex::Int, key::String, val::Any, com::String)

    ne = get(f.hdu[hduindex].header.map, "END", 0)
    ne > 0 || Base.throw(FITSError(msgErr(13)))       # END keyword not found

    return fits_insert_key!(f, hduindex, ne, key, val, com)

end


# ------------------------------------------------------------------------------
#                  fits_delete_key!(f, hduindex, key)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_delete_key!(f::FITS, hduindex::Int, key::String)

Delete a header record of given `key`, `value` and `comment` from the 
FITS_HDU `f` of given `hduindex`.
#### Examples:
```
julia> filnam = "minimal.fits";

julia> f = fits_create(filnam; protect=false);

julia> fits_add_key!(f, 1, "KEYNEW1", true, "This is the new key");

julia> cardindex = get(f.hdu[1].header.map,"KEYNEW1", nothing)
8

julia> keyword = f.hdu[1].header.card[cardindex].keyword
"KEYNEW1"

julia> cardindex = get(f.hdu[1].header.map,"KEYNEW1", nothing)
8

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
    
    ne = get(f.hdu[hduindex].header.map, "END", 0)
    ne > 0 || Base.throw(FITSError(msgErr(13)))       # END keyword not found

    nr = get(f.hdu[hduindex].header.map, keyword, 0)   # card nr with given key
    nr > 0 || Base.throw(FITSError(msgErr(18)))        # keyword not found

    abrkey = _format_keyword(key; abr=true)
    ismandatory = abrkey ∈ fits_mandatory_keyword(f.hdu[hduindex])
    ismandatory && Base.throw(FITSError(msgErr(17)))

    card = f.hdu[hduindex].header.card
    nrec = length(card)

    nd = nr
    while (card[nd].keyword == keyword) ⊻ (card[nd].keyword == "CONTINUE")
        nd += 1
    end
    nd -= nr # n records to be deleted

    ne = ne-nd
    for i=nr:ne # shift remaining records up
        rec = card[i+nd].record 
        f.hdu[hduindex].header.card[i] = cast_FITS_card(i, rec)
    end

    nblanks = (36 - (ne % 36)) % 36 # number of blanks required to fill the block
    nrec = ne + nblanks

    for i=ne+1:ne+nblanks # fill remainder of block with blanks
        blank = Base.repeat(' ', 80)
        f.hdu[hduindex].header.card[i] = cast_FITS_card(i, blank)
    end

    card = f.hdu[hduindex].header.card[1:nrec]
    
    dataobject = f.hdu[hduindex].dataobject
    header = cast_FITS_header(card)
    f.hdu[hduindex] = cast_FITS_HDU(hduindex, header, dataobject)

    fits_save(f, protect=false)

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
julia> using Dates

julia> data = DateTime("2020-01-01T00:00:00.000");

julia> strExample="minimal.fits";

julia> f = fits_create(strExample; protect=false);

julia> fits_add_key!(f, 1, "KEYNEW1", true, "this is record 5");

julia> fits_edit_key!(f, 1, "KEYNEW1", data, "record 5 changed to a DateTime type");

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
EXTEND  =                    T / FITS dataset may contain extensions
KEYNEW1 = '2020-01-01T00:00:0' / record 5 changed to a DateTime type
END

Any[]
```
"""
function fits_edit_key!(f::FITS, hduindex::Int, key::String, val::Any, com::String)

    keyword = _format_keyword(key)

    nr = get(f.hdu[hduindex].header.map, keyword, 0)   # card nr with given key
    nr > 0 || Base.throw(FITSError(msgErr(18)))        # keyword not found

    fits_delete_key!(f, hduindex, key)
    fits_insert_key!(f, hduindex, nr, key, val, com)

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

    dataobject = f.hdu[hduindex].dataobject
    header = cast_FITS_header(card)
    f.hdu[hduindex] = cast_FITS_HDU(hduindex, header, dataobject)

    fits_save(f, protect=false)

    return f

end

# ------------------------------------------------------------------------------
#                    fits_parse_table(hdu::FITS_HDU)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_parse_table(hdu::FITS_HDU; byrow=true)


Parse `FITS_TABLE` (ASCII table) into a Vector of its rows/columns for further
processing by the user. Default formatting in ISO 2004 FORTRAN data format
specified by keys "TFORMS1" - "TFORMSn"). Display formatting in ISO 2004
FORTRAN data format ("TDISP1" - "TDISPn") prepared for user editing.

#### Example:
```
julia> filnam = "foo.fits";
    
julia> fits_create(filnam; protect=false);
    
julia> data = [[true, 0x6c, 1081, 0x0439, 1081, 0x00000439, 1081, 0x0000000000000439, 1.23, 1.01f-6, 1.01e-6, 'a', "a", "abc"],
               [false, 0x6d, 1011, 0x03f3, 1011, 0x000003f3, 1011, 0x00000000000003f3, 123.4, 3.01f-6, 3.001e-5, 'b', "b", "abcdef"]];
    
julia> f = fits_extend(filnam, data; hdutype="table");
    
julia> fits_parse_table(f.hdu[2]; byrow=true)                                                                                                                                                                  
2-element Vector{Vector{Any}}:
     [1, 108, 1081, 1081, 1081, 1081, 1081, 1081, 1.23, 1.01e-6, 1.01e-6, "a", "a", "   abc"]
     [0, 109, 1011, 1011, 1011, 1011, 1011, 1011, 123.4, 3.01e-6, 3.001e-5, "b", "b", "abcdef"]
    
julia> fits_parse_table(f.hdu[2]; byrow=false)
14-element Vector{Any}:
 [1, 0]
 [108, 109]
 [1081, 1011]
 [1081, 1011]
 [1081, 1011]
 [1081, 1011]
 [1081, 1011]
 [1081, 1011]
 [1.23, 123.4]
 [1.01e-6, 3.01e-6]
 [1.01e-6, 3.001e-5]
 ["a", "b"]
 ["a", "b"]
 ["   abc", "abcdef"]
    
julia> rm(filnam)
```
"""
function fits_parse_table(hdu::FITS_HDU; byrow=true)

    dict = hdu.header.map
    card = hdu.header.card
    i = get(dict, "XTENSION", 0)
    thdu = i > 0 ? card[i].value : "UNKNOWN"
    thdu = Base.strip(thdu)

    thdu == "'TABLE   '" || return error("Error: $(thdu) is not an ASCII TABLE HDU")

    ncols = card[Base.get(dict, "TFIELDS", 0)].value
    nrows = card[Base.get(dict, "NAXIS2", 0)].value
    tbcol = [card[Base.get(dict, "TBCOL$n", 0)].value for n = 1:ncols]
    tform = [card[Base.get(dict, "TFORM$n", 0)].value for n = 1:ncols]
    tform = [string(strip(tform[n], ['\'', ' '])) for n = 1:ncols]

    ttype = [cast_FORTRAN_format(tform[n]).datatype for n = 1:ncols]
    tchar = [cast_FORTRAN_format(tform[n]).char for n = 1:ncols]
    width = [cast_FORTRAN_format(tform[n]).width for n = 1:ncols]
    itr = [(tbcol[k]:tbcol[k]+width[k]-1) for k = 1:ncols]

    data = hdu.dataobject.data
    data = [string(strip(hdu.dataobject.data[n])) for n = 1:nrows]
    data = [[data[i][itr[k]] for i = 1:nrows] for k = 1:ncols]
    data = [tchar[k] == 'D' ? Base.join.(Base.replace!.(Base.collect.(data[k]), 'D' => 'E')) : data[k] for k = 1:ncols]
    Type = [ttype[k] == "Aw" ? (width[k] == 1 ? Char : String) : ttype[k] == "Iw" ? Int : Float64 for k = 1:ncols]
    data = Any[ttype[k] == "Aw" ? data[k] : parse.(Type[k], (data[k])) for k = 1:ncols]

    data = byrow ? [Any[data[i][k] for i = 1:ncols] for k = 1:nrows] : data

    return data

end

# ------------------------------------------------------------------------------
#                      fits_zero_offset(T)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_zero_offset(T::Type)

Zero offset `a` as used in linear scaling equation
```
f(x) = a + b x,
```
where `b` is the scaling factor. 

The default value is `a = 0.0` for `Real` numeric types. 
For non-real types `a = nothing`.
#### Example:
```
julia> T = Type[Any, Bool, Int8, UInt8, Int16, UInt16, Int32, UInt32,
                  Int64, UInt64, Float16, Float32, Float64];

julia> o = (0.0, 0.0, -128, 0.0, 0.0, 32768,
                   0.0, 2147483648, 0.0, 9223372036854775808, 0.0, 0.0, 0.0);

julia> sum([fits_zero_offset(T[i]) == o[i] for i ∈ eachindex(T)]) == 13
true
```
"""
function fits_zero_offset(T::Type)

    T <: Real || return T == Any ? 0.0 : nothing

    nbits = 8 * Base.sizeof(T)
    offset = T ∉ [Int8, UInt16, UInt32, UInt64] ? 0.0 :
             T == Int8 ? -128 : T == UInt64 ? 9223372036854775808 : 2^(nbits - 1)

    return offset

end