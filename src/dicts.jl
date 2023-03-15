# SPDX-License-Identifier: MIT

# ========================== dictDefinedTerms ===========================


dictDefinedTerms = Dict("ANSI" => "American National Standards Institute.",
    "Array" => "A sequence of data values. \nThis sequence corresponds to the elements in a rectilinear, n-dimensional matrix (1 ≤ n ≤ 999, or n = 0 in the case of a null array).",
    "Array value" => "The value of an element of an array in a FITS file, without the application of the associated linear transformation to derive the physical value.",
    "ASCII" => "American National Standard Code for Information Interchange.",
    "ASCII character" => "Any member of the seven-bit ASCII character set.",
    "ASCII digit" => "One of the ten ASCII characters ‘0’ through ‘9’, which are represented by decimal character codes 48 through 57 (hexadecimal 30 through 39).",
    "ASCII NULL" => "The ASCII character that has all eight bits set to zero.",
    "ASCII space" => "The ASCII character for space, which is represented by decimal 32 (hexadecimal 20).",
    "ASCII text" => "The restricted set of ASCII characters decimal 32 through 126 (hexadecimal 20 through 7E).",
    "Basic FITS" => "The FITS structure consisting of the primary header followed by a single primary data array. \nThis is also known as Single Image FITS (SIF), as opposed to Multi-Extension FITS (MEF) files that contain one or more extensions following the primary HDU.",
    "Big endian" => "The numerical data format used in FITS files in which the most-significant byte of the value is stored first followed by the remaining bytes in order of significance.",
    "Bit" => "A single binary digit.",
    "Byte" => "An ordered sequence of eight consecutive bits treated as a single entity.",
    "Card image" => "An obsolete term for an 80-character keyword record derived from the 80-column punched computer cards that were prevalent in the 1960s and 1970s.",
    "Character string" => "A sequence of one or more of the restricted set of ASCII-text characters, decimal 32 through 126 (hexadecimal 20 through 7E).",
    "Conforming extension" => "An extension whose keywords and organization adhere to the requirements for conforming extensions defined in Sect. 3.4.1 of this Standard.",
    "Data block" => "A 2880-byte FITS block containing data described by the keywords in the associated header of that HDU.",
    "Deprecate" => "To express disapproval of. \nThis term is used to refer to obsolete structures that should not be used in new FITS files, but which shall remain valid indefinitely.",
    "Entry" => "A single value in an ASCII-table or binary-table standard extension.",
    "Extension" => "A FITS HDU appearing after the primary HDU in a FITS file.",
    "Extension type name" => "The value of the XTENSION keyword, used to identify the type of the extension.",
    "Field" => "A component of a larger entity, such as a keyword record or a row of an ASCII-table or binary-table standard extension. \nA field in a table-extension row consists of a set of zero-or-more table entries collectively described by a single format.",
    "File" => "A sequence of one or more records terminated by an endof-file indicator appropriate to the medium.",
    "FITS" => "Flexible Image Transport System.",
    "FITS block" => "A sequence of 2880 eight-bit bytes aligned on 2880-byte boundaries in the FITS file, most commonly either a header block or a data block. \nSpecial records are another infrequently used type of FITS block. \nThis block length was chosen because it is evenly divisible by the byte and word lengths of all known computer systems at the time FITS was developed in 1979.",
    "FITS file" => "A file with a format that conforms to the specifications in this document.",
    "FITS structure" => ", the random-groups records, an extension, or, collectively, the special records following the last extension.",
    "FITS Support Office" => "The FITS information website that is maintained by the IAUFWG and is currently hosted at http://fits.gsfc.nasa.gov.",
    "Floating point" => "A computer representation of a real number.",
    "Fraction" => "The field of the mantissa (or significand) of a floatingpoint number that lies to the right of its implied binary point.",
    "Group parameter value" => "The value of one of the parameters preceding a group in the random-groups structure, without the application of the associated linear transformation.",
    "HDU Header and Data Unit." => "A data structure consisting of a header and the data the header describes. \nNote that an HDU may consist entirely of a header with no data blocks.",
    "Header" => "A series of keyword records organized within one or more header blocks that describes structures and/or data that follow it in the FITS file.",
    "Header block" => "A 2880-byte FITS block containing a sequence of thirty-six 80-character keyword records.",
    "Heap" => "The supplemental data area following the main data table in a binary-table standard extension.",
    "IAU" => "International Astronomical Union.",
    "IAUFWG" => "International Astronomical Union FITS Working Group.",
    "IEEE" => "Institute of Electrical and Electronic Engineers.",
    "IEEE NaN" => "IEEE Not-a-Number value; used to represent undefined floating-point values in FITS arrays and binary tables.",
    "IEEE special values" => "Floating-point number byte patterns that have a special, reserved meaning, such as −0, ±∞, ±underflow, ±overflow, ±denormalized, ±NaN.",
    "Indexed keyword" => "A keyword name that is of the form of a fixed root with an appended positive integer index number.",
    "Keyword name" => "The first eight bytes of a keyword record, which contain the ASCII name of a metadata quantity (unless it is blank).",
    "Keyword record" => "An 80-character record in a header block consisting of a keyword name in the first eight characters followed by an optional value indicator, value, and comment string. \nThe keyword record shall be composed only of the restricted set of ASCII-text characters ranging from decimal 32 to 126 (hexadecimal 20 to 7E).",
    "Mandatory keyword" => "A keyword that must be used in all FITS files or a keyword required in conjunction with particular FITS structures.",
    "Mantissa" => "Also known as significand. \nThe component of an IEEE floating-point number consisting of an explicit or implicit leading bit to the left of its implied binary point and a fraction field to the right.",
    "MEF" => "Multi-Extension FITS, i.e., a FITS file containing a primary HDU followed by one or more extension HDUs.",
    "NOST" => "NASA/Science Office of Standards and Technology.",
    "Physical value" => "The value in physical units represented by an element of an array and possibly derived from the array value using the associated, but optional, linear transformation.",
    "Pixel" => "Short for ‘Picture element’; a single location within an array.",
    "Primary data array" => "The data array contained in the primary HDU.",
    "Primary HDU" => "The first HDU in a FITS file.",
    "Primary header" => "The first header in a FITS file, containing information on the overall contents of the file (as well as on the primary data array, if present).",
    "Random Group" => "A FITS structure consisting of a collection of ‘groups’, where a group consists of a subarray of data and a set of associated parameter values. \nRandom groups are deprecated for any use other than for radio interferometry data.",
    "Record" => "A sequence of bits treated as a single logical entity.",
    "Repeat count" => "The number of values represented in a field in a binary-table standard extension.",
    "Reserved keyword" => "An optional keyword that must be used only in the manner defined in this Standard.",
    "SIF" => "Single Image FITS, i.e., a FITS file containing only a primary HDU, without any extension HDUs. \nAlso known as Basic FITS.",
    "Special records" => "A series of one or more FITS blocks following the last HDU whose internal structure does not otherwise conform to that for the primary HDU or to that specified for a conforming extension in this Standard. \nAny use of special records requires approval from the IAU FITS Working Group.",
    "Standard extension" => "A conforming extensionwhose header and data content are completely specified in Sect. 7 of this Standard, namely, an image extension, an ASCII-table extension, or a binary-table extension."
)


# ..............................................................................
function _suggest(dict::Dict, term::String)

    o = sort(collect(keys(dict)))
    a = [o[i][1] for i ∈ eachindex(o)]
    X = Base.Unicode.uppercase(term[1])

    itr = findall(x -> x == X, a)

    str = term * ":"
    str *= "\nNot one of the FITS defined terms."
    str *= "\nsuggestions: "
    for i ∈ itr
        str *= o[i]
        str *= ", "
    end

    str = str[1:end-2]
    str *= ".\n\nsee FITS Standard (Version 4.0) - https://fits.gsfc.nasa.gov/fits_standard.html"

    return str

end
@doc raw"""
    definition(term::String)

Definition of *defined terms* from [FITS standard - Version 4.0](https://fits.gsfc.nasa.gov/fits_standard.html)
```
julia> fits_defined_term("FITS")
FITS:
Flexible Image Transport System.

julia> get(dictDefinedTerms, "FITS", nothing)
"Flexible Image Transport System."

julia> fits_defined_term("p")
p:
Not one of the FITS defined terms.
suggestions: Physical value, Pixel, Primary HDU, Primary data array, Primary header.

see FITS Standard (Version 4.0) - https://fits.gsfc.nasa.gov/fits_standard.html
```
"""
function fits_defined_term(term::String)

    term = isnothing(term) ? "" : term
    dict = dictDefinedTerms

    length(term) > 0 || return fits_defined_term()

    o = sort(collect(keys(dict)))
    u = [Base.uppercase(o[i]) for i ∈ eachindex(o)]
    X = Base.Unicode.uppercase(term)

    itr = findall(x -> x == X, u)

    str = length(itr) == 0 ? _suggest(dict::Dict, term::String) :
          (o[itr][1] * ":\n" * Base.get(dict, o[itr][1], nothing))
    return println(str)

end
function fits_defined_term()

    dict = dictDefinedTerms

    o = sort(collect(keys(dict)))

    str = "FITS defined terms:\n"
    for i ∈ eachindex(o)
        str *= o[i]
        str *= ", "
    end

    str = str[1:end-2]

    str *= ".\n\nsee FITS Standard (Version 4.0) - https://fits.gsfc.nasa.gov/fits_standard.html"

    return println(str)

end