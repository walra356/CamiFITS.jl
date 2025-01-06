# SPDX-License-Identifier: MIT

# Copyright (c) 2024 Jook Walraven <69215586+walra356@users.noreply.github.com> and contributors

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# ------------------------------------------------------------------------------
#                            fits_test.jl
# ------------------------------------------------------------------------------

function test_fits_info(;dbg=false)

dbg && println("test_fits_info - Integers")

    filnam = "kanweg.fits"

    T = [Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64, UInt64,
        Float32, Float64]
    c = []

    for i ∈ eachindex(T)
dbg && println("----------------------------------")
        data = [typemin(T[i]), typemax(T[i])]
dbg && println(data)
        f = fits_create(filnam, data; protect=false)
        a = fits_info(f; hdr=false) == data
dbg && println("fits_info(f) = ", fits_info(f; hdr=false))
dbg && println("i = $i, passed test 1 = $a")
        push!(c, a)
        a = fits_info(filnam; hdr=false) == data  # [1] == '\n'
dbg && println("fits_info(filnam) = ", fits_info(filnam; hdr=false))
dbg && println("i = $i, passed test 2 = $a")
        push!(c, a)
    end
    

dbg && println("----------------------------------")
dbg && println("test_fits_info - Real numbers")

dbg && println("----------------------------------")
    data = [1.23, 4.56]
dbg && println(data)
    f = fits_create(filnam, data; protect=false)
    a = fits_info(f; hdr=false) == data
dbg && println("fits_info(f) = ", fits_info(f; hdr=false))
dbg && println("Real: passed test 1 = $a")
    push!(c, a)
    a = fits_info(filnam; hdr=false) == data  # [1] == '\n'
dbg && println("fits_info(filnam) = ", fits_info(filnam; hdr=false))
dbg && println("Real: passed test 2 = $a")
    push!(c, a)
dbg && println("----------------------------------")

    rm(filnam)

    o = c[1] & c[2] & c[3] & c[4] & c[5] & c[6] & c[7] & c[8] & c[9] & c[10]
    o = o & c[11]

    o || println(c)

    return o

end

function test_fits_read(;msg=true)

    filnam = "kanweg.fits"

    data = [11, 21, 31, 12, 22, 23, 13, 23, 33]
    data = reshape(data, (3, 3, 1))

    fits_create(filnam, data; protect=false)

    f = fits_read(filnam; msg)

    a = fits_info(f; hdr=false) == data
    b = fits_info(filnam; hdr=false) == data  # [1] == '\n'

    rm(filnam)

    o = a & b

    o || println([a, b])

    return o

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

    filnam1 = "filnam1.fits"
    filnam2 = "filnam2.fits"

    fits_create(filnam1; protect=false)
    fits_copy(filnam1, filnam2; protect=false, msg=false)
    f = fits_read(filnam2)

    o = f.filnam.value == filnam2

    rm(filnam1)
    rm(filnam2)

    return o

end

function test_fits_collect()

    data1(i) = [i]
    for i = 1:5
        fits_create("T$i.fits", data1(i); protect=false)
    end
    f = fits_collect("T1.fits", "T5.fits"; protect=false, msg=false)
    dataout = fits_info(f; hdr=false)
    a = dataout[2, 1] == data1(2)[1]

    data2(i) = [0, i, 0]
    for i = 1:5
        fits_create("T$i.fits", data2(i); protect=false)
    end
    f = fits_collect("T1.fits", "T5.fits"; protect=false, msg=false)
    dataout = fits_info(f; hdr=false)
    b = dataout[2, :] == data2(2)

    data3(i) = [0 i 0]
    for i = 1:5
        fits_create("T$i.fits", data3(i); protect=false)
    end
    f = fits_collect("T1.fits", "T5.fits"; protect=false, msg=false)
    dataout = fits_info(f; hdr=false)
    c = dataout[:, :, 2] == data3(2)[:, :, 1]

    data4(i) = [0 0 0; 0 i 0; 0 0 0]
    for i = 1:5
        fits_create("T$i.fits", data4(i); protect=false)
    end
    f = fits_collect("T1.fits", "T5.fits"; protect=false, msg=false)
    dataout = fits_info(f; hdr=false)
    d = dataout[:, :, 2] == data4(2)[:, :, 1]

    data5(i) = [0 0 0; 0 i 0; 0 0 0;;;]
    for i = 1:5
        fits_create("T$i.fits", data5(i); protect=false)
    end
    f = fits_collect("T1.fits", "T5.fits"; protect=false, msg=false)
    dataout = fits_info(f; hdr=false)
    e = dataout[:, :, 2] == data5(2)[:, :, 1]

    for i = 1:5
        rm("T$i.fits")
    end

    rm("T1-T5.fits")

    pass = a & b & c & d & e
    pass || println([a, b, c, d, e])

    return pass

end

function test_fits_keyword()

    a = fits_keyword("end"; msg=false)[1] == 'K'
    b = fits_keyword("ed"; msg=false)[1] == 'E'
    c = fits_keyword(; msg=false)[1] == 'F'
    d = fits_keyword(hdutype="'PRIMARY '"; msg=false)[1] == 'F'
    e = fits_keyword("all"; msg=false)[1] == 'F'

    pass = a & b & c & d & e
    pass || println([a, b, c, d, e])

    return pass

end

function test_fits_add_key!()

    filnam = "kanweg.fits"
    f = fits_create(filnam; protect=false)

    long = repeat(" long", 71)
    for i = 1:5
        fits_add_key!(f, 1, "KEY$i", true, "this is a" * long * " comment")
    end

    date = Dates.Date("2020-09-18", "yyyy-mm-dd")
    fits_add_key!(f, 1, "DATE", date, "this is a" * long * " comment")

    i = get(f.hdu[1].header.map, "KEY1", 0)
    a = f.hdu[1].header.card[i].keyword

    i = get(f.hdu[1].header.map, "DATE", 0)
    b = f.hdu[1].header.card[i].keyword

    a = a == "KEY1"
    b = b == "DATE"

    rm(filnam)

    pass = a & b 
    pass || println([a, b])

    return pass

end

function test_fits_rename_key!()

    filnam = "minimal.fits"
    f = fits_create(filnam; protect=false)
    fits_add_key!(f, 1, "KEYNEW1", true, "this is card 7")

    i = get(f.hdu[1].header.map, "KEYNEW1", 0)

    test1 = i == 6

    fits_rename_key!(f, 1, "KEYNEW1", "KEYNEW2")

    i = get(f.hdu[1].header.map, "KEYNEW2", 0)

    test2 = i == 6

    rm(filnam)

    return test1 & test2

end

function test_fits_delete_key!()

    filnam = "minimal.fits"
    f = fits_create(filnam; protect=false)
    fits_add_key!(f, 1, "KEYNEW1", true, "FITS dataset may contain extension")

    i = get(f.hdu[1].header.map, "KEYNEW1", 0)

    test1 = i == 6

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
    data = [0x0000043e, 0x0000040c, 0x0000041f]
    f = fits_create(filnam, data; protect=false)
    fits_extend!(f, data; hdutype="'IMAGE   '")
    fits_extend!(f, data; hdutype="'IMAGE   '")

    o = IORead(filnam);
    p = cast_FITS_pointer(o)
    a = p.nblock == 6
    b = p.nhdu == 3
    c = p.block_start  == (0, 2880, 5760, 8640, 11520, 14400)
    d = p.block_stop == (2880, 5760, 8640, 11520, 14400, 17280)
    e = p.hdu_start == (0, 5760, 11520)
    f = p.hdu_stop == (2880, 8640, 14400)
    g = p.hdr_start == (0, 5760, 11520)
    h = p.hdr_stop == (2880, 8640, 14400)
    i = p.data_start == (2880, 8640, 14400)
    j = p.data_stop == (5760, 11520, 17280)

    r = fits_record_dump(filnam; msg=false)
    k = r[8][8:10]
    l = r[37][8:83]
    m = r[109][8:83]
    n = r[181][8:83]

    x = "UInt8["
    x *= "0x80, 0x00, 0x04, 0x3e, "
    x *= "0x80, 0x00, 0x04, 0x0c, "
    x *= "0x80, 0x00, 0x04, 0x1f"
    k = (k == "END")
    l = (l == x)
    m = (m == x)
    n = (n == x)
    
    rm(filnam)

    o = a & b & c & d & e & f & g & h & i & j & k & l & m & n

    o || println([a, b, c, d, e, f, g, h, i, j, k, l, m, n])

end

function test_fits_ptr()

    filnam = "kanweg.fits"
    data = [0x0000043e, 0x0000040c, 0x0000041f]
    f = fits_create(filnam, data; protect=false)
    fits_extend!(f, data; hdutype="'IMAGE   '")
    fits_extend!(f, data; hdutype="'IMAGE   '")

    o = IORead(filnam);
    p = cast_FITS_ptr(o);

    a = p.hdu[2].header.start == 5760 
    b = p.hdu[2].header.stop == 8640 
    c = p.hdu[2].data.start == 8640
    d = p.hdu[2].data.stop == 11520
    
    rm(filnam)

    o = a & b & c & d

    o || println([a, b, c, d])
    
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

    d1 = (F.datatype, F.char, F.EngSci, F.width, F.nmin, F.ndec, F.nexp)
    d2 = ("Ew.dEe", 'E', nothing, 10, 0, 5, 3)

    a = a1 == a2
    b = b1 == b2
    c = c1 == c2
    d = d1 == d2

    o = a & b & c & d

    o || println([a, b, c, d])

    return o

end

function test_image_datatype()

    filnam = "kanweg.fits"
    f = fits_create(filnam; protect=false)

    data = [0x0000043e, 0x0000040c, 0x0000041f]

    fits_extend!(f, data; hdutype="image")

    g = fits_read(filnam)

    rm(filnam)

    data1 = g.hdu[2].dataobject.data

    o = data .== data1

    pass = 1 == sum(o) ÷ length(data)

    pass || println(o)

    return pass

end

function dataset_table()

    a1, b1 = Bool(1), Bool(0)
    a2, b2 = UInt8(108), UInt8(109)
    a3, b3 = Int16(1081), Int16(1011)
    a4, b4 = UInt16(1081), UInt16(1011)
    a5, b5 = Int32(1081), Int32(1011)
    a6, b6 = UInt32(1081), UInt32(1011)
    a7, b7 = Int64(1081), Int64(1011)
    a8, b8 = UInt64(1081), UInt64(1011)
    a9, b9 = 1.23, 123.4
    a10, b10 = Float32(1.01e-6), Float32(3.01e-6)
    a11, b11 = Float64(1.01e-6), Float64(30.01e-6)
    a12, b12 = 'a', 'b'
    a13, b13 = "a", "b"
    a14, b14 = "abc", "abcdef"

    data1 = Any[a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14]
    data2 = Any[b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14]

    data = [data1, data2]

    return data

end

function _bintable()
    #   type 1 - Int8 ----------------------
    a1 = Int8(11)
    a2 = Int8[11, 12]
    a3 = Tuple(a2)
    #   type 2 -----------------------
    b1 = UInt8(108)
    b2 = UInt8[108, 109]
    b3 = Tuple(b2)
    #   type 3 - Int16 ----------------------
    c1 = Int16(1001)
    c2 = Int16[1001, 1002, 1003, 1004, 1005, 1006]
    c2 = reshape(c2, 2, 3)
    c3 = Tuple(c2)
    #   type 4 -----------------------
    d1 = UInt16(1081)
    d2 = UInt16[1081, 1002]
    d3 = Tuple(d2)
    #   type 5 - Int32 ----------------------
    e1 = Int32(1081)
    e2 = Int32[1081, 1002]
    e3 = Tuple(e2)
    #   type 6 -----------------------
    f1 = UInt32(1081)
    f2 = UInt32[1081, 1002]
    f3 = Tuple(f2)
    #   type 7 - Int64 ----------------------
    g1 = Int64(1081)
    g2 = Int64[1081, 1002]
    g3 = Tuple(g2)
    #   type 8 -----------------------
    h1 = UInt64(1081)
    h2 = UInt64[1081, 1002]
    h3 = Tuple(h2)
    #   type 9 -----------------------
    i1 = 1.23
    i2 = [1.23, 123.14]
    i3 = Tuple(i2)
    #   type 10 -----------------------
    j1 = Float32(1.01e-6)
    j2 = Float32[1.01e-6, 2, 01e-7]
    j3 = Tuple(j2)
    #   type 11 -----------------------
    k1 = Float64(1.01e-6)
    k2 = Float64[1.01e-6, 2.02e-7]
    k3 = Tuple(k2)
    #   type 12 -----------------------
    l1 = ComplexF32(3.0, 3.0)
    l2 = [ComplexF32(3.0, 3.0), ComplexF32(2.0, 2.0)]
    l3 = Tuple(l2)
    #   type 13 -----------------------
    m1 = ComplexF64(3.0, 3.0)
    m2 = [ComplexF64(3.0, 3.0), ComplexF64(2.0, 2.0)]
    m3 = Tuple(m2)
    #   type 14 -----------------------
    n1 = Bool(1)
    n2 = Bool[1, 0]
    n3 = Tuple(n2)
    #   type 15 -----------------------
    o1 = 'a'
    o2 = ['a', 'b']
    o3 = Tuple(o2)
    o4 = empty([], Char)
    #   type 16-----------------------
    p1 = "aaa"
    p2 = "abc def" # String Array not allowed - use String
    p3 = p2 # Tuple{String} not allowed - use String
    #   type 17 -----------------------
    q1 = BitVector([1, 0, 1, 0, 1, 0])
    q2 = [BitVector([1, 0, 1, 0, 1, 0]), BitVector([1, 0, 1, 0, 1, 0])]
    q3 = Tuple(q2)

    data = Any[
        Any[a1, a2, a3],
        Any[b1, b2, b3],
        Any[c1, c2, c3],
        Any[d1, d2, d3],
        Any[e1, e2, e3],
        Any[f1, f2, f3],
        Any[g1, g2, g3],
        Any[h1, h2, h3],
        Any[i1, i2, i3],
        Any[j1, j2, j3],
        Any[k1, k2, k3],
        Any[l1, l2, l3],
        Any[m1, m2, m3],
        Any[n1, n2, n3],
        Any[o1, o2, o3],
        Any[p1, p2, p3],
        Any[q1, q2, q3]]

    return data

end

function dataset_bintable(; j=0)

    data = _bintable()

    o = Any[]

    for i ∈ eachindex(data)
        if j > 0
            push!(o, data[i][j])
        else
            append!(o, data[i])
        end
    end

    return Any[o]

end

function test_table_datatype()

    filnam = "kanweg.fits"
    f = fits_create(filnam; protect=false)

    data = dataset_table()

    fits_extend!(f, data; hdutype="table")

    data = f.hdu[2].dataobject.data

    g = fits_read(filnam)

    rm(filnam)

    data1 = g.hdu[2].dataobject.data

    o = data .== data1

    pass =  (sum(o) ÷ length(data)) == 1

    pass || println(o)

    return pass

end

function test_bintable_datatype()

    filnam = "kanweg.fits"
    f = fits_create(filnam; protect=false)

    data = dataset_bintable()

    fits_extend!(f, data; hdutype="bintable")

    g = fits_read(filnam)

    rm(filnam)

    data1 = g.hdu[2].dataobject.data

    o = data .== data1

    pass = 1 == sum(o) ÷ length(data)

    pass || println(o)

    return pass

end

function test_FORTRAN_eltype_char()

    T = (Char, Bool, Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64, UInt64,
        Float16, Float32, Float64, ComplexF16, ComplexF32, ComplexF64, FITS)

    o = [FORTRAN_eltype_char(T[i]; msg=false) for i ∈ eachindex(T)]
    x = join(o) == "AL-BIIJJKK-ED-CM-"

    return x

end

function test_fits_zero_offset()

    a = fits_zero_offset(Any) == 0.0
    b = fits_zero_offset(Bool) == 0.0
    c = fits_zero_offset(Int8) == -128
    d = fits_zero_offset(UInt8) == 0.0
    e = fits_zero_offset(Int16) == 0.0
    f = fits_zero_offset(UInt16) == 32768
    g = fits_zero_offset(Int32) == 0.0
    h = fits_zero_offset(UInt32) == 2147483648
    i = fits_zero_offset(Int64) == 0.0
    j = fits_zero_offset(UInt64) == 9223372036854775808
    k = fits_zero_offset(Float16) == 0.0
    l = fits_zero_offset(Float32) == 0.0
    m = fits_zero_offset(Float64) == 0.0

    o = a & b & c & d & e & f & g & h & i & j & k & l & m

    o || println([a, b, c, d, e, f, g, h, i, j, k, l, m])

    return o

end

function test_format_value_string() # available but not yet used

    a = _format_value_string("this is it") == ["'this is it'        "]
    b = _format_value_string("this is a longer version of this text") == ["'this is a longer version of this text'"]
    str = "this is a longer version of this text which does not fot on an 80 character line"
    c = _format_value_string(str) == ["'this is a longer version of this text which does not fot on an 80 c&'", "'haracter line"]
    d = _format_value_string(str, false) == ["'this is a longer version of this text which does not fot on an 80 c&'", "'haracter line&'"]
    e = _format_value_string("this is it", false) == ["'this is it'        "]
    f = _format_value_string("this is a longer version of this text", false) == ["'this is a longer version of this text&'"]

    o = a & b & c & d & e & f

    o || println([a, b, c, d, e, f])

    return o

end