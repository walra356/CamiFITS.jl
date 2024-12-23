# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                          write_io.jl
#                         Jook Walraven 21-03-2023
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                        fits_save(f::FITS)
# ------------------------------------------------------------------------------
function fits_save(f::FITS)
     
    n = 0

    for i ∈ eachindex(f.hdu)
        o1 = IOWrite_header(f.hdu[i])
        o2 = IOWrite_data(f.hdu[i])
        n += o1.size
        n += o2.size > 0 ? o2.size : 0
    end

    maxsize = n
    
    # buffersize must be actively restricted to the correct number of blocks of 2880 bytes,
    # because the memory allocated by julia when using Base.write() is larger
    o = IOBuffer(maxsize=n) 

    ptr2 = 1
    for i ∈ eachindex(f.hdu)
        o1 = IOWrite_header(f.hdu[i])
        Base.write(o, Array{UInt8,1}(o1.data[1:o1.size]))
            ptr1 = o.ptr
            ptr0 = ptr2 + o1.size
            ptr1 == ptr0 || println("fits_save: ptr = $(ptr1) ($(ptr0) expected)")
        o2 = IOWrite_data(f.hdu[i]) 
        o2.size > 0 && Base.write(o, Array{UInt8,1}(o2.data[1:o2.size]))
            ptr2 = o.ptr
            ptr0 = ptr1 + o2.size
            ptr2 == ptr0 || println("fits_save: ptr = $(ptr2) ($(ptr0) expected)")
    end

    length(o.data) == maxsize || println("Warning - fits_save: FITS filesize error")

    return IOWrite(o, f.filnam.value)

end

# ------------------------------------------------------------------------------
#                        fits_save_as(f::FITS)
# ------------------------------------------------------------------------------
@doc raw"""
    fits_save_as(f::FITS, filnam::String [; protect=true])

Save the [`FITS`](@ref) object under the name `filnam`.
Key:
* `protect::Bool`: overwrite protection
```
julia> f = fits_create("minimal.fits"; protect=false);

julia> fits_save_as(f, "kanweg.fits"; protect=false);

julia> f = fits_read("kanweg.fits");

julia> fits_info(f)
File: kanweg.fits
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
```
"""
function fits_save_as(f::FITS, filnam::String; protect=true)

    n = 0

    for i ∈ eachindex(f.hdu)
        o1 = IOWrite_header(f.hdu[i])
        o2 = IOWrite_data(f.hdu[i])
        n += o1.size
        n += o2.size > 0 ? o2.size : 0
    end
    
    # buffersize restricted to the correct number of blocks 0f 2880 bytes
    # NB. the memory allocated by julia when using Base.write() is larger
    o = IOBuffer(maxsize=n) 

    for i ∈ eachindex(f.hdu)
        o1 = IOWrite_header(f.hdu[i])
        Base.write(o, Array{UInt8,1}(o1.data))
        o2 = IOWrite_data(f.hdu[i])
        o2.size > 0 && Base.write(o, Array{UInt8,1}(o2.data))
    end

    isfile = Base.Filesystem.isfile(filnam)

    (isfile & protect) && Base.throw(FITSError(msgErr(4)))

    return IOWrite(o, filnam)

end

# ------------------------------------------------------------------------------
#                        IOWrite(o, filnam)
# ------------------------------------------------------------------------------

function IOWrite(o::IO, filnam::String; msg=false)

    s = Base.open(filnam, "w")
    Base.write(s, o.data)
    Base.close(s)

    if msg
        println("===========================================")
        println("IOWrite:") 
        println("-------------------------------------------")
        for i=1:2880:o.size    
            str = String(o.data[i:i+7])                                                                                                                                                                                    
            str ∈ ["SIMPLE  ", "XTENSION"] && println("$i: " * str)                                                                                      
        end
        println("-------------------------------------------")
    end

end

# ------------------------------------------------------------------------------
#                          IOWrite_header(hdu)
# ------------------------------------------------------------------------------

function IOWrite_header(hdu::FITS_HDU)

    o = IOBuffer()

    Base.seekstart(o)

    records = [hdu.header.card[i].record for i ∈ eachindex(hdu.header.card)]
    header = join(records)
    isasciitext = _isascii_text(header)
    isasciitext || Base.throw(FITSError(msgErr(23)))
    nbytes = Base.write(o, Array{UInt8,1}(header))
    remain = nbytes % 2880
    remain > 0 && Base.throw(FITSError(msgErr(8)))

    return o

end

# ------------------------------------------------------------------------------
#                          IOWrite_data(hdu)
# ------------------------------------------------------------------------------

function IOWrite_data(hdu::FITS_HDU)

    hdutype = hdu.dataobject.hdutype

    hdutype == "'PRIMARY '" && return IOWrite_ARRAY_data(hdu)
    hdutype == "'IMAGE   '" && return IOWrite_ARRAY_data(hdu)
    hdutype == "'ARRAY   '" && return IOWrite_ARRAY_data(hdu)
    hdutype == "'TABLE   '" && return IOWrite_TABLE_data(hdu)
    hdutype == "'BINTABLE'" && return IOWrite_BINTABLE_data(hdu)

    return error("strError: '$hdutype': not a 'FITS standard extension'")

end

# ------------------------------------------------------------------------------
#                          IOWrite_ARRAY_data(hdu)
# ------------------------------------------------------------------------------

function IOWrite_ARRAY_data(hdu::FITS_HDU)

    o = IOBuffer() #maxsize=2880) # uitgaand van 1 block (kan fout zijn)

    Base.seekstart(o)

    data = hdu.dataobject.data
    ndat = Base.length(data)
    ndat ≠ 0 || return o

    T = Base.eltype(data)

    i = get(hdu.header.map, "BZERO", 0)
    bzero = i > 0 ? hdu.header.card[i].value : 0.0
    nbyte = T ≠ Any ? Base.sizeof(T) : 8

    data = Base.vec(data)

    #data = data .+ T(bzero)
    # apply mapping between UInt-range and Int-range (if applicable):
    data = fits_apply_offset(data)

    T = Base.eltype(data)

    # change from 'host' to 'network' ordering: 
    data = hton.(data) 

    # write data:
    [Base.write(o, data[i]) for i ∈ eachindex(data)] 
    # complete block with blanks:
    [Base.write(o, T(0)) for i = 1:((2880÷nbyte)-ndat % (2880÷nbyte))]  

    return o

end

# ------------------------------------------------------------------------------
#                          IOWrite_TABLE_data(hdu)
# ------------------------------------------------------------------------------

function IOWrite_TABLE_data(hdu::FITS_HDU)

    o = IOBuffer()

    Base.seekstart(o)

    record = join(hdu.dataobject.data)
    nchars = length(record)
    # number of blanks to complement last data block:
    nblank = 2880 - nchars % 2880
    # complement last data block with blanks:
    blanks = Base.repeat(' ', nblank)
    nbyte = Base.write(o, Vector{UInt8}(record * blanks))
    remain = nbyte % 2880                      # remainder (incomplete block)

    remain > 0 && Base.throw(FITSError(msgErr(6)))

    return o

end

# ------------------------------------------------------------------------------
#                          IOWrite_BINTABLE_data(hdu)
# ------------------------------------------------------------------------------

function _apply_offset(data)

    t = eltype(data)

    t ∈ (Int8, UInt16, UInt32, UInt64) || return data

    t == Int8 && return UInt8.(Int.(data) .+ 128)
    t == UInt16 && return Int16.(Int.(data) .- 32768)
    t == UInt32 && return Int32.(Int.(data) .- 2147483648)
    t == UInt64 && return Int64.(Int128.(data) .- 9223372036854775808)

    # note workaround for InexactError:trunc(Int64, 9223372036854775808)

end
# ------------------------------------------------------------------------------
function IOWrite_BINTABLE_data(hdu::FITS_HDU)

    o = IOBuffer()

    Base.seekstart(o)

    data = hdu.dataobject.data
    nrow = Base.length(data) 
    tfields = Base.length(data[1])

    nbyte = 0

    for i = 1:nrow
        for j = 1:tfields
            field = data[i][j]
            V = typeof(data[1][j])
            T = typeof(field)
            T ≠ V && Base.throw(FITSError(msgErr(46)))
            if (T <: Vector) ⊻ (T <: Tuple)
                t = eltype(field)
            else
                t = T == BitVector ? T : eltype(field)
            end
            # apply mapping between UInt-range and Int-range (if applicable):
            field = _apply_offset(field)
            # change from 'host' to 'network' ordering: 
            if t <: Number
                if t ≠ Bool
                    field = hton.(field)
                end
            elseif t == BitVector
                if (T <: Vector) ⊻ (T <: Tuple)
                    field = [bitstring(field[k]) for k ∈ eachindex(field)]
                    field = parse.(UInt, field; base=2)
                    field = hton.(field)
                else
                    field = bitstring(field)
                    field = parse(UInt, field; base=2)
                    field = hton(field)
                end
            end
            
            # write data from field:
            if (T <: Vector) ⊻ (T <: Tuple)
                Any[Base.write(o, field[k]) for k ∈ eachindex(field)]
            else
                Base.write(o, field)
            end
        end
    end
    # number of blanks to complement last data block
    ndat = 2880 - o.size % 2880
 
    # complete block with blanks:
    [Base.write(o, UInt8(0)) for i = 1:ndat]
    
    return o

end

