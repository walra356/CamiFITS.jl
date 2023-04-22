# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#     dictTest
# ------------------------------------------------------------------------------

dictTest = Dict(
    1 => "filename test",
    2 => "block test",
    3 => "record count test"
)

# ------------------------------------------------------------------------------
#     dictPass
# ------------------------------------------------------------------------------

dictPass = Dict(
    1 => "file exists in conformance with the CamiFITS naming convention.",
    2 => "integer number of blocks (of 2880 bytes).",
    3 => "header consists of integer number of blocks (of 36 records)"
)

# ------------------------------------------------------------------------------
#     dictFail
# ------------------------------------------------------------------------------

dictFail = Dict(
    1 => "file not found.",
    2 => "not integer number of blocks (of 2880 bytes).",
    3 => "header does not consist of integer number of 36-record blocks"
)

# ------------------------------------------------------------------------------
#     dictWarn
# ------------------------------------------------------------------------------

dictWarn = Dict(
    1 => "filename not conform the CamiFITS naming convention."
)

# ------------------------------------------------------------------------------
#     dictHint
# ------------------------------------------------------------------------------

dictHint = Dict(
    0 => "file in use - set 'protect=false' to lift overwrite protection",
    1 => "file in use - set 'protect=false' to lift overwrite protection"
)

# ------------------------------------------------------------------------------
#     dictErr
# ------------------------------------------------------------------------------

dictErr = Dict(0 => nothing,
    1 => "file not found",
    2 => "filename lacks mandatory '.fits' extension",
    3 => "filnam lacks mandatory 'name' specificaton",
    4 => "filnam in use - set 'protect=false' to overrule overwrite protection",
    5 => "incorrect DataType (Real type mandatory for image HDUs)",
    6 => "FITS format requires integer number of blocks (of 2880 bytes)",
    7 => "illegal keyword value (keyword in use)",
    8 => "header shall consist of integer number of blocks (of 36 records)",
    9 => "leading zeros not allowed in mandatory indexed keywords.",
    10 => "illegal keyword value (exceeds 8 charaters).",
    11 => "mandatory keyword not present or out of order.",
    12 => "mandatory keyword has wrong datatype or illegal value.",
    13 => "END keyword not found.",
    14 => "illegal keyword value (not 'single quote' delimited string')",
    15 => "illegal keyword value (not 'numeric', 'date' or 'single quote' delimited string')",
    16 => "illegal keyword value type",
    17 => "mandatory keyword",
    23 => "header contains illegal ASCII character (not ASCCI 32 - 126)",
    24 => "keyword contains illegal character."
)

# ------------------------------------------------------------------------------
#     dictError
# ------------------------------------------------------------------------------

dictError = Dict(0 => nothing,
    1 => "file not found",
    2 => "filename lacks mandatory '.fits' extension",
    3 => "filnam lacks mandatory 'name' specificaton",
    4 => "filnam in use - set '; protect=false' to overrule overwrite protection",
    5 => "incorrect DataType (Real type mandatory for image HDUs)",
    6 => "FITS format requires integer number of blocks (of 2880 bytes)",
    7 => "key in use (use different name or edit key)",# _write_IMAGE_data(FITS_HDU)
    8 => "header shall consist of integer number of blocks (of 36 records)",
    9 => "header blocks shall contain only the restricted set of ASCII text characters, decimal 32 through 126.",
    10 => "illegal keyword (exceeds 8 charaters).",
    11 => "mandatory keyword not present or out of order.",
    12 => "mandatory keyword has wrong datatype or illegal value.",
    13 => "END header keyword not present.",
    23 => "header contains illegal ASCII character (not ASCCI 32 - 126)",
    24 => "keyword contains illegal character."
)

# ------------------------------------------------------------------------------
# dictDefinedTerms
# ------------------------------------------------------------------------------

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
    "HDU" => "Header and Data Unit. A data structure consisting of a header and the data the header describes. \nNote that an HDU may consist entirely of a header with no data blocks.",
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

# ------------------------------------------------------------------------------
#  fits_terminology()
# ..............................................................................
function _suggest(dict::Dict, term::String; test=false)

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

    return test ? true : str

end
@doc raw"""
    fits_terminology([term::String [; test=false]])

Description of the *defined terms* from [FITS standard - Version 4.0](https://fits.gsfc.nasa.gov/fits_standard.html): 

ANSI, ASCII, ASCII NULL, ASCII character, ASCII digit, ASCII space, ASCII text, 
Array, Array value, Basic FITS, Big endian, Bit, Byte, Card image, 
Character string, Conforming extension, Data block, Deprecate, Entry, 
Extension, Extension type name, FITS, FITS Support Office, FITS block, 
FITS file, FITS structure, Field, File, Floating point, Fraction, 
Group parameter value, HDU Header and Data Unit., Header, Header block, Heap, 
IAU, IAUFWG, IEEE, IEEE NaN, IEEE special values, Indexed keyword, 
Keyword name, Keyword record, MEF, Mandatory keyword, Mantissa, NOST, 
Physical value, Pixel, Primary HDU, Primary data array, Primary header, 
Random Group, Record, Repeat count, Reserved keyword, SIF, Special records, 
Standard extension.
```
julia> fits_terminology()
FITS defined terms:
ANSI, ASCII, ASCII NULL, ASCII character, ..., SIF, Special records, Standard extension.

julia> fits_terminology("FITS")
FITS:
Flexible Image Transport System.

julia> get(dictDefinedTerms, "FITS", nothing)
"Flexible Image Transport System."

julia> fits_terminology("p")
p:
Not one of the FITS defined terms.
suggestions: Physical value, Pixel, Primary HDU, Primary data array, Primary header.

see FITS Standard (Version 4.0) - https://fits.gsfc.nasa.gov/fits_standard.html
```
"""
function fits_terminology(term::String; test=false)

    term = isnothing(term) ? "" : term
    dict = dictDefinedTerms

    length(term) > 0 || return fits_terminology()

    o = sort(collect(keys(dict)))
    u = [Base.uppercase(o[i]) for i ∈ eachindex(o)]
    X = Base.Unicode.uppercase(term)

    itr = findall(x -> x == X, u)

    str = length(itr) == 0 ? _suggest(dict::Dict, term::String; test) :
          (o[itr][1] * ":\n" * Base.get(dict, o[itr][1], nothing))

    test ? (return str) : println(str)

end
function fits_terminology(; test=false)

    dict = dictDefinedTerms

    o = sort(collect(keys(dict)))

    str = "FITS defined terms:\n"
    for i ∈ eachindex(o)
        str *= o[i]
        str *= ", "
    end

    str = str[1:end-2]

    str *= ".\n\nsee FITS Standard (Version 4.0) - https://fits.gsfc.nasa.gov/fits_standard.html"

    test ? true : println(str)

end

_fits_standard = "FITS Standard - https://fits.gsfc.nasa.gov/fits_standard.html"

dictDefinedKeywords = Dict(
    "        " => ("(blank)", _fits_standard, "reserved", "any", "none", "", "descriptive comment",
        "Columns 1-8 contain ASCII blanks. This keyword has no associated value.  Columns 9-80 may contain any ASCII text.  
Any number of card images with blank keyword fields may appear in a header."),
    "AUTHOR" => ("AUTHOR", _fits_standard, "reserved", "any", "string", "", "author of the data",
        "The value field shall contain a character string identifying who compiled the information in the data associated with the header. 
This keyword is appropriate when the data originate in a published paper or are compiled from many sources."),
    "BITPIX" => ("BITPIX", _fits_standard, "manditory", "any", "integer", "RANGE:      -64,-32,8,16,32", "bits per data value",
        "The value field shall contain an integer.  
The absolute value is used in computing the sizes of data structures.  
It shall specify the number of bits that represent a data value."),
    "BLANK" => ("BLANK", _fits_standard, "reserved", "image", "integer", "", "value used for undefined array elements",
        "This keyword shall be used only in primary array headers or IMAGE extension headers with positive values of BITPIX (i.e., in arrays with integer data). 
Columns 1-8 contain the string, `BLANK   ' (ASCII blanks in columns 6-8). 
The value field shall contain an integer that specifies the representation of array values whose physical values are undefined."),
    "BLOCKED" => ("BLOCKED", _fits_standard, "reserved", "primary", "logical", "", "is physical blocksize a multiple of 2880?",
        "This keyword may be used only in the primary header.  It shall appear within the first 36 card images of the FITS file. 
(Note: This keyword thus cannot appear if NAXIS is greater than 31, or if NAXIS is greater than 30 and the EXTEND keyword is present.) 
Its presence with the required logical value of T advises that the physical block size of the FITS file on which it appears may be an integral multiple of the logical record length, and not necessarily equal to it. 
Physical block size and logical record length may be equal even if this keyword is present or unequal if it is absent.  
It is reserved primarily to prevent its use with other meanings. Since the issuance of version 1 of the standard, the BLOCKED keyword has been deprecated."),
    "BSCALE" => ("BSCALE", _fits_standard, "reserved", "image", "real", "DEFAULT:    1.0", "linear factor in scaling equation",
        "This keyword shall be used, along with the BZERO keyword, when the array pixel values are not the true physical values, to transform the primary data array values to the true physical values they represent, using the equation: physical_value = BZERO + BSCALE * array_value.  
The value field shall contain a floating point number representing the coefficient of the linear term in the scaling equation, the ratio of physical value to array value at zero offset. 
The default value for this keyword is 1.0."),
    "BUNIT" => ("BUNIT", _fits_standard, "reserved", "image", "string", "", "physical units of the array values",
        "The value field shall contain a character string, describing the physical units in which the quantities in the array, after application of BSCALE and BZERO, are expressed.
The units of all FITS header keyword values, with the exception of measurements of angles, should conform with the recommendations in the IAU Style Manual. 
For angular measurements given as floating point values and specified with reserved keywords, degrees are the recommended units (with the units, if specified, given as 'deg')."),
    "BZERO" => ("BZERO", _fits_standard, "reserved", "image", "real", "DEFAULT:    0.0", "zero point in scaling equation",
        "This keyword shall be used, along with the BSCALE keyword, when the array pixel values are not the true physical values, to transform the primary data array values to the true values using the equation: physical_value = BZERO + BSCALE * array_value. 
The value field shall contain a floating point number representing the physical value corresponding to an array value of zero.
The default value for this keyword is 0.0."),
    "CDELTn" => ("CDELTn", _fits_standard, "reserved", "image", "real", "", "coordinate increment along axis",
        "The value field shall contain a floating point number giving the partial derivative of the coordinate specified by the CTYPEn keywords with respect to the pixel index, evaluated at the reference point CRPIXn, in units of the coordinate specified by  the CTYPEn keyword.  
These units must follow the prescriptions of section 5.3 of the FITS Standard."),
    "COMMENT" => ("COMMENT", _fits_standard, "reserved", "any", "none", "", "descriptive comment",
        "This keyword shall have no associated value; columns 9-80 may contain any ASCII text.  
Any number of COMMENT card images may appear in a header."),
    "CROTAn" => ("CROTAn", _fits_standard, "reserved", "image", "real", "UNITS:      degrees", "coordinate system rotation angle",
        "This keyword is used to indicate a rotation from a standard coordinate system described by the CTYPEn to a different coordinate system in which the values in the array are actually expressed. 
Rules for such rotations are not further specified in the Standard; the rotation should be explained in comments.
The value field shall contain a floating point number giving the rotation angle in degrees between axis n and the direction implied by the coordinate system defined by CTYPEn."),
    "CRPIXn" => ("CRPIXn", _fits_standard, "reserved", "image", "real", "", "coordinate system reference pixel",
        "The value field shall contain a floating point number, identifying the location of a reference point along axis n, in units of the axis index.  
This value is based upon a counter that runs from 1 to NAXISn with an increment of 1 per pixel.  
The reference point value need not be that for the center of a pixel nor lie within the actual data array. 
Use comments to indicate the location of the index point relative to the pixel."),
    "CRVALn" => ("CRVALn", _fits_standard, "reserved", "image", "real", "", "coordinate system value at reference pixel",
        "The value field shall contain a floating point number, giving the value of the coordinate specified by the CTYPEn keyword at the reference point CRPIXn.
Units must follow the prescriptions of section 5.3 of the FITS Standard."),
    "CTYPEn" => ("CTYPEn", _fits_standard, "reserved", "image", "string", "", "name of the coordinate axis",
        "The value field shall contain a character string, giving the name of the coordinate represented by axis n."),
    "DATAMAX" => ("DATAMAX", _fits_standard, "reserved", "image", "real", "", "maximum data value",
        "The value field shall always contain a floating point number, regardless of the value of BITPIX. 
This number shall give the maximum valid physical value represented by the array, exclusive of any special values."),
    "DATAMIN" => ("DATAMIN", _fits_standard, "reserved", "image", "real", "", "minimum data value",
        "The value field shall always contain a floating point number, regardless of the value of BITPIX. 
This number shall give the minimum valid physical value represented by the array, exclusive of any special values."),
    "DATE" => ("DATE", _fits_standard, "reserved", "any", "string", "", "date of file creation",
        "The date on which the HDU was created, in the format specified in the FITS Standard.  
The old date format was 'yy/mm/dd' and may be used only for dates from 1900 through 1999. 
The new Y2K compliant date format is 'yyyy-mm-dd' or 'yyyy-mm-ddTHH:MM:SS[.sss]'."),
    "DATE-OBS" => ("DATE-OBS", "FITS Stadard", "reserved", "any", "string", "", "date of the observation",
        "The date of the observation, in the format specified in the FITS Standard. 
The old date format was 'yy/mm/dd' and may be used only for dates from 1900 through 1999.  
The new Y2K compliant date format is 'yyyy-mm-dd' or 'yyyy-mm-ddTHH:MM:SS[.sss]'."),
    "END" => ("END", _fits_standard, "mandatory", "any", "none", "", "marks the end of the header keywords",
        "This keyword has no associated value.  Columns 9-80 shall be filled with ASCII blanks."),
    "EPOCH" => ("EPOCH", _fits_standard, "reserved", "any", "real", "", "equinox of celestial coordinate system",
        "The value field shall contain a floating point number giving the equinox in years for the celestial coordinate system in which positions are expressed.  
Starting with Version 1, the Standard has deprecated the use of the EPOCH keyword and thus it shall not be used in FITS files created after the adoption of the standard; rather, the EQUINOX keyword shall be used."),
    "EQUINOX" => ("EQUINOX", _fits_standard, "reserved", "any", "real", "", "equinox of celestial coordinate system",
        "The value field shall contain a floating point number giving the equinox in years for the celestial coordinate system in which positions are expressed."),
    "EXTEND" => ("EXTEND", _fits_standard, "reserved", "primary", "logical", "", "may the FITS file contain extensions?",
        "If the FITS file may contain extensions, a card image with the keyword EXTEND and the value field containing the logical value T must appear in the primary header immediately after the last NAXISn card image, or, if NAXIS=0, the NAXIS card image.
The presence of this keyword with the value T in the primary header does not require that extensions be present."),
    "EXTLEVEL" => ("EXTLEVEL", _fits_standard, "reserved", "extension", "integer", "RANGE:      [1:] \nDEFAULT:    1", "hierarchical level of the extension",
        "The value field shall contain an integer, specifying the level in a hierarchy of extension levels of the extension header containing it. 
The value shall be 1 for the highest level; levels with a higher value of this keyword shall be subordinate to levels with a lower value. 
If the EXTLEVEL keyword is absent, the file should be treated as if the value were 1. 
This keyword is used to describe an extension and should not appear in the primary header."),
    "EXTNAME" => ("EXTNAME", _fits_standard, "reserved", "extension", "string", "", "name of the extension",
        "The value field shall contain a character string, to be used to distinguish among different extensions of the same type, i.e., with the same value of XTENSION, in a FITS file.  
This keyword is used to describe an extension and should not appear in the primary header."),
    "EXTVER" => ("EXTVER", _fits_standard, "reserved", "extension", "integer", "RANGE:      [1:] \nDEFAULT:    1", "version of the extension",
        "The value field shall contain an integer, to be used to distinguish among different extensions in a FITS file with the same type and name, i.e., the same values for XTENSION and EXTNAME. 
The values need not start with 1 for the first extension with a particular value of EXTNAME and need not be in sequence for subsequent values. 
If the EXTVER keyword is absent, the file should be treated as if the value were 1.  
This keyword is used to describe an extension and should not appear in the primary header."),
    "GCOUNT" => ("GCOUNT", _fits_standard, "mandatory", "extension", "integer", "", "group count",
        "The value field shall contain an integer that shall be used in any way appropriate to define the data structure, consistent with Eq.5.2 in the FITS Standard. 
This keyword originated for use in FITS Random Groups where it specifies the number of random groups present. 
In most other cases this keyword will have the value 1."),
    "GROUPS" => ("GROUPS", _fits_standard, "mandatory", "groups", "logical", "", "indicates random groups structure",
        "The value field shall contain the logical constant T.  
The value T associated with this keyword implies that random groups records are present."),
    "HISTORY" => ("HISTORY", _fits_standard, "reserved", "any", "none", "", "processing history of the data",
        "This keyword shall have no associated value; columns 9-80 may contain any ASCII text.  
The text should contain a history of steps and procedures associated with the processing of the associated data. 
Any number of HISTORY card images may appear in a header."),
    "INSTRUME" => ("INSTRUME", _fits_standard, "reserved", "any", "string", "", "name of instrument",
        "The value field shall contain a character string identifying the instrument used to acquire the data associated with the header."),
    "NAXIS" => ("NAXIS", _fits_standard, "mandatory", "any", "integer", "RANGE:      [0:999]", "number of axes",
        "The value field shall contain a non-negative integer no greater than 999, representing the number of axes in the associated data array. 
A value of zero signifies that no data follow the header in the HDU.  
In the context of FITS 'TABLE' or 'BINTABLE' extensions, the value of NAXIS is always 2."),
    "NAXISn" => ("NAXISn", _fits_standard, "mandatory", "any", "integer", "RANGE:      [0:]", "size of the axis",
        "The value field of this indexed keyword shall contain a non-negative integer, representing the number of elements along axis n of a data array.  
The NAXISn must be present for all values n = 1,...,NAXIS, and for no other values of n. 
A value of zero for any of the NAXISn signifies that no data follow the header in the HDU. 
If NAXIS is equal to 0, there should not be any NAXISn keywords."),
    "OBJECT" => ("OBJECT", _fits_standard, "reserved", "any", "string", "", "name of observed object",
        "The value field shall contain a character string giving a name for the object observed."),
    "OBSERVER" => ("OBSERVER", _fits_standard, "reserved", "any", "string", "", "observer who acquired the data",
        "The value field shall contain a character string identifying who acquired the data associated with the header."),
    "ORIGIN" => ("ORIGIN", _fits_standard, "reserved", "any", "string", "", "organization responsible for the data",
        "The value field shall contain a character string identifying the organization or institution responsible for creating the FITS file."),
    "PCOUNT" => ("PCOUNT", _fits_standard, "mandatory", "extension", "integer", "", "parameter count",
        "The value field shall contain an integer that shall be used in any way appropriate to define the data structure, consistent with Eq.5.2 in the FITS Standard. 
This keyword was originated for use with FITS Random Groups and represented the number of parameters preceding each group. 
It has since been used in 'BINTABLE' extensions to represent the size of the data heap following the main data table. 
In most other cases its value will be zero."),
    "PSCALn" => ("PSCALn", _fits_standard, "reserved", "groups", "real", "DEFAULT:    1.0", "parameter scaling factor",
        "This keyword is reserved for use within the FITS Random Groups structure. 
This keyword shall be used, along with the PZEROn keyword, when the nth FITS group parameter value is not the true physical value, to transform the group parameter value to the true physical values it represents, using the equation, physical_value = PZEROn + PSCALn * group_parameter_value. 
The value field shall contain a floating point number representing the coefficient of the linear term, the scaling factor between true values and group parameter values at zero offset.  
The default value for this keyword is 1.0."),
    "PTYPEn" => ("PTYPEn", _fits_standard, "reserved", "groups", "string", "", "name of random groups parameter",
        "This keyword is reserved for use within the FITS Random Groups structure.  
The value field shall contain a character string giving the name of parameter n.  
If the PTYPEn keywords for more than one value of n have the same associated name in the value field, then the data value for the parameter of that name is to be obtained by adding the derived data values of the corresponding parameters. 
This rule provides a mechanism by which a random parameter may have more precision than the accompanying data array elements; 
for example, by summing two 16-bit values with the first scaled relative to the other such that the sum forms a number of up to 32-bit precision."),
    "PZEROn" => ("PZEROn", _fits_standard, "reserved", "groups", "real", "DEFAULT:    0.0", "parameter scaling zero point",
        "This keyword is reserved for use within the FITS Random Groups structure. 
This keyword shall be used, along with the PSCALn keyword, when the nth FITS group parameter value is not the true physical value, to transform the group parameter value to the physical value. 
The value field shall contain a floating point number, representing the true value corresponding to a group parameter value of zero.  
The default value for this keyword is 0.0.  The transformation equation is as follows: physical_value = PZEROn + PSCALn * group_parameter_value."),
    "REFERENC" => ("REFERENC", _fits_standard, "reserved", "any", "string", "", "bibliographic reference",
        "The value field shall contain a character string citing a reference where the data associated with the header are published."),
    "SIMPLE" => ("SIMPLE", _fits_standard, "mandatory", "primary", "logical", "", "does file conform to the Standard?",
        "The SIMPLE keyword is required to be the first keyword in the primary header of all FITS files. 
The value field shall contain a logical constant with the value T if the file conforms to the standard. 
This keyword is mandatory for the primary header and is not permitted in extension headers. A value of F signifies that the file does not conform to this standard."),
    "TBCOLn" => ("TBCOLn", _fits_standard, "mandatory", "ASCII_table", "integer", "RANGE:      [1:]", "begining column number",
        "The value field of this indexed keyword shall contain an integer specifying the column in which field n starts in an ASCII TABLE extension.  
The first column of a row is numbered 1."),
    "TDIMn" => ("TDIMn", _fits_standard, "reserved", "BINTABLE", "string", "", "dimensionality of the array ",
        "The value field of this indexed keyword shall contain a character string describing how to interpret the contents of field n as a multidimensional array, providing the number of dimensions and the length along each axis.
The form of the value is not further specified by the Standard.  
A proposed convention is described in Appendix B.2 of the FITS Standard in which the value string has the format '(l,m,n...)' where l, m, n,... are the dimensions of the array."),
    "TDISPn" => ("TDISPn", _fits_standard, "reserved", "table", "string", "", "display format",
        " The value field of this indexed keyword shall contain a character string describing the format recommended for the display of the contents of field n.  
If the table value has been scaled, the physical value shall be displayed. All elements in a field shall be displayed with a single, repeated format. 
For purposes of display, each byte of bit (type X) and byte (type B) arrays is treated as an unsigned integer. Arrays of type A may be terminated with a zero byte.  
Only the format codes in Table 8.6, discussed in section 8.3.4 of the FITS Standard, are permitted for encoding. 
The format codes must be specified in upper case. If the Bw.m, Ow.m, and Zw.m formats are not readily available to the reader, the Iw.m display format may be used instead, and if the ENw.d and ESw.d formats are not available, Ew.d may be used.  
The meaning of this keyword is not defined for fields of type P in the Standard but may be defined in conventions using such fields."),
    "TELESCOP" => ("TELESCOP", _fits_standard, "reserved", "any", "string", "", "name of telescope",
        "The value field shall contain a character string identifying the telescope used to acquire the data associated with the header."),
    "TFIELDS" => ("TFIELDS", _fits_standard, "mandatory", "table", "integer", "RANGE:      [0:999]", "number of columns in the table",
        "The value field shall contain a non-negative integer representing the number of fields in each row of a 'TABLE' or 'BINTABLE' extension.  
The maximum permissible value is 999."),
    "TFORMn" => ("TFORMn", _fits_standard, "mandatory", "table", "string", "", "column data format",
        "The value field of this indexed keyword shall contain a character string describing the format in which field n is encoded in a 'TABLE' or 'BINTABLE' extension."),
    "THEAP" => ("THEAP", _fits_standard, "reserved", "BINTABLE", "integer", "", "offset to starting data heap address",
        "The value field of this keyword shall contain an integer providing the separation, in bytes, between the start of the main data table and the start of a supplemental data area called the heap.  
The default value shall be the product of the values of NAXIS1 and NAXIS2. This keyword shall not be used if the value of PCOUNT is zero.  
A proposed application of this keyword is presented in Appendix B.1 of the FITS Standard."),
    "TNULLn" => ("TNULLn", "FITS Stadard", "reserved", "table", "integer or string", "", "value used to indicate undefined table element",
        "In ASCII 'TABLE' extensions, the value field for this indexed keyword shall contain the character string that represents an undefined value for field n.  
The string is implicitly blank filled to the width of the field.  
In binary 'BINTABLE' table extensions, the value field for this indexed keyword shall contain the integer that represents an undefined value for field n of data type B, I, or J. 
The keyword may not be used in 'BINTABLE' extensions if field n is of any other data type."),
    "TSCALn" => ("TSCALn", _fits_standard, "reserved", "table", "real", "DEFAULT:    1.0", "linear data scaling factor",
        "This indexed keyword shall be used, along with the TZEROn keyword, when the quantity in field n does not represent a true physical quantity.  
The value field shall contain a floating point number representing the coefficient of the linear term in the equation, 
physical_value = TZEROn + TSCALn * field_value, which must be used to compute the true physical value of the field, or, in the case of the complex data types C and M, of the real part of the field with the imaginary part of the scaling factor set to zero.
The default value for this keyword is 1.0.  
This keyword may not be used if the format of field n is A, L, or X."),
    "TTYPEn" => ("TTYPEn", "FITS Stadard", "reserved", "table", "string", "", "column name",
        "The value field for this indexed keyword shall contain a character string, giving the name of field n.  
It is recommended that only letters, digits, and underscore (hexadecimal code 5F, ('_') be used in the name.  
String comparisons with the values of TTYPEn keywords should not be case sensitive.  
The use of identical names for different fields should be avoided."),
    "TUNITn" => ("TUNITn", "FITS Stadard", "reserved", "table", "string", "", "column units",
        "The value field shall contain a character string describing the physical units in which the quantity in field n, after any application of TSCALn and TZEROn, is expressed.   
The units of all FITS header keyword values, with the exception of measurements of angles, should conform with the recommendations in the IAU Style Manual. 
For angular measurements given as floating point values and specified with reserved keywords, degrees are the recommended units (with the units, if specified, given as 'deg')."),
    "TZEROn" => ("TZEROn", _fits_standard, "reserved", "table", "real", "DEFAULT:    0.0", "column scaling zero point",
        "This indexed keyword shall be used, along with the TSCALn keyword, when the quantity in field n does not represent a true physical quantity.  
The value field shall contain a floating point number representing the true physical value corresponding to a value of zero in field n of the FITS file, 
or, in the case of the complex data types C and M, in the real part of the field, with the imaginary part set to zero. The default value for this keyword is 0.0.
This keyword may not be used if the format of field n is A, L, or X."),
    "XTENSION" => ("XTENSION", "FITS Stadard", "mandatory", "extension", "string", "", "marks beginning of new HDU",
        "The value field shall contain a character string giving the name of the extension type. This keyword is mandatory for an extension header and must not appear in the primary header.  
For an extension that is not a standard extension, the type name must not be the same as that of a standard extension."))

# ==============================================================================
#                            fits_keyword(keyword)
# ..............................................................................

function _suggest_keyword(dict::Dict, keyword::String)

    o = sort(collect(keys(dict)))
    u = [o[i][1] for i ∈ eachindex(o)]
    X = Base.Unicode.uppercase(keyword[1])

    itr = findall(x -> x == X, u)

    str = keyword * ": "
    str *= "Not recognized as a FITS defined keyword"
    str *= "\nsuggestions: "
    for i ∈ itr
        str *= o[i]
        str *= ", "
    end

    str = str[1:end-2]

    return str *= "\n\nreference: " * _fits_standard

end
function _keyword(keyword)

    isnothing(keyword) && return _keyword()

    keyword = strip(keyword)
    keyword = keyword == "" ? repeat(' ', 8) : keyword

    dict = dictDefinedKeywords

    o = sort(collect(keys(dict)))
    u = [Base.uppercase(o[i]) for i ∈ eachindex(o)]
    X = Base.Unicode.uppercase(keyword)

    itr = findall(x -> x == X, u)

    length(itr) ≠ 0 || return _suggest_keyword(dict, X)

    o = Base.get(dict, o[itr][1], nothing)

    str = "KEYWORD:    " * o[1]
    str *= "\nREFERENCE:  " * o[2]
    str *= "\nSTATUS:     " * o[3]
    str *= "\nHDU:        " * o[4]
    str *= "\nVALUE:      " * o[5]
    o[6] ≠ "" ? (str *= "\n" * o[6]) : false
    str *= "\nCOMMENT:    " * o[7]
    str *= "\nDEFINITION: " * o[8]

    return str

end
function _keyword()

    dict = dictDefinedKeywords

    o = sort(collect(keys(dict)))

    str = "FITS defined keywords:\n\n"
    for i ∈ eachindex(o)
        str *= (isone(i) ? "(blanks) " : rpad(o[i], 9))
        iszero(i % 8) ? str = str * "\n" : false
    end

    # str = str[1:end-2]

    return str *= "\n\nreference: " * _fits_standard

end

@doc raw"""
    fits_keyword(keyword::String)

Description of a keyword from the FITS standard (https://fits.gsfc.nasa.gov/fits_standard.html)
```
julia> fits_keyword("END")
KEYWORD:    END
REFERENCE:  FITS Standard - https://fits.gsfc.nasa.gov/fits_standard.html
STATUS:     mandatory
HDU:        any
VALUE:      none
COMMENT:    marks the end of the header keywords
DEFINITION: This keyword has no associated value.  Columns 9-80 shall be filled with ASCII blanks.

julia> fits_keyword()
FITS defined keywords:

(blanks) AUTHOR   BITPIX   BLANK    BLOCKED  BSCALE   BUNIT    BZERO    
CDELTn   COMMENT  CROTAn   CRPIXn   CRVALn   CTYPEn   DATAMAX  DATAMIN  
DATE     DATE-OBS END      EPOCH    EQUINOX  EXTEND   EXTLEVEL EXTNAME  
EXTVER   GCOUNT   GROUPS   HISTORY  INSTRUME NAXIS    NAXISn   OBJECT   
OBSERVER ORIGIN   PCOUNT   PSCALn   PTYPEn   PZEROn   REFERENC SIMPLE   
TBCOLn   TDIMn    TDISPn   TELESCOP TFIELDS  TFORMn   THEAP    TNULLn   
TSCALn   TTYPEn   TUNITn   TZEROn   XTENSION

reference: FITS Standard - https://fits.gsfc.nasa.gov/fits_standard.html
```
"""
function fits_keyword(keyword::String; msg=true)

    o = _keyword(keyword)

    msg && println(o)
    
    return o

end
function fits_keyword(; msg=true)

    o = _keyword()

    msg && println(o)
    
    return o

end

function fits_keywords()

    dict = dictDefinedKeywords

    o = sort(collect(keys(dict)))

    for i ∈ eachindex(o)
        fits_keyword(o[i])
        println(" ")
    end

end