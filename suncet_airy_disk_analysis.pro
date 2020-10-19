;+
; NAME:
;   SunCET_airy_disk_analysis
;
; PURPOSE:
;   Analyze Airy disk data aqcuired in the lab
;
; INPUTS:
;   None, but requires access to the data
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
dataloc = getenv('SunCET_base') + '2020-10-13 Airy SHDR/Final Setup/'
saveloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/Airy Disks/'
dims = [700, 700] ; [1500, 1500]
slice_row = 450
slice_color = '#0075D0'


; Load short exposure data
im_short = SunCET_read_detector_hex(dataloc + 'With ND Filter/3.2s 1500x1500/FrameData_20201013_235353919.hex')
im_short_dark1 = SunCET_read_detector_hex(dataloc + 'With ND Filter/3.2s 1500x1500/Dark/FrameData_20201013_235153989.hex')
im_short_dark2 = SunCET_read_detector_hex(dataloc + 'With ND Filter/3.2s 1500x1500/Dark/FrameData_20201013_235205981.hex')

corr_short = im_short - im_short_dark1

; Create an average dark
dark_stack = [[[im_short_dark1]], [[im_short_dark2]]]
mean_dark = mean(dark_stack, dimension=3)

;i1 = image(im_short^0.8, dimensions=dims, margin=0)
;i1.save, saveloc + 'Airy 3.2s.png'

; Load really long exposure data
im_long2 = SunCET_read_detector_hex(dataloc + 'Without ND Filter/50s/FrameData_20201014_003202549.hex')
im_50_dark1 = SunCET_read_detector_hex(dataloc + 'Without ND Filter/50s/Dark/FrameData_20201014_002932546.hex')
im_50_dark2 = SunCET_read_detector_hex(dataloc + 'Without ND Filter/50s/Dark/FrameData_20201014_003022560.hex')

corr_long2 = im_long2 - im_50_dark2

;i5 = image(im_long2^0.8, min_value=0, max_value=5e3)
;i6 = image(corr_long2^0.8, max_value=5e3, dimensions=dims, margin=0)

;i6.save, saveloc + 'Airy 50s.png'


; Rotate image to get a good slice
imrot = rot(corr_long2, -50) 
irot = image(imrot^0.8, max_value=5e3, dimensions=dims, margin=0)
line_slice = polyline([0, 2000], [slice_row, slice_row], /DATA, target=i6, color=slice_color, thick=3)

slice = imrot[*, slice_row]

p1 = plot(slice, color=slice_color, THICK=2, FONT_SIZE=16, $
          TITLE='Airy Slice', $
          YTITLE='intensity [native units]', $
          XTITLE='column index')
;p1.save, saveloc + 'Airy Slice.png'

STOP

right_slice_normalized = slice[1250:-1] / float(max(slice)) * 100.

p2 = plot(jpmrange(1250, 1999), right_slice_normalized, 'tomato', THICK=2, FONT_SIZE=16, $
          TITLE='Airy Slice (right side only)', $
          YTITLE='normalized intensity [%]', $
          XTITLE='column index')
;p2.save, saveloc + 'Airy Slice Normalized (right side only).png'
STOP

END