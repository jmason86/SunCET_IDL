;+
; NAME:
;   SuncetDetectorBloomingFromCsol
;
; PURPOSE:
;   Determine the magnitude (intensity) and extent (distance) of blooming around saturated pixels
;   in the Teledyne e2v CIS115 detector based on the images it took as part of the CSOL instrument
;   during the NASA EVE sounding rocket flight 33.336 in 2018
;
; INPUTS:
;   None (but require access to the raw data)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plots, images, quatifications on console
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires the CSOL processing code
;   Requires the CSOL data
;
; EXAMPLE:
;   Just run it!
;-
PRO SuncetDetectorBloomingFromCsol
kill
; Defaults
dataloc = '/Users/jmason86/Dropbox/minxss_dropbox/rocket_eve_docs/36.336/TM_Data/Flight/CSOL_SDcard/'
saveloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/Blooming/'
slice_column = 75
top_non_bloom_row = 696
blooming_extent_check_row = 780

; Constants
arcsec_per_pixel = 4.8
arcsec_per_deg = 3600.
Rs_deg = 0.265

files = file_search(dataloc + '*.hex')

im = csol_hex2img(dataloc + 'FrameData_SDAddr_0211.hex', 1)
i1 = image(im, MARGIN=0, FONT_COLOR='white', DIMENSIONS=[2000, 1504])
t1 = text(0.5, 0.9, 'Frame 02' + strmid(files[-1], 108, 2), color='white', alignment=0.5, font_size=18)
line_slice = polyline([slice_column, slice_column], [0, 1504], /DATA, TARGET=i1, COLOR='tomato', THICK=3)
l2 = polyline([0, 2000], [top_non_bloom_row, top_non_bloom_row], /DATA, TARGET=i1, COLOR='dodger blue', THICK=2)
l3 = polyline([0, 2000], [blooming_extent_check_row, blooming_extent_check_row], /DATA, TARGET=i1, COLOR='dodger blue', THICK=2)

slice = float(im[slice_column, top_non_bloom_row - 10:blooming_extent_check_row])
background = min(float(im[slice_column, *]))
slice_no_background = slice - background

p1 = plot(slice, 'tomato', THICK=2, $
          TITLE='Raw slice', $
          YTITLE='intensity [native units]', $
          XTITLE='row index')
p2 = plot(slice / max(slice) * 100, 'tomato', THICK=2, $
          TITLE='Normalzied Slice', $
          YTITLE='intensity normalized to peak [%]', $
          XTITLE='row index')
p3 = plot(slice_no_background / max(slice_no_background) * 100, 'tomato', THICK=2, $
          TITLE='Normalized, Background-Subtracted (min in column) Slice', $
          YTITLE='intensity normalized to peak with background subtracted [%]', $
          XTITLE='row index')

; Find knee in the slice
slice = float(im[slice_column, top_non_bloom_row:blooming_extent_check_row]) ; No 10 pixel addition
slice -= background
slice /= max(slice)
slice *= 100.
slice = smooth(slice, 5)
slope = deriv(findgen(n_elements(slice)), slice)
tolerance = 0.5
flat_indices = where(slope GT -tolerance AND slope LT tolerance)
knee_index = flat_indices[0]

; Convert that amount of blooming into how far it would extend for SunCET
blooming_range_arcsec = knee_index * arcsec_per_pixel ; [arcsec/pixel]
blooming_range_deg = blooming_range_arcsec / arcsec_per_deg
blooming_range_Rs = blooming_range_deg / Rs_deg

print, 'Blooming range = ' + jpmprintnumber(blooming_range_arcsec) + '"'
print, 'Blooming range = ' + jpmprintnumber(blooming_range_deg, NUMBER_OF_DECIMALS=3) + 'º'
print, 'Blooming range = ' + jpmprintnumber(blooming_range_Rs) + ' Rs'

p4 = plot(slice_no_background[6:40] / max(slice_no_background) * 100, thick=3, font_size=16, $
          title='CIS115 Detector Blooming', $
          ytitle='normalized intensity [%]', $
          xtitle='distance from saturated pixel [pixels]')        
p4.save, saveloc + 'cis115_blooming.png'


STOP
; Look at all the slices 
knee_extents = intarr(1999)

FOR slice_column = 0, n_elements(knee_extents) - 1 DO BEGIN
  ; Find the knee in the slice
  slice = float(im[slice_column, top_non_bloom_row:blooming_extent_check_row]) ; No 10 pixel addition
  slice -= background
  slice /= max(slice)
  slice *= 100.
  slice = smooth(slice, 5)
  slope = deriv(findgen(n_elements(slice)), slice)
  tolerance = 0.5
  flat_indices = where(slope GT -tolerance AND slope LT tolerance)
  knee_index = flat_indices[0]
  knee_value = slice[knee_index]
  
  knee_extents[slice_column] = knee_index
ENDFOR

p = plot(knee_extents, THICK=2, $
         TITLE='Extent of Blooming (Multi-Slice)', $
         YTITLE='blooming extent [row pixels]', $
         XTITLE='slice [column index]')
STOP








END













PRO make_csol_movie 
movieObject = IDLffVideoWrite(saveloc + 'CSOL Flight.mp4')
xsize = 2000
ysize = 1504
fps = 3
bitrate = 1e7
vidStream = movieObject.AddVideoStream(xsize, ysize, fps, BIT_RATE = bitrate)

w = window(DIMENSIONS = [xsize, ysize], /DEVICE, /BUFFER)

FOREACH file, files DO BEGIN
  csol_image = csol_hex2img(file, 1)
  
  i1 = image(im, MARGIN=0, /CURRENT)
  t1 = text(0.5, 0.9, 'Frame 02' + strmid(file, 108, 2), color='white', alignment=0.5, font_size=18)
  timeInMovie = movieObject.Put(vidStream, w.CopyWindow()) ; time returned in seconds
  w.erase

ENDFOREACH
movieObject.Cleanup

END