# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                            fits_test.jl
#                        Jook Walraven 18-03-2023
# ------------------------------------------------------------------------------

function test_fits_info()

    filnam = "kanweg.fits"

    data = [11, 21, 31, 12, 22, 23, 13, 23, 33]
    data = reshape(data, (3, 3, 1))

    f = fits_create(filnam, data; protect=false)

    a = fits_info(f; msg=false) == data
    b = fits_info(filnam; msg=false) == data  # [1] == '\n'
    
    rm(filnam)

    return a & b

end

function test_fits_create()

    filnam = "minimal.fits"

    f = fits_create(filnam; protect=false)
    a = f.hdu[1].header.card[1].keyword == "SIMPLE"
    b = f.hdu[1].dataobject.data == Any[]
    c = f.hdu[1].header.card[1].value == true
    d = f.hdu[1].header.card[4].value == 0

    rm(filnam)

    filnam = "kanweg.fits"
    data = [11, 21, 31, 12, 22, 23, 13, 23, 33]
    data = reshape(data, (3, 3, 1))

    f = fits_create(filnam, data; protect=false)
    p = f.hdu[1].header.card[1].keyword == "SIMPLE"
    q = f.hdu[1].dataobject.data == data
    r = f.hdu[1].header.card[1].value == true
    s = f.hdu[1].header.card[4].value == 3

    rm(filnam)

    o = a & b & c & d & p & q & r & s

    o || println([a, b, c, d, p, q, r, s])

    return o

end

function test_fits_read()

    filnam = "minimal.fits"

    f = fits_create(filnam; protect=false)
    f = fits_read(filnam)

    a = f.hdu[1].header.card[1].keyword == "SIMPLE"
    b = f.hdu[1].dataobject.data == Any[]
    c = f.hdu[1].header.card[1].value == true
    d = f.hdu[1].header.card[4].value == 0

    rm(filnam)

    filnam = "kanweg.fits"
    data = [11, 21, 31, 12, 22, 23, 13, 23, 33]
    data = reshape(data, (3, 3, 1))

    f = fits_create(filnam, data; protect=false)

    t = Float32[1.01E-6, 2.0E-6, 3.0E-6, 4.0E-6, 5.0E-6]
    u = [0x0000043e, 0x0000040c, 0x0000041f, 0x0000042e, 0x0000042f]
    v = [1.23, 2.12, 3.0, 4.0, 5.0]
    w = ['a', 'b', 'c', 'd', 'e']
    x = ["a", "bb", "ccc", "dddd", "ABCeeaeeEEEEEEEEEEEE"]
    data1 = (t,u,v,w,x)

    fits_extend!(f, data1; hdutype="TABLE")

    f = fits_read(filnam)

    p = f.hdu[1].header.card[1].keyword == "SIMPLE"
    q = f.hdu[1].dataobject.data == data
    r = f.hdu[1].header.card[1].value == true
    s = f.hdu[1].header.card[4].value == 3
    x = f.hdu[2].dataobject.data[1] == " 1.01e-6 1086 1.23 a                    a"

    rm(filnam)

    o = a & b & c & d & p & q & r & s & x

    o || println([a, b, c, d, p, q, r, s, x])

    return o

end

function test_fits_extend!()

    filnam = "kanweg.fits";
    data = [0x0000043e, 0x0000040c, 0x0000041f];
    f = fits_create(filnam, data; protect=false);

    a = Float32[1.01E-6, 2.0E-6, 3.0E-6, 4.0E-6, 5.0E-6];
    b = [0x0000043e, 0x0000040c, 0x0000041f, 0x0000042e, 0x0000042f];
    c = [1.23, 2.12, 3.0, 4.0, 5.0];
    d = ['a', 'b', 'c', 'd', 'e'];
    e = ["a", "bb", "ccc", "dddd", "ABCeeaeeEEEEEEEEEEEE"];
    data = (a, b, c, d, e);

    fits_extend!(f, data; hdutype="TABLE");

    strExample = " 1.01e-6 1086 1.23 a                    a"
    a = f.hdu[1].header.card[1].keyword == "SIMPLE"
    b = f.hdu[1].dataobject.data[1][1] == 0x0000043e
    c = f.hdu[2].header.card[1].keyword == "XTENSION"
    d = f.hdu[2].dataobject.data[1] == strExample
    e = get(Dict(f.hdu[2].header.map), "NAXIS", 0) == 3

    rm(filnam)

    o = a & b & c & d & e

    o || println([a, b, c, d, e])

    return o

end

function test_fits_save_as()

    filnam1 = "minimal.fits"
    filnam2 = "kanweg.fits"
    f = fits_create(filnam1; protect=false)

    fits_save_as(f, filnam2; protect=false)

    o = Base.Filesystem.isfile(filnam2)

    rm(filnam1)
    rm(filnam2)

    return o

end

function test_fits_copy()

    filnam1="filnam1.fits"
    filnam2="filnam2.fits"

    fits_create(filnam1; protect=false)
    fits_copy(filnam1, filnam2; protect=false, msg=false);
    f = fits_read(filnam2)

    o = f.filnam.value == filnam2
    
    rm(filnam1)
    rm(filnam2)

    return o

end

function test_fits_collect()

    filnam1 = "F1.fits"
    filnam2 = "F2.fits"
    filnam3 = "F3.fits"
    filnam4 = "F1-F3.fits"

    data = [11, 21, 31, 12, 22, 23, 13, 23, 33]
    data = reshape(data, (3, 3, 1))

    fits_create(filnam1, data; protect=false)
    fits_create(filnam2, data; protect=false)
    fits_create(filnam3, data; protect=false)

    f = fits_collect(filnam1, filnam3; protect=false, msg=false)

    o = f.filnam.value == filnam4

    rm(filnam1)
    rm(filnam2)
    rm(filnam3)
    rm(filnam4)

    return o

end

function test_fits_keyword()

    a = fits_keyword("end"; msg=false)[1] == 'K'
    b = fits_keyword("ed"; msg=false)[1] == 'E'
    c = fits_keyword(; msg=false)[1]  == 'F'
    d = fits_keyword(hdutype="'PRIMARY '"; msg=false)[1] == 'F'
    e = fits_keyword("all"; msg=false)[1] == 'F'

    return a & b & c & d & e

end

function test_fits_add_key!()

    filnam = "kanweg.fits";
    f = fits_create(filnam; protect=false);
    
    long = repeat(" long", 71);
    for i=1:5
           fits_add_key!(f, 1, "KEY$i", true, "this is a" * long * " comment");
    end

    i = get(f.hdu[1].header.map, "KEY1", 0)
    k = f.hdu[1].header.card[i].keyword

    test = k == "KEY1"

    rm(filnam)

    return test

end

function test_fits_rename_key!()

    filnam = "minimal.fits"
    f = fits_create(filnam; protect=false)
    fits_add_key!(f, 1, "KEYNEW1", true, "this is card 9")

    i = get(f.hdu[1].header.map, "KEYNEW1", 0)

    test1 = i == 7

    fits_rename_key!(f, 1, "KEYNEW1", "KEYNEW2")

    i = get(f.hdu[1].header.map, "KEYNEW2", 0)

    test2 = i == 7

    # test = .![test1, test2]

    # o = isnothing(findfirst(.![test1, test2])) ? true : false

    rm(filnam)

    return test1 & test2

end

function test_fits_delete_key!()

    filnam = "minimal.fits"
    f = fits_create(filnam; protect=false)
    fits_add_key!(f, 1, "KEYNEW1", true, "FITS dataset may contain extension")

    i = get(f.hdu[1].header.map, "KEYNEW1", 0)

    test1 = i == 7

    fits_delete_key!(f, 1, "KEYNEW1")

    i = get(f.hdu[1].header.map, "KEYNEW1", 0)

    test2 = i == 0

    rm(filnam)

    return test1 & test2

end

function test_fits_edit_key!()

    filnam = "minimal.fits"
    f = fits_create(filnam; protect=false)
    
    fits_add_key!(f, 1, "KEYNEW1", true, "FITS dataset may contain extension")
    fits_edit_key!(f, 1, "KEYNEW1", false, "comment has changed")

    k = get(f.hdu[1].header.map, "KEYNEW1", 0)

    test = strip(f.hdu[1].header.card[k].comment) == "comment has changed"

    rm(filnam)

    return test

end

function test_fits_pointer()
    
    filnam = "kanweg.fits"
    data = [0x0000043e, 0x0000040c, 0x0000041f];
    f = fits_create(filnam, data; protect=false);
    fits_extend!(f, data; hdutype="'IMAGE   '")
    fits_extend!(f, data; hdutype="'IMAGE   '")

    o = IORead(filnam)
    a = _row_nr(o)
    b = _block_row(o)
    c = _hdu_row(o)
    d = _header_row(o)
    e = _data_row(o)
    f = _end_row(o)

    r = fits_record_dump(filnam)
    g = r[9][2][1:3]
    h = r[37][2][1:15]
    i = r[109][2][1:15]
    j = r[181][2][1:15]

    a = (a .+1 == Base.OneTo(216))
    b = (b == [0, 36, 72, 108, 144, 180])
    c = (c == [0, 72, 144])
    d = (d == [0, 72, 144])
    e = (e == [36, 108, 180])
    f = (f == [72, 144, 216])
    g = (g == "END")
    h = (h == "\x80\0\x04>\x80\0\x04\f\x80\0\x04\x1f\0\0\0")
    i = (i == "\x80\0\x04>\x80\0\x04\f\x80\0\x04\x1f\0\0\0")
    j = (j == "\x80\0\x04>\x80\0\x04\f\x80\0\x04\x1f\0\0\0")

    rm(filnam)

    o = a & b & c & d & e & f & g & h & i & j

    o || println([a, b, c, d, e, f, g, h, i, j])

    return o

end

function test_format_hdutype()

    a = "'TEST    '" == _format_hdutype("test")
    b = "'TEST    '" == _format_hdutype("'test'")
    c = "'TEST    '" == _format_hdutype("'test")
    d = "'TEST    '" == _format_hdutype(" 'test")
    e = "'TEST    '" == _format_hdutype("' test")
    f = "'TEST    '" == _format_hdutype("test' ")
    g = "'TEST    '" == _format_hdutype("test '")
    h = "'TEST    '" == _format_hdutype("TEST")

    o = a & b & c & d & e & f & g & h

    o || println([a, b, c, d, e, f, g, h])

    return o

end

function test_FORTRAN_format()

    a1 = cast_FORTRAN_format("I10")
    a2 = FORTRAN_format("Iw", 'I', nothing, 10, 0, 0, 0)

    b1 = cast_FORTRAN_format("I10.12")
    b2 = FORTRAN_format("Iw.m", 'I', nothing, 10, 12, 0, 0)

    c1 = cast_FORTRAN_format("E10.5E3")
    c2 = FORTRAN_format("Ew.dEe", 'E', nothing, 10, 0, 5, 3)

    F = cast_FORTRAN_format("E10.5E3")

    d1 = (F.Type, F.TypeChar, F.EngSci, F.width, F.nmin, F.ndec, F.nexp)
    d2 = ("Ew.dEe", 'E', nothing, 10, 0, 5, 3)

    a = a1 == a2
    b = b1 == b2
    c = c1 == c2
    d = d1 == d2

    o = a & b & c & d

    o || println([a, b, c, d])

    return o
    
end

function test_fits_tform()

    filnam = "kanweg.fits"
    f = fits_create(filnam; protect=false)

    a1 = Bool[1, 0, 1, 0, 1]
    a2 = UInt8[108, 108, 108, 108, 108]
    a3 = Int16[1081, 1082, 1083, 1084, 1085]
    a4 = UInt16[1081, 1082, 1083, 1084, 1085]
    a5 = Int32[1081, 1082, 1083, 1084, 10850]
    a6 = UInt32[1081, 10820, 1083, 1084, 10850]
    a7 = Int64[1081, 1082, 1083, 1084, 108500]
    a8 = UInt64[1081, 1082, 1083, 1084, 108500]
    a9 = [1.23, 2.12, 3.0, 4.0, 5.0]
    a10 = Float32[1.01e-6, 2e-6, 3.0e-6, 4.0e6, 5.0e-6]
    a11 = Float64[1.01e-6, 2.0e-6, 3.0e-6, 4.0e-6, 50.0e-6]
    a12 = ['a', 'b', 'c', 'd', 'e']
    a13 = ["a", "bb", "ccc", "dddd", "ABCeeaeeEEEEEEEEEEEE"]
    data = (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13)

    d = FITS_data("'TABLE   '", data)

    fits_tform(d) == ["L1", "I3", "I4", "I4", "I5", "I5", "I6", "I6", "F1.2", "E1.5", "D1.5", "A1", "A20"]

end

function test_table_data_types()

    filnam = "kanweg.fits";
    f = fits_create(filnam; protect=false);

    a = Float16[1.01E-6, 2.0E-6, 3.0E-6, 4.0E-6, 5.0E-6, 6.0E-6, 7.0E-6]
    b = Float32[1.01E-6, 2.0E-6, 3.0E-6, 4.0E-6, 5.0E-6, 6.0E-6, 7.0E-6]
    c = Float64[1.01E-6, 2.0E-6, 3.0E-6, 4.0E-6, 5.0E-6, 6.0E-6, 7.0E-6]
    d = [1.23, 2.12, 3.0, 4.0, 5.0, 6.0, 7.0]
    a1 = [convert(Int8, Int(2^i) - 1) for i = 1:7];
    a2 = [convert(Int16, Int(2^i) - 1) for i = 8:14];
    a3 = [convert(Int32, Int(2^i) - 1) for i = 15:21];
    a1 = [convert(Int64, Int(2^i) - 1) for i = 22:28];
    b1 = [convert(UInt8, Int(2^i) - 1) for i = 1:7];
    b2 = [convert(UInt16, Int(2^i) - 1) for i = 8:14];
    b3 = [convert(UInt32, Int(2^i) - 1) for i = 15:21];
    b4 = [convert(UInt64, Int(2^i) - 1) for i = 22:28];
    data = [a, b, c, d, a1, a2, a3, a4, b1, b2, b3, b4];

    fits_extend!(f, data; hdutype="TABLE");



end