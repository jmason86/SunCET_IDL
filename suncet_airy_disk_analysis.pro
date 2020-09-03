;+
; NAME:
;   SunCET_airy_disk_analysis
;
; PURPOSE:
;   Analyze Airy disk data aqcuired in the lab
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
PRO SunCET_airy_disk_analysis
kill
; Defaults
dataloc = '//Users/jmason86/Google Drive/Proposals/SunCET CubeSat/Detector/Phase A Lab Testing/Captured Data/'
saveloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/Airy Disks/'
slice_row = 774

; Load data
im = rotate(csol_hex2img(dataloc + 'FrameData_20200901_212533376_GOOD1.hex', 6), 5.5)
;im = rot(im, 280.)

i1 = image(im^1.8)
line_slice = polyline([0, 2000], [slice_row, slice_row], /DATA, TARGET=i1, COLOR='tomato', THICK=3)
i1.save, saveloc + 'Airy Image.png'

slice = im[*, slice_row]

p1 = plot(slice, 'tomato', THICK=2, FONT_SIZE=16, $
          TITLE='Airy Slice', $
          YTITLE='intensity [native units]', $
          XTITLE='column index')
p1.save, saveloc + 'Airy Slice.png'

right_slice_normalized = slice[1250:-1] / float(max(slice)) * 100.

p2 = plot(jpmrange(1250, 1999), right_slice_normalized, 'tomato', THICK=2, FONT_SIZE=16, $
          TITLE='Airy Slice (right side only)', $
          YTITLE='normalized intensity [%]', $
          XTITLE='column index')
p2.save, saveloc + 'Airy Slice Normalized (right side only).png'
STOP

END