# SPDX-License-Identifier: MIT

# ========================== dictDefinedTerms ===========================


dictDefinedTerms = Dict("ANSI" => "American National Standards Institute.",
    "Array" => "A sequence of data values. This sequence corresponds to the elements in a rectilinear, n-dimensional matrix (1 ≤ n ≤ 999, or n = 0 in the case of a null array). Array value The value of an element of an array in a FITS file, without the application of the associated linear transformation to derive the physical value.",
    "ASCII" => "American National Standard Code for Information Interchange.",
    "ASCII character" => "Any member of the seven-bit ASCII character set.",
    "ASCII digit" => "One of the ten ASCII characters ‘0’ through ‘9’, which are represented by decimal character codes 48 through 57 (hexadecimal 30 through 39).",
    "ASCII NULL" => "The ASCII character that has all eight bits set to zero.",
    "ASCII space" => "The ASCII character for space, which is represented by decimal 32 (hexadecimal 20).",
    "ASCII text" => "The restricted set of ASCII characters decimal 32 through 126 (hexadecimal 20 through 7E).",
    "Basic FITS" => "The FITS structure consisting of the primary header followed by a single primary data array. This is also known as Single Image FITS (SIF), as opposed to Multi-Extension FITS (MEF) files that contain one or more extensions following the primary HDU.",
    "Big endian" => "The numerical data format used in FITS files in which the most-significant byte of the value is stored first followed by the remaining bytes in order of significance.",
    "Bit" => "A single binary digit.",
    "Byte" => "An ordered sequence of eight consecutive bits treated as a single entity.",
    "Card image" => "An obsolete term for an 80-character keyword record derived from the 80-column punched computer cards that were prevalent in the 1960s and 1970s.",
    "Character string" => "A sequence of one or more of the restricted set of ASCII-text characters, decimal 32 through 126 (hexadecimal 20 through 7E).",
    "Conforming extension" => "An extension whose keywords and organization adhere to the requirements for conforming extensions defined in Sect. 3.4.1 of this Standard.",
    "Data block" => "A 2880-byte FITS block containing data described by the keywords in the associated header of that HDU.",
    "Deprecate" => "To express disapproval of. This term is used to refer to obsolete structures that should not be used in new FITS files, 
    but which shall remain valid indefinitely. Entry A single value in an ASCII-table or binary-table standard extension.",
    "Extension" => "A FITS HDU appearing after the primary HDU in a FITS file.",
    "Extension type name" => "The value of the XTENSION keyword, used to identify the type of the extension.",
    "Field" => "A component of a larger entity, such as a keyword record or a row of an ASCII-table or binary-table standard extension. A field in a table-extension row consists of a set of zero-or-more table entries collectively described by a single format.",
    "File" => "A sequence of one or more records terminated by an endof-file indicator appropriate to the medium.",
    "FITS" => "Flexible Image Transport System.",
    "FITS block" => raw"A sequence of 2880 eight-bit bytes aligned on 2880-byte boundaries\n in the FITS file, most commonly either a header block or a data block. Special records are another infrequently used type of FITS block. This block length was chosen because it is evenly divisible by the byte and word lengths of all known computer systems at the time FITS was developed in 1979.",
    "FITS file" => "A file with a format that conforms to the specifications in this document.",
    "FITS structure" => ", the random-groups records, an extension, or, collectively, the special records following the last extension.",
    "FITS Support Office" => "The FITS information website that is maintained by the IAUFWG and is currently hosted at http://fits.gsfc.nasa.gov.",
    "Floating point" => "A computer representation of a real number.",
    "Fraction" => "The field of the mantissa (or significand) of a floatingpoint number that lies to the right of its implied binary point.",
    "Group parameter value" => "The value of one of the parameters preceding a group in the random-groups structure, without the application of the associated linear transformation.")

@doc raw"""
    definition(term::String)

Definition of *defined terms* from [FITS standard - Version 4.0](https://fits.gsfc.nasa.gov/fits_standard.html)
```
julia> definition("FITS")
FITS: Flexible Image Transport System.

julia> Z = get(dictDefinedTerms, "FITS", nothing)

```
"""
function definition(term::String)

    o = get(dictDefinedTerms, term, "not recognized as defined under the FITS Standard (Version 4.0) - see https://fits.gsfc.nasa.gov/fits_standard.html")

    println(term * ": " * o)

    return o[1:3] == "not" ? false : true

end