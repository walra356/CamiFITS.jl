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
#                          write_io.jl
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                        fits_save(f::FITS)
# ------------------------------------------------------------------------------
@doc raw"""
    fits_save(f::FITS [; protect=true])

Write the FITS object to disc. This routine is called by [`fits_create`](@ref) 
and [`fits_extend`](@ref)

![Image](../assets/fits_save.png)
"""
function fits_save(f::FITS; protect=true)

    if Base.Filesystem.isfile(f.filnam.value) & protect
        Base.throw(FITSError(msgErr(4)))
    end

    n = 0
    for i ∈ eachindex(f.hdu)
        n += f.hdu[i].header.size
        k = f.hdu[i].header.map["BITPIX"]
        ndata = length(f.hdu[i].dataobject.data)
        nbyte = ndata * f.hdu[i].header.card[k].value
        n += (nbyte ÷ 2880) + (iszero(nbyte % 2880) ? 0 : 2880)
    end
    
    # restrict buffersize explicitly to the correct number of blocks of 2880 bytes,
    # NB. memory allocated by julia when using Base.write() is larger)
    o = IOBuffer(maxsize=n) 

    for i ∈ eachindex(f.hdu)
        o1 = IOWrite_header(f, i)
        Base.write(o, o1.data[1:o1.size])
        o2 = IOWrite_data(f, i)
        o2.size > 0 && Base.write(o, o2.data[1:o2.size])
    end

    length(o.data) == n || error("fits_save: FITS filesize error")

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

julia> fits_save_as(f, "foo.fits"; protect=false);

julia> f = fits_read("foo.fits");

julia> fits_info(f)
File: foo.fits
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

    if Base.Filesystem.isfile(filnam) & protect
        Base.throw(FITSError(msgErr(4)))
    end

    n = 0

    for i ∈ eachindex(f.hdu)
        n += f.hdu[i].header.size
        k = f.hdu[i].header.map["BITPIX"]
        ndata = length(f.hdu[i].dataobject.data)
        nbyte = ndata * f.hdu[i].header.card[k].value
        #nbyte *= ndata * sizeof(eltype(f.hdu[i].dataobject.data))
        n += (nbyte ÷ 2880) + (iszero(nbyte % 2880) ? 0 : 2880)
    end
    
    # restrict buffersize explicitly to the correct number of blocks of 2880 bytes,
    # NB. memory allocated by julia when using Base.write() is larger)
    o = IOBuffer(maxsize=n) 

    for i ∈ eachindex(f.hdu)
        o1 = IOWrite_header(f, i)
        Base.write(o, o1.data[1:o1.size])
        o2 = IOWrite_data(f, i)
        o2.size > 0 && Base.write(o, o2.data[1:o2.size])
    end

    length(o.data) == n || error("fits_save: FITS filesize error")

    return IOWrite(o, filnam)

end

# ------------------------------------------------------------------------------
#                        IOWrite(o, filnam)
# ------------------------------------------------------------------------------

function IOWrite(o::IO, filnam::String)

    s = Base.open(filnam, "w")
    Base.write(s, o.data)
    Base.close(s)

end

# ------------------------------------------------------------------------------
#                          IOWrite_header(hdu)
# ------------------------------------------------------------------------------

function IOWrite_header(f::FITS, hduindex::Int)

    hdu = f.hdu[hduindex]

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

function IOWrite_data(f::FITS, hduindex::Int; msg=false)

    hdutype = f.hdu[hduindex].dataobject.hdutype

    hdutype == "'PRIMARY '" && return IOWrite_ARRAY_data(f, hduindex; msg)
    hdutype == "'IMAGE   '" && return IOWrite_ARRAY_data(f, hduindex; msg)
    hdutype == "'ARRAY   '" && return IOWrite_ARRAY_data(f, hduindex; msg)
    hdutype == "'TABLE   '" && return IOWrite_TABLE_data(f, hduindex; msg)
    hdutype == "'BINTABLE'" && return IOWrite_BINTABLE_data(f, hduindex; msg)

end

# ------------------------------------------------------------------------------
#                          IOWrite_ARRAY_data(hdu)
# ------------------------------------------------------------------------------

function IOWrite_ARRAY_data(f::FITS, hduindex::Int; msg=false)

    hdu = f.hdu[hduindex]
    maxindex = length(f.hdu)
    header = f.hdu[hduindex].header

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
    T = Base.eltype(data)


msg && println("from object: hdu[$(hduindex)].dataobject.data = ", data) 
    data = fits_apply_zero_offset(data) # to store double range for natural numbers
msg && println("after offset: hdu[$(hduindex)].dataobject.data = ", data) 
    data = hton.(data) # change from host ordering (depends on machine) network ordering (big-endian) 
msg && println("after hton: hdu[$(hduindex)].dataobject.data = ", data) 


# write data:
    [Base.write(o, data[i]) for i ∈ eachindex(data)] 
    # complete block with blanks:
    [Base.write(o, T(0)) for i = 1:((2880÷nbyte)-ndat % (2880÷nbyte))]  

    return o

end

# ------------------------------------------------------------------------------
#                          IOWrite_TABLE_data(hdu)
# ------------------------------------------------------------------------------

function IOWrite_TABLE_data(f::FITS, hduindex::Int; msg=false)

    hdu = f.hdu[hduindex]

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
# ------------------------------------------------------------------------------
#                      fits_apply_offset(data)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_apply_zero_offset(data)
 
Shift the `UInt` range of values onto the `Int` range by *substracting* from 
the `data` the appropriate integer offset value as specified by the `BZERO` 
keyword.

NB. Since the FITS format *does not support a native unsigned integer data 
type* (except `UInt8`), unsigned values of the types `UInt16`, `UInt32` and 
`UInt64`, are stored as native signed integers of the types `Int16`, `Int32` 
and `Int64`, respectively, after *substracting* the appropriate integer offset 
specified by the (positive) `BZERO` keyword value. For the byte data type 
(`UInt8`), the converse technique can be used to store signed byte values 
(`Int8`) as native unsigned values (`UInt`) after subtracting the (negative) 
`BZERO` offset value. 

This method is included and used in storing of data to ensure backward 
compatibility with software not supporting native values of the types `Int8`, 
`UInt16`, `UInt32` and `UInt64`.
#### Example:
```
julia> fits_apply_zero_offset(UInt32[0])
1-element Vector{Int32}:
 -2147483648

julia> fits_apply_zero_offset(Int8[0])
1-element Vector{UInt8}:
 0x80

julia> Int(0x80)
128
```
"""
function fits_apply_zero_offset(data) # to store double range for natural numbers

    T = eltype(data)

    T ∈ (Int8, UInt16, UInt32, UInt64) || return data

    T == Int8 && return UInt8.(Int.(data) .+ 128)
    T == UInt16 && return Int16.(Int.(data) .- 32768)
    T == UInt32 && return Int32.(Int.(data) .- 2147483648)
    T == UInt64 && return Int64.(Int128.(data) .- 9223372036854775808)

    # note workaround for InexactError:trunc(Int64, 9223372036854775808)

end

# ------------------------------------------------------------------------------
function IOWrite_BINTABLE_data(f::FITS, hduindex::Int; msg=false)

    hdu = f.hdu[hduindex]

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
msg && println("from object: hdu[$(hduindex)].dataobject.data = ", data) 
            field = fits_apply_zero_offset(field) # to store double range for natural numbers
msg && println("after offset: hdu[$(hduindex)].dataobject.data = ", data) 
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

