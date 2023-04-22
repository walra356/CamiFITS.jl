# .................................. save to file for FITS array ...................................................

function _fits_save(f::FITS)

    o = IOBuffer()

    for i ∈ eachindex(f.hdu)
        o1 = IOWrite_header(f.hdu[i])
        Base.write(o, Array{UInt8,1}(o1.data))
        o2 = IOWrite_data(f.hdu[i])
        o2.size > 0 && Base.write(o, Array{UInt8,1}(o2.data))
    end

    return _fits_write_IO(o, f.filnam.value)

end

# ------------------------------------------------------------------------------
#                        _fits_write_IO(o, filnam)
# ------------------------------------------------------------------------------

function _fits_write_IO(o::IO, filnam::String)

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

    hdutype == "PRIMARY" && return IOWrite_IMAGE_data(hdu)
    hdutype == "IMAGE" && return IOWrite_IMAGE_data(hdu)
    hdutype == "TABLE" && return IOWrite_TABLE_data(hdu)
    hdutype == "BINTABLE" && return IOWrite_BINTABLE_data(hdu)

    return error("strError: '$hdutype': not a 'FITS standard extension'")

end

function IOWrite_IMAGE_data(hdu::FITS_HDU)

    o = IOBuffer()

    Base.seekstart(o)

    data = hdu.dataobject.data
    ndat = Base.length(data)
    ndat ≠ 0 || return o

    E = Base.eltype(data)
    E <: Real || Base.throw(FITSError(msgErr(5)))
    # 5 - incorrect DataType (Real type mandatory for image HDUs)

    nbyte = sizeof(E)
    bzero = _fits_bzero(E)
    data = Base.vec(data)
    data = data .- E(bzero)                                           # change between Int and UInt (if applicable)
    data = hton.(data)                                                # change from 'host' to 'network' ordering

    [Base.write(o, data[i]) for i = 1:ndat]                           # write data
    [Base.write(o, E(0)) for i = 1:((2880÷nbyte)-ndat%(2880÷nbyte))]  # complement with type E zero elements

    return o

end

function IOWrite_TABLE_data(hdu::FITS_HDU)

    o = IOBuffer()

    Base.seekstart(o)

    records = join(hdu.dataobject.data)                      # Array of ASCII records
    nrecs = Base.length(records)                                # number of ASCII records
    lrecs = Base.length(records[1])                             # length of ASCII records
    nchar = 2880 - (nrecs * lrecs) % 2880                       # number of blanks to complement last data block
    blanks = Base.repeat(' ', nchar)                              # complement last data block with blanks
    nbytes = Base.write(o, Array{UInt8,1}(records * blanks))

    return o

end

