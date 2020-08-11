;+
; NAME:
;   SuncetImageAlgorithmWithSuvi
;
; PURPOSE:
;   Load some GOES/SUVI data and combine it in the way SunCET will to show what the processed data would look like 
;   and quantify impacts of different algorithm options
;
; INPUTS:
;   None (but requires the SUVI data be downloaded)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Images on disk and screen
;   Console messages with quantified results
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires the SUVI, AIA, and MHD synthetic data be available on disk
;
; EXAMPLE:
;   Just run it!
;-
PRO SuncetImageAlgorithmWithApproximateData

kill
; Defaults
dataloc_suvi = '/Users/jmason86/Dropbox/Research/Data/GOES/SUVI/Processed/'
dataloc_aia = '/Users/jmason86/Dropbox/Research/Data/AIA/For SunCET Phase A/'
dataloc_mhd = '/Users/jmason86/Dropbox/Research/Data/MHD/For SunCET Phase A/aia_sim/'
saveloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/SHDR Algorithm/'
SunCET_image_size = [1500, 1500]

; Configuration
DO_SUVI = 0
DO_AIA = 0
DO_MHD = 1
HIGHLIGHT_SUB_IMAGES = 1
IF keyword_set(HIGHLIGHT_SUB_IMAGES) THEN BEGIN
  sub1 = 'RED TEMPERATURE'
  sub2 = 'CB-Oranges'
  sub3 = 'BLUE/WHITE'
ENDIF ELSE BEGIN
  sub1 = 'B-W LINEAR'
  sub2 = sub1
  sub3 = sub1
ENDELSE

; Load data
IF keyword_set(DO_AIA) THEN BEGIN
  files = file_search(dataloc_aia + '*171A_*.fits')
  mreadfits, files, info, data, /SILENT ; Need to skip every other one because the exposures toggle long/short (1 second, 0.005 second)
  num_images_to_stack = 10
ENDIF

IF keyword_set(DO_MHD) THEN BEGIN
  files = file_search(dataloc_mhd + '*04*.sav')
  data = fltarr(1024, 1024, n_elements(files))
  FOR i = 0, n_elements(files) - 1 DO BEGIN
    restore, files[i]
    data[*, *, i] = aia171_image.data + aia193_image.data ; Rough way of getting closer to SunCET's broader bandpass [DN/s]
  ENDFOR
  
  num_images_to_stack = 4
ENDIF


; CB-Oranges
;i1 = image(data[*, *, 0]^0.2, rgb_table='RED TEMPERATURE')
;i2 = image(data[*, *, 1] - data[*, *, 0])

;
; Composite image result corresponding to SunCET SHDR algorithm
;

im_disk_arr = fltarr(SunCET_image_size[0], SunCET_image_size[1], n_elements(files))
im_disk_arr[*, *, *] = !VALUES.F_NAN
im_mid_arr = im_disk_arr
im_outer_arr = im_disk_arr
FOR image_index = 0, n_elements(files) - 1 DO BEGIN

  ; Select one image and downscale it to the SunCET size (1500 x 1500)
  im = float(congrid(data[*, *, image_index], SunCET_image_size[0], SunCET_image_size[1]))
  
  IF keyword_set(DO_AIA) THEN BEGIN
    bound0 = 0    ; start pixel
    bound1 = 159  ; pixels in to solar limb
    bound2 = 1339 ; pixels in to opposite solar limb
    bound3 = 1499 ; final pixel
  ENDIF ELSE IF keyword_set(DO_MHD) THEN BEGIN
    bound0 = 0    ; start pixel
    bound1 = 550  ; pixels in to solar limb
    bound2 = 950  ; pixels in to opposite solar limb
    bound3 = 1499 ; final pixel
  ENDIF
  
  ; Disk pixels (circle)
  ; TODO: Make this a general function in my library
  xcen = SunCET_image_size[0] / 2
  ycen = SunCET_image_size[1] / 2
  radius = (bound2 - bound1) / 2.
  x = indgen(SunCET_image_size[0])
  y = indgen(SunCET_image_size[1])
  xgrid = x # replicate(1, n_elements(y))
  ygrid = replicate(1, n_elements(x)) # y
  mask1d = where(((xgrid-xcen)^2. + (ygrid-ycen)^2.) LE radius^2.)
  mask2d = array_indices(im, mask1d)
  im_disk = fltarr(SunCET_image_size)
  FOR i = 0, n_elements(mask2d[0, *]) - 1 DO BEGIN
    im_disk[mask2d[0, i], mask2d[1, i]] = im[mask2d[0, i], mask2d[1, i]]
  ENDFOR
  
  ; Re-NaN since somehow ended up turning the NaNs to 0s
  im_disk[where(im_disk EQ 0)] = !VALUES.F_NAN
  
  ; Store the sub-images
  im_disk_arr[*, *, image_index] = im_disk
  im_outer_arr[bound0:bound1, *, image_index] = im[bound0:bound1, *]
  im_mid_arr[bound1 + 1:bound2, *, image_index] = im[bound1 + 1:bound2, *]
  im_outer_arr[bound2 + 1:bound3, *, image_index] = im[bound2 + 1:bound3, *]

ENDFOR ; image_index

; Take medians for each sub-image accordingly 
im_disk_median = im_disk_arr[*, *, 0] ; algorithm says median 3-40 0.025 second images but AIA cadence is only 12 seconds so for now just grabbing one image
im_mid_median = median(im_mid_arr[*, *, 0:num_images_to_stack -2], DIMENSION=3) ; 9 images in the stack to median
im_outer_median = median(im_outer_arr[*, *, 0:num_images_to_stack -1], DIMENSION=3) ; 10 images in the stack to median

; Show the composite
i1 = image(im_outer_median^0.2, max_value=max(im)^0.2, min_value=min(im^0.2), rgb_table=sub1, dimensions=SunCET_IMAGE_SIZE, margin=0)
i2 = image(im_mid_median^0.2, max_value=max(im)^0.2, min_value=min(im^0.2), rgb_table=sub2, /OVERPLOT)
i3 = image(im_disk_median^0.2, max_value=max(im)^0.2, min_value=min(im^0.2), rgb_table=sub3, /OVERPLOT)

; Optionally overlay the boundaries to emphasize them
IF keyword_set(HIGHLIGHT_SUB_IMAGES) THEN BEGIN
  p2 = polygon([bound1, bound2, bound2, bound1], [0, 0, bound3, bound3], '2', color='tomato', FILL_BACKGROUND=0, /DATA)
  p3 = ellipse(xcen, ycen, /DATA, major=radius, FILL_BACKGROUND=0, 'tomato', thick=2)
ENDIF
STOP


BULK:
;
; Bulk comparison -- whole image medians with 9 vs 10 images in stack
;


; Take the median of 10 images
med_10 = median(data[*, *, 0:9], DIMENSION=3)

; Take the median of 9 images
med_9 = median(data[*, *, 0:8], DIMENSION=3)

; Compare the medians
med_diff = med_10 - med_9
i1 = image(med_10^0.2, title='Median of 10 images')
i2 = image(med_9^0.2, title='Median of 9 images')
i3 = image(med_diff, title='Diff of medians')

print, 'µ_10 = ' + strtrim(mean(med_10), 2) + ' | σ_10 = ' + strtrim(stddev(med_10), 2)
print, 'µ_9 = ' + strtrim(mean(med_9), 2) + ' | σ_9 = ' + strtrim(stddev(med_9), 2)
print, 'µ_diff = ' + strtrim(mean(med_diff), 2) + ' | σ_diff = ' + strtrim(stddev(med_diff), 2)
print, 'µ_diff = ' + strtrim(mean(med_diff) / mean(med_10) * 10, 2) + '% | σ_diff = ' + strtrim(stddev(med_diff) / stddev(med_10) * 10, 2) + '%'

movieObject = IDLffVideoWrite(saveloc + 'SUVI Median Comparison.mp4')
xsize = 1000
ysize = 1000
fps = 1
bitrate = 1e7
vidStream = movieObject.AddVideoStream(xsize, ysize, fps, BIT_RATE = bitrate)

w = window(DIMENSIONS = [xsize, ysize], /DEVICE, /BUFFER)
i1 = image(med_10^0.2, title='Median of 10 images', /CURRENT)
timeInMovie = movieObject.Put(vidStream, w.CopyWindow()) ; time returned in seconds
w.erase
i2 = image(med_9^0.2, title='Median of 9 images', /CURRENT)
timeInMovie = movieObject.Put(vidStream, w.CopyWindow()) ; time returned in seconds
movieObject.Cleanup
STOP

END



