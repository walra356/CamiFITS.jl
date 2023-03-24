# .................................. save to file for FITS array ...................................................

function _fits_save(FITS)
    
    o = IOBuffer()  
      
    for i ∈ eachindex(FITS)
        a = _write_header(FITS[i])
        Base.write(o, Array{UInt8,1}(a.data))
        b = _write_data(FITS[i])
        b.size > 0 && Base.write(o, Array{UInt8,1}(b.data))
    end
        
    return _fits_write_IO(o, FITS[1].filnam)                    # same filnam in all HDUs                
    
end

function _fits_write_IO(o::IO, filnam::String)

    s = Base.open(filnam, "w")
    Base.write(s, o.data)
    Base.close(s)

end

# ------------------------------------------------------------------------------
#                      _write_header(hdu::FITS_HDU)
# 
#   - 
#   - 
# ------------------------------------------------------------------------------  

function _write_header(hdu::FITS_HDU)

    o = IOBuffer()

    Base.seekstart(o)

    records = hdu.header.records
    recvals = join(records) 
    isascii = !convert(Bool, sum(.!(31 .< Int.(collect(recvals)) .< 127)))
    isascii || Base.throw(FITSError(msgFITS(9)))
    #nrecs = Base.length(records)
    #blanks = [Base.repeat(' ', 80) for i=1:(36 - nrecs % 36)]      # complement last header block with blank records
    #records = Base.append!(records,blanks)
    nbytes = Base.write(o, Array{UInt8,1}(join(records)))
    remain = nbytes % 2880
    remain > 0 && Base.throw(FITSError(msgFITS(8)))

    return o

end
function _write_header1(hdu::FITS_HDU)
     
    o = IOBuffer() 
    
    Base.seekstart(o) 
    
    records = FITS_HDU.header.records     
      nrecs = Base.length(records)
     blanks = [Base.repeat(' ', 80) for i=1:(36 - nrecs % 36)]      # complement last header block with blank records
    records = Base.append!(records,blanks)
     nbytes = Base.write(o, Array{UInt8,1}(join(records)))
        
    return o
    
end

# .................................. write-io for FITS_HDU (data sector) ..........................................

function _write_data(hdu::FITS_HDU)     
        
    hdutype = hdu.dataobject.hdutype
           
    hdutype == "PRIMARY"  && return _write_IMAGE_data(hdu)
    hdutype == "IMAGE"    && return _write_IMAGE_data(hdu)    
    hdutype == "TABLE"    && return _write_TABLE_data(hdu)  
    hdutype == "BINTABLE" && return _write_BINTABLE_data(hdu)  
    
    return error("strError: '$hdutype': not a 'FITS standard extension'")
        
end

function _write_IMAGE_data(hdu::FITS_HDU)

    o = IOBuffer()

    Base.seekstart(o)

    data = hdu.dataobject.data
    ndat = !isnothing(data) ? Base.length(data) : 0
    ndat ≠ 0 || return o

    E = Base.eltype(data)
    E <: Real || Base.throw(FITSError(msgFITS(5))) 
                 # 5 - incorrect DataType (Real type mandatory for image HDUs)

    nbyte = sizeof(E)
    bzero = _fits_bzero(E)
    data = Base.vec(data)
    data = data .- E(bzero)                                           # change between Int and UInt (if applicable)
    data = hton.(data)                                                # change from 'host' to 'network' ordering

    [Base.write(o, data[i]) for i = 1:ndat]                               # write data
    [Base.write(o, E(0)) for i = 1:((2880÷nbyte)-ndat%(2880÷nbyte))]  # complement with type E zero elements

    return o

end

function _write_TABLE_data(hdu::FITS_HDU) 
     
    o = IOBuffer() 
    
    Base.seekstart(o) 
    
    records = join(hdu.dataobject.data)                      # Array of ASCII records
      nrecs = Base.length(records)                                # number of ASCII records
      lrecs = Base.length(records[1])                             # length of ASCII records
      nchar = 2880 - (nrecs * lrecs) % 2880                       # number of blanks to complement last data block
     blanks = Base.repeat(' ',nchar)                              # complement last data block with blanks
     nbytes = Base.write(o,Array{UInt8,1}(records * blanks))
            
    return o
    
end
