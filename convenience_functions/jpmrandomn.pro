;+
; NAME:
;   JPMrandomn
;
; PURPOSE:
;   Make a random distribution with specified mean and standard deviation
;
; INPUTS:
;   seed [number]: Set this to any value or none -- it's just a passthrough to the randomu function
;
; OPTIONAL INPUTS:
;   d_i [intarr]: An array specifying the dimensions of the result -- passthrough to randomu function
;   mean [float]: The mean of the normal distribution. Default is 0.
;   stddev [float]: The standard deviation of the normal distribution. Default is 1.
;   
; KEYWORD PARAMETERS:
;   DOUBLE: Set this to use double precision. 
;
; OUTPUTS:
;   random_numbers [fltarr or dblarr]: The random number(s) in the specified dimensions. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   gauss = jpmrandomn(seed, mean=34.9, stddev=4.2)
;
;-
FUNCTION JPMrandomn, seed, $
                     d_i=d_i, mean=mean, stddev=stddev, $
                     DOUBLE=DOUBLE

; Defaults
IF d_i EQ !NULL THEN BEGIN
  d_i = 1
ENDIF
IF mean EQ !NULL THEN BEGIN
  mean = 0
ENDIF
IF stddev EQ !NULL THEN BEGIN
  stddev = 1
ENDIF

return, randomu(seed, d_i, DOUBLE=DOUBLE, /NORMAL) * stddev + mean

END