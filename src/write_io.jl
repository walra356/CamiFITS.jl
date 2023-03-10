# .................................. save to file for FITS array ...................................................

function _fits_save(FITS)
    
    o = IOBuffer()  
      
    for i ∈ eachindex(FITS)
        a = _write_header(FITS[i])
        Base.write(o,Array{UInt8,1}(a.data))
        b = _write_data(FITS[i])
        b.size > 0 && Base.write(o,Array{UInt8,1}(b.data))
    end
        
    return _fits_write_IO(o, FITS[1].filename)                    # same filename in all HDUs                
    
end

function _fits_write_IO(o::IO, filename::String)
      
    s = Base.open(filename,"w")   
        Base.write(s,o.data)    
        Base.close(s)

end

# .................................. write-io (header sector) .......................................................

function _write_header(FITS_HDU)
     
    o = IOBuffer() 
    
    Base.seekstart(o) 
    
    records = FITS_HDU.header.records     
      nrecs = Base.length(records)
     blanks = [Base.repeat(' ',80) for i=1:(36 - nrecs % 36)]      # complement last header block with blank records
    records = Base.append!(records,blanks)
     nbytes = Base.write(o,Array{UInt8,1}(join(records)))
        
    return o
    
end

# .................................. write-io for FITS_HDU (data sector) ..........................................

function _write_data(FITS_HDU)     
        
    hdutype = FITS_HDU.dataobject.hdutype
           
    hdutype == "PRIMARY"  && return _write_IMAGE_data(FITS_HDU)
    hdutype == "IMAGE"    && return _write_IMAGE_data(FITS_HDU)    
    hdutype == "TABLE"    && return _write_TABLE_data(FITS_HDU)  
    hdutype == "BINTABLE" && return _write_BINTABLE_data(FITS_HDU)  
    
    return error("FitsError: '$hdutype': not a 'FITS standard extension'")
        
end

function _write_IMAGE_data(FITS_HDU) 
     
    o = IOBuffer() 
    
    Base.seekstart(o)  
        
     data = FITS_HDU.dataobject.data
    ndata = Base.length(data)
        
    ndata == 0 && return o
      
         E = Base.eltype(data)
         E <: Real || error("FitsError: incorrect DataType (Real type mandatory for image HDUs)")
    nbytes = sizeof(E)
     bzero = _fits_bzero(E)
      data = Base.vec(data)
      data = data .- E(bzero)                                           # change between Int and UInt (if applicable)
      data = hton.(data)                                                # change from 'host' to 'network' ordering

    [Base.write(o,data[i]) for i=1:ndata]                               # write data
    [Base.write(o,E(0)) for i=1:((2880÷nbytes)-ndata % (2880÷nbytes))]  # complement with type E zero elements
    
    return o
    
end

function _write_TABLE_data(FITS_HDU) 
     
    o = IOBuffer() 
    
    Base.seekstart(o) 
    
    records = join(FITS_HDU.dataobject.data)                      # Array of ASCII records
      nrecs = Base.length(records)                                # number of ASCII records
      lrecs = Base.length(records[1])                             # length of ASCII records
      nchar = 2880 - (nrecs * lrecs) % 2880                       # number of blanks to complement last data block
     blanks = Base.repeat(' ',nchar)                              # complement last data block with blanks
     nbytes = Base.write(o,Array{UInt8,1}(records * blanks))
            
    return o
    
end
