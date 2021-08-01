### splash.pl

First steps in SDL_perl. Not that easy, so there may be room for improvement. It's quite slow for example. Press 'q' to end. 

Drawing routine of a ZX Spectrum demo found [https://www.youtube.com/watch?v=-Aw_YiZVu38](here). BASIC code is:

    10 DIM m(255)
    15 LET a = COS(PI / 4)
    20 FOR y = 1 TO 141 STEP 5
    25 LET e = a * y
    27 LET c = y - 70
    29 LET c = c * c
    30 FOR x = 1 TO 141
    34 LET d = x - 70
    40 LET z = 80 * EXP(-0.001 * (c + d * d))
    50 LET x1 = x + e
    60 LET y1 = z + e
    70 IF y1 >= m(x1) THEN LET m(x1) = y1: PLOT x1, y1
    80 NEXT x
    90 NEXT y

License of my Perl code: GNU GPL 3 (or above).
