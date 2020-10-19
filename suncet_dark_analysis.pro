;+
; NAME:
;   SunCET_dark_analysis
;
; PURPOSE:
;   Analyze dark images taken wth the detector from the lab
;
; INPUTS:
;   path_file [string]: Hardcoded at the moment. The path and filename of the data to load
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plots and numbers to console
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   Just run it!
;-
PRO SunCET_dark_analysis
kill
; Defaults
dataloc = getenv('SunCET_base') + 'Dark_Data/'
saveloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/Darks/'

file = '-10 C/10 second/FrameData_20201007_235500184.hex'
path_filename = dataloc + file

; Short exposures could only read out smaller frames, so figure out the right nrows, ncols
IF file.contains('0.025 second') THEN BEGIN
  nrows = 1504L
  ncols = 8L
ENDIF ELSE IF file.contains('1 second') OR file.contains('2 second') THEN BEGIN
  nrows = 1000L
  ncols = 512L
ENDIF ELSE BEGIN
  nrows = 1500L
  ncols = 1500L
ENDELSE

; Load data
im = SunCET_read_detector_hex(path_filename, nrows=nrows, ncols=ncols)

; Remove bias
im_no_bias = im - 4400L

; Display image
i1 = image(im, min_value=3000L, max_value=7000L)
i1.save, saveloc + str_replace(file, '/', '_', /GLOBAL) + '.png'

STOP
END