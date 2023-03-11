# CamiFITS.jl

FITS stands for 'Flexible Image Transport System'. This is an open standard origionally developed for the astronomy community to store telescope images together with tables of spectral information. Over the years it has developed into a scientific standard - [R. J. Hanisch et al](https://doi.org/10.1051/0004-6361:20010923). 

CamiFITS offers the basic FITS functionality for scientific users not requiring celestal coordinates. The user can create, read and extend .fits files as well as create, edit and delete user-defined metainformation.

# Table of contents

```@contents
```
# Installation

The package is installed using the Julia package manager

```
julia> using Pkg; Pkg.add("CamiFITS")
```

# Documentation
## Introduction

A FITS file consists of a sequence of one or more header-data-units ([`FITS_HDU`](@ref)s), each containing a [`FITS_data`](@ref) block preceeded by [`FITS_header`](@ref) records of metainformation.

We distinguish between `IMAGE` and `TABLE` HDU data types. The first HDU in a .fits file is called the `PRIMARY` HDU.

By the command f = [`fits_read`](@ref)("filnam.fits") we asign a collection of [`FITS_HDU`](@ref) objects from the file `"filnam.fits"` to the variable `f`. 

The elements of the HDU collection `f` are `f[1], f[2], ...`, with `f[1]` representing the `PRIMARY` HDU. The structure of HDU `f[i]` can be printed in formated form using the command [`FITS_info`](@ref)(`f[i]`)

The minimal FITS file consists of a single HDU, which is empty. FITS files are created using the command [`fits_create`](@ref)(filnam; protect=false).

#### Example:
Creating and inspecting the minimal FITS file:
```
julia> filnam = "minimal.fits";

julia> fits_create(filnam; protect=false);

julia> f = fits_read(filnam);

julia> fits_info(f[1])

File: minimal.fits
hdu: 1
hdutype: PRIMARY
DataType: Any
Datasize: (0,)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
NAXIS   =                    0 / number of data axes
EXTEND  =                    T / FITS dataset may contain extensions
COMMENT    Primary FITS HDU    / http://fits.gsfc.nasa.gov/iaufwg
END

Any[]

julia> rm(filnam); f = nothing
```

### FITS - Types

```@docs
FITS_HDU{T,V}
FITS_header
FITS_data
FITS_table
FITS_name
```



### FITS - HDU Methods

```@docs
fits_info(hdu::FITS_HDU)
parse_FITS_TABLE(hdu::FITS_HDU)
```

#### FITS - File Methods

```@docs
cast_FITS_name(filename::String)
fits_combine(filnamFirst::String, filnamLast::String; protect=true)
fits_copy(filenameA::String, filenameB::String=" "; protect=true)
fits_create(filename::String, data=[]; protect=true)
fits_extend(filename::String, data_extend, hdutype="IMAGE")
fits_read(filename::String)
```

### FITS - Key Methods

```@docs
fits_add_key(filename::String, hduindex::Int, key::String, val::Real, com::String)
fits_delete_key(filename::String, hduindex::Int, key::String)
fits_edit_key(filename::String, hduindex::Int, key::String, val::Real, com::String)
fits_rename_key(filename::String, hduindex::Int, keyold::String, keynew::String)
```

## FORTRAN

```@docs
FORTRAN_format
cast_FORTRAN_format(str::String)
cast_FORTRAN_datatype(str::String)
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

## Index

```@index
```