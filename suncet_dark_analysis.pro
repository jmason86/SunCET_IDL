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
dataloc = getenv('SunCET_dark_data_phase_a')
saveloc = getenv('SunCET_dark_analysis')

file = '-10 C/2 second/FrameData_20201007_233651147.hex'
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

; Display image
i1 = image(im, min_value=3000L, max_value=7000L)
i1.save, saveloc + str_replace(file, '/', '_', /GLOBAL) + '.png'

END