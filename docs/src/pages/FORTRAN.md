# FORTRAN

## Objects 

```@docs
FORTRAN_format
```

## Object casting

```@docs
cast_FORTRAN_format(str::String)
```

## FORTRAN-related methods

```@docs
FORTRAN_eltype_char(T::Type)
FORTRAN_fits_table_tform(col::Vector{T}) where {T}
parse_FITS_TABLE(hdu::FITS_HDU)
```