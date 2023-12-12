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
;   snr_levels [fltarr]: The SNR values to be shown in the contour overlay. Default is [40, 10].
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
PRO SunCET_overlay_snr, binning=binning, snr_binning=snr_binning, mirror_coating=mirror_coating, exposure_time_sec=exposure_time_sec, snr_levels=snr_levels, $
                        VIGIL_APL=VIGIL_APL
kill

; Defaults
IF binning EQ !NULL THEN BEGIN
  binning = 2
ENDIF
IF snr_binning EQ !NULL THEN BEGIN
  snr_binning = binning+1 ; [pixels] The number of pixels used for binning for the SNR calculation
ENDIF
IF mirror_coating EQ !NULL THEN BEGIN
  mirror_coating = 'b4c'
ENDIF
IF exposure_time_sec EQ !NULL THEN BEGIN
  exposure_time_sec = 15.
ENDIF
IF snr_levels EQ !NULL THEN BEGIN
  snr_levels = [40, 10]
ENDIF
IF keyword_set(VIGIL_APL) THEN BEGIN
  binning = 2
  snr_binning = 3
  filter = 'Al_150nm' ; TODO
  mesh_transmission =  0.83 ; [% but as a fraction] 5lpi nickel mesh = 0.98, 20 LPI = ????, 70 LPI nickel mesh = 0.83
  mirror_coating = 'frederic_195' ; TODO
  exposure_time_sec = 60
  SunCET_image_size = [2048, 2048]
  segmentation = 2.
ENDIF ELSE BEGIN
  SunCET_image_size = [1500, 1500]
ENDELSE

; Paths
dataloc = getenv('SunCET_base') + '/snr/dimmest/'
dataloc_maps = getenv('SunCET_base') + 'mhd/dimmest/rendered_euv_maps/'
saveloc = dataloc

; ~Constants / config
plate_scale = 4.8 ; [arcsec/pixel]
rsun_binned_pixels = 960./plate_scale / binning
rs_ellipse = 3.5
dim_x = SunCET_image_size[0]/binning
dim_y = SunCET_image_size[1]/binning

; Load the contours and get the filtered image filename
filename_config = 'snr_' + JPMPrintNumber(exposure_time_sec) + 'sec_rebin_' + JPMPrintNumber(binning, /NO_DECIMALS) + '_' + mirror_coating
filename = dataloc + filename_config + '.sav'
;IF file_test(filename) NE 1 THEN BEGIN
  snr_plotter, exposure_time_sec=exposure_time_sec, snr_neighborhood_size=snr_binning, rebin_size=binning, filter=filter, mesh_transmission=mesh_transmission, mirror_coating=mirror_coating, segmentation=segmentation, dataloc=dataloc_maps, saveloc=dataloc, VIGIL_APL=VIGIL_APL
;ENDIF
restore, filename
im_filename = dataloc + 'composite_' + filename_config + '_filtered.png'
im_filename = dataloc + 'composite_15.00sec_rebin_2_b4c_filtered.png'
;im_filename = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/SunCET Image Simulation/Image Simulation Results/2011-02-15/214_5_0.03_4_5.00_log.png'

; Create the image 
;i1 = image(im_filename, dimensions=SunCET_image_size/binning, margin=0)
;;e = ellipse(750/2., 750/2., major=rsun_binned_pixels * rs_ellipse, /DATA, color='white', target=i1, fill_background=0)
;c = contour(snr_smooth, contour_x/4., contour_y/4., overplot=i1, $
;            c_value = snr_levels, c_color = ['dodger blue', 'tomato'], $
;            c_thick=3, c_label_interval=[0.3, 0.19], /C_LABEL_SHOW, dimensions=SunCET_image_size/binning)
;c.font_size=20
;i1.save, saveloc + 'snr_composite_filtered_' + filename_config + '.png', height=dim_y, width=dim_x

; Also save the ellipse and contours out as individual files for more control in Pixelmator
; Have to do some janky stuff to actually get it output at the right dimensions
tmp = fltarr(dim_x, dim_y)
tmp[0, 0] = 1
tmp[-1, -1] = 1
i2 = image(tmp, dimensions=SunCET_image_size, margin=0)
c = contour(snr_smooth, contour_x/binning, contour_y/binning, overplot=i2, $
            ;c_value = snr_levels, c_color = ['dodger blue', 'tomato'], $
            c_thick=3, c_label_interval=[0.3, 0.19], /C_LABEL_SHOW, dimensions=SunCET_image_size)
c.font_size=30
i2.save, saveloc + 'snr_contours_' + filename_config + '.png', transparent=[0, 0, 0], height=dim_y, width=dim_x

tmp = fltarr(dim_x, dim_y)
i3 = image(tmp, dimensions=SunCET_image_size/binning, margin=0)
e = ellipse(750/2., 750/2., major=rsun_binned_pixels * rs_ellipse, /DATA, color='white', target=i3, fill_background=0)
i3.save, saveloc + '3Rs_.png', /TRANSPARENT, height=dim_y, width=dim_x
STOP
kill
END