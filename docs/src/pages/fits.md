# FITS structure

## Introduction

The *Application Programming Interface* (API) for CamiFITS is based on 6 
*FITS-object structs* with dedicated *object-casting procedures to enforce the* 
[FITS standard ](https://fits.gsfc.nasa.gov/fits_standard.html). The API 
elements are typically called internally by one of the *Basic tools* but is
made available in the documentation to provide insight in the structure of 
CamiFITS.

## FITS-objects
```@docs
FITS
FITS_filnam
FITS_HDU
FITS_header
FITS_card
FITS_dataobject
Ptrs
HDU_ptr
FITS_pointer
FITS_ptr
```

## FITS-object casting
The ordering of the FITS-object casting procedures is illustrated in the 
flow diagram below. 

![Image](../assets/fits_casting.png)

The use of the casting procedures is *recommended* over direct application
of the FITS-object strucs *to ensure conformance to the* 
[FITS standard ](https://fits.gsfc.nasa.gov/fits_standard.html).

```@docs
cast_FITS_filnam(filnam::String)
cast_FITS_dataobject(hdutype::String, data)
cast_FITS_header(dataobject::FITS_dataobject)
cast_FITS_card(cardindex::Int, record::String)
cast_FITS_HDU(hduindex::Int, header::FITS_header, data::FITS_dataobject)
cast_FITS(filnam::String, hdu::Vector{FITS_HDU})
cast_FITS_pointer(o::IO)
cast_FITS_ptr(o::IO; msg=false)
```

## FITS methods

```@docs
fits_pointer(filnam::String)
fits_pointers(filnam::String)
fits_zero_offset(T::Type)
fits_apply_zero_offset(data)
fits_remove_zero_offset(data)
fits_parse_table(hdu::FITS_HDU; byrow=true)
```

## Fortran objects 

```@docs
FORTRAN_format
```

## Fortran-object casting

```@docs
cast_FORTRAN_format(str::String)
```

## FORTRAN-related methods

```@docs
FORTRAN_eltype_char(T::Type)
```

## Plotting

```@docs
step125(x::Real)
select125(x)
steps(x::Vector{T} where T<:Real)
stepcenters(x::Vector{T} where T<:Real)
stepedges(x::Vector{T} where T<:Real)
edges(px, Δx=1.0, x0=0.0)
```