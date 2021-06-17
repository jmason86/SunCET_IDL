;+
; NAME:
;   SunCET_overlay_snr
;
; PURPOSE:
;   Overlay SNR contours on radial filtered composite images
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   binning [integer]: The number of pixels binned over (in each direction). Default is 2.
;   snr_binning [integer]: The number of pixels binned over (in each direction) just for SNR calculation. Default is 2.
;   mirror_coating [string]: Which mirror coating to use. Can be either 'b4c', 'alzr', or 'simo'. Default is 'b4c'.
;   exposure_time_sec [float]: Which long exposure time to use. Default is 15.
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Images to screen and disk.
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to the contours and the processed composite images.
;
; EXAMPLE:
;   Just run it!
;-
PRO SunCET_overlay_snr, binning=binning, snr_binning=snr_binning, mirror_coating=mirror_coating, exposure_time_sec=exposure_time_sec
kill

; Defaults
IF binning EQ !NULL THEN BEGIN
  binning = 2
ENDIF
IF snr_binning EQ !NULL THEN BEGIN
  snr_binning = 2 ; [pixels] The number of pixels used for binning for the SNR calculation
ENDIF
IF mirror_coating EQ !NULL THEN BEGIN
  mirror_coating = 'b4c'
ENDIF
IF exposure_time_sec EQ !NULL THEN BEGIN
  exposure_time_sec = 15.
ENDIF

; Paths
dataloc = getenv('SunCET_base') + 'SNR/2011-02-15/'
dataloc_maps = getenv('SunCET_base') + 'MHD/Rendered_EUV_Maps_2011-02-15/fast_cme/'
saveloc = dataloc

; ~Constants / config
plate_scale = 4.8 ; [arcsec/pixel]
rsun_binned_pixels = 960./plate_scale / binning
rs_ellipse = 3.5
SunCET_image_size = [1500, 1500]
dim_x = SunCET_image_size[0]/binning
dim_y = SunCET_image_size[1]/binning

; Load the contours and get the filtered image filename
filename_config = JPMPrintNumber(exposure_time_sec) + 'sec_rebin_' + JPMPrintNumber(snr_binning, /NO_DECIMALS) + '_' + mirror_coating
IF file_test(dataloc + 'snr_' + filename_config + '.sav') NE 1 THEN BEGIN
  snr_plotter, snr_neighborhood_size=snr_binning, rebin_size=binning, mirror_coating=mirror_coating, dataloc=dataloc_maps, saveloc=dataloc
ENDIF
restore, dataloc + 'snr_' + filename_config + '.sav'
im_filename = dataloc + 'composite_' + filename_config + '_filtered.png'

; Create the image 
i1 = image(im_filename, dimensions=SunCET_image_size/binning, margin=0)
e = ellipse(750/2., 750/2., major=rsun_binned_pixels * rs_ellipse, /DATA, color='white', target=i1, fill_background=0)
c = contour(snr_smooth, contour_x * snr_binning / binning, contour_y * snr_binning / binning, overplot=i1, $
            c_value = [40, 10], c_color = ['dodger blue', 'tomato'], $
            c_thick=3, c_label_interval=[0.3, 0.19], /C_LABEL_SHOW, dimensions=SunCET)
c.font_size=20
i1.save, saveloc + 'snr_composite_filtered_' + filename_config + '.png', height=dim_y, width=dim_x

; Also save the ellipse and contours out as individual files for more control in Pixelmator
; Have to do some janky stuff to actually get it output at the right dimensions
tmp = fltarr(750, 750)
tmp[0, 0] = 1
tmp[-1, -1] = 1
i2 = image(tmp, dimensions=SunCET_image_size/binning, margin=0)
c = contour(snr_smooth, contour_x * snr_binning / binning, contour_y * snr_binning / binning, overplot=i2, $
            c_value = [40, 10], c_color = ['dodger blue', 'tomato'], $
            c_thick=3, c_label_interval=[0.3, 0.19], /C_LABEL_SHOW, dimensions=SunCET)
c.font_size=30
i2.save, saveloc + 'snr_contours_' + filename_config + '.png', transparent=[0, 0, 0], height=dim_y, width=dim_x

tmp = fltarr(750, 750)
i3 = image(tmp, dimensions=SunCET_image_size/binning, margin=0)
e = ellipse(750/2., 750/2., major=rsun_binned_pixels * rs_ellipse, /DATA, color='white', target=i3, fill_background=0)
i3.save, saveloc + '3Rs_.png', /TRANSPARENT, height=dim_y, width=dim_x
STOP
kill
END