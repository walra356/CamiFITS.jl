# CamiFITS.jl

FITS stands for 'Flexible Image Transport System'. This is an open standard origionally developed for the astronomy community to store telescope images together with tables of spectral information. Over the years it has developed into a scientific standard - http://fits.gsfc.nasa.gov/iaufwg. 

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

### FITS - Types

```@docs
FITS_HDU{T,V}
FITS_header
FITS_data
FITS_table
FITS_name
```
## Using FITS files

By the command `f = fits_read("filnam.fits")` we asign a collection of [`FITS_HDU`](@ref) objects from the file `"filnam.fits"` to the variable `f`.

---


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