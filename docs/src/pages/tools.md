# FITS Tools

## FITS information tools

```@docs
fits_info(hdu::FITS_HDU; nr=true, msg=true)
fits_record_dump(filnam::String, hduindex=0; hdr=true, dat=true, nr=true, msg=true)
parse_FITS_TABLE(hdu::FITS_HDU)
```

## FITS creation and file-handling tools

#### FITS creation, extension and collection

```@docs
fits_create(filnam::String, data=nothing; protect=true, msg=true)
fits_extend!(f::FITS, data_extend; hdutype="IMAGE")
fits_collect(filnamFirst::String, filnamLast::String; protect=true)
```

#### FITS reading, copying and saving
```@docs
fits_read(filnam::String)
fits_save_as(f::FITS, filnam::String; protect=true)
fits_copy(fileStart::String, fileStop::String=" "; protect=true)
```

## FITS keyword tools

```@docs
fits_add_key!(f::FITS, hduindex::Int, key::String, val::Any, com::String)
fits_delete_key!(f::FITS, hduindex::Int, key::String)
fits_edit_key!(f::FITS, hduindex::Int, key::String, val::Real, com::String)
fits_rename_key!(f::FITS, hduindex::Int, keyold::String, keynew::String)
```
