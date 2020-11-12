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
;dataloc = getenv('SunCET_base') + '2020-10-13 Airy SHDR/Final Setup/'
dataloc = '/Users/jmason86/Google Drive/Proposals/SunCET CubeSat/Detector/Phase A Lab Testing/Captured Data/2020-11-10 Airy SHDR/'
saveloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/Airy Disks/'
dims = [700, 700] ; [1500, 1500]
slice_row = 700
slice_color = '#0075D0'

;bla = SunCET_read_detector_hex(dataloc  + 'Without ND Filter/60s/FrameData_20201110_200813707.hex')
;dark = SunCET_read_detector_hex(dataloc + 'Without ND Filter/60s/Dark/FrameData_20201110_201713711.hex')
;im = bla - dark
;i1 = image(im^0.8, max_value=5e3, dimensions=dims, margin=0)
;STOP




; Load short exposure data
files_short = file_search(dataloc + 'With ND Filter/3.2s 1500x1500/*.hex', count=num_files)
im_short_stack = lonarr(1500, 1500, num_files)
FOR i = 0, num_files - 1 DO BEGIN
  im_short_stack[*, *, i] = suncet_read_detector_hex(files_short[i])
ENDFOR
im_short = median(im_short_stack, dimension=3)

files_short_dark = file_search(dataloc + 'With ND Filter/3.2s 1500x1500/Dark/*.hex', count=num_files)
im_short_dark_stack = lonarr(1500, 1500, num_files)
FOR i = 0, num_files - 1 DO BEGIN
  im_short_dark_stack[*, *, i] = suncet_read_detector_hex(files_short_dark[i])
ENDFOR
im_short_dark = median(im_short_dark_stack, dimension=3)

; Dark subtract short exposure
corr_short = im_short - im_short_dark

;i1 = image(corr_short - 1e3, dimensions=dims, margin=0, window_title = 'short')
ishort = image(corr_short, dimensions=dims, min_value=0, max_value=(65535L - mean(im_short_dark)), margin=0, window_title = 'short')
ishort.save, saveloc + 'Airy 3.2s.png'

; Load long exposure data
files_long = file_search(dataloc + 'Without ND Filter/50s/*.hex', count=num_files)
im_long_stack = lonarr(1500, 1500, num_files)
FOR i = 0, num_files - 1 DO BEGIN
  im_long_stack[*, *, i] = suncet_read_detector_hex(files_long[i])
ENDFOR
im_long = median(im_long_stack, dimension=3)

files_long_dark = file_search(dataloc + 'Without ND Filter/50s/Dark/*.hex', count=num_files)
im_long_darks = lonarr(1500, 1500, num_files)
FOR i = 0, num_files - 1 DO BEGIN
  im_long_darks[*, *, i] = SunCET_read_detector_hex(files_long_dark[i])
ENDFOR
im_long_dark = median(im_long_darks, dimension=3)

corr_long = im_long - im_long_dark

ilong = image(alog10(corr_long), min_value=4.02, dimensions=dims, margin=0, window_title='long') ;max_value=5e3)
ilong.save, saveloc + 'Airy 50s.png'

; Optionally rotate image to get a good slice
;imrot = rot(corr_long2, 0)
;irot = image(alog10((imrot - 11e3) > 0.001), min_value=0, dimensions=dims, margin=0, window_title='long') ;max_value=5e3)
;line_slice = polyline([0, 2000], [slice_row, slice_row], /DATA, target=i6, color=slice_color, thick=3)
;slice = imrot[*, slice_row]

;p1 = plot(slice - 11e3, color=slice_color, THICK=2, FONT_SIZE=16, $
;          TITLE='Airy Slice', $
;          YTITLE='intensity [native units]', /YLOG, $
;          XTITLE='column index')
;p1.save, saveloc + 'Airy Slice.png'


peaks_short = [51e3 * 1.06, 3000.] * 10. ; * 1.06 for nonlinearity, * 10. for exposure time normalization
peaks_long = 10.^[4.15, 3.75, 3.2, 3.0] ; Manual grabbing of ring peaks -- ignoring disk and first ring

peaks = [peaks_short, peaks_long] / 50. ; /50. to get to DN/s
peak_x = ([750, 575, 475, 375, 285, 210] - 750) / 2. ; -750 to center it and /2. to get into 700x700
peak_y = ([750, 720, 625, 600, 460, 350] - 750) / 2.
distance = sqrt(peak_x^2. + peak_y^2.)

p2 = plot(distance, peaks, thick=3, font_size=16, dimensions=[800,400], $
          xtitle='distance from center [pixels]', $
          ytitle='intensity of Airy disk/rings [DN/s]', /YLOG)
;p2.save, saveloc + 'Airy intensity.png'
STOP

right_slice_normalized = slice[1250:-1] / float(max(slice)) * 100.

p2 = plot(jpmrange(1250, 1999), right_slice_normalized, 'tomato', THICK=2, FONT_SIZE=16, $
          TITLE='Airy Slice (right side only)', $
          YTITLE='normalized intensity [%]', $
          XTITLE='column index')
;p2.save, saveloc + 'Airy Slice Normalized (right side only).png'
STOP

END