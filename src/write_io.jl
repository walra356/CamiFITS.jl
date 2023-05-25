# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                          write_io.jl
#                         Jook Walraven 21-03-2023
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                        fits_save(f::FITS)
# ------------------------------------------------------------------------------

function fits_save(f::FITS)

    o = IOBuffer()

    for i ∈ eachindex(f.hdu)
        o1 = IOWrite_header(f.hdu[i])
        Base.write(o, Array{UInt8,1}(o1.data))
        o2 = IOWrite_data(f.hdu[i])
        o2.size > 0 && Base.write(o, Array{UInt8,1}(o2.data))
    end

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

    o = IOBuffer()

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

function IOWrite(o::IO, filnam::String)

    s = Base.open(filnam, "w")
    Base.write(s, o.data)
    Base.close(s)

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

function IOWrite_ARRAY_data(hdu::FITS_HDU)

    o = IOBuffer()

    Base.seekstart(o)

    data = hdu.dataobject.data
    ndat = Base.length(data)
    ndat ≠ 0 || return o

    T = Base.eltype(data)

    i = get(hdu.header.map, "BZERO", 0)
    bzero = i > 0 ? hdu.header.card[i].value : 0.0
    nbyte = T ≠ Any ? Base.sizeof(T) : 8

    data = Base.vec(data)
    # change between Int and UInt (if applicable):
    data = data .- T(bzero)
    # change from 'host' to 'network' ordering: 
    data = hton.(data) 

    # write data:
    [Base.write(o, data[i]) for i ∈ eachindex(data)] 
    # complete block with blanks:
    [Base.write(o, T(0)) for i = 1:((2880÷nbyte)-ndat%(2880÷nbyte))]  
    return o

end
function IOWrite_TABLE_data(hdu::FITS_HDU)

    o = IOBuffer()

    Base.seekstart(o)

    record = join(join.(hdu.dataobject.data))
    nchars = length(record)
    # number of blanks to complement last data block:
    nblank = 2880 - nchars % 2880
    # complement last data block with blanks:
    blanks = Base.repeat(' ', nblank)
    nbyte = Base.write(o, Array{UInt8,1}(record * blanks))
    remain = nbyte % 2880                      # remainder (incomplete block)

    remain > 0 && Base.throw(FITSError(msgErr(6)))

    return o

end

function IOWrite_BINTABLE_data(hdu::FITS_HDU)

    o = IOBuffer()

    Base.seekstart(o)

    record = join(hdu.dataobject.data) # Array of ASCII records
    nrecs = Base.length(record) # number of ASCII records
    lrecs = Base.length(record[1])  # length of ASCII records
    nchar = 2880 - (nrecs * lrecs) % 2880  # number of blanks to complement last data block
    blank = Base.repeat(' ', nchar) # complement last data block with blanks
    nbyte = Base.write(o, Array{UInt8,1}(record * blank))

    return o

end

