;+
; NAME:
;   SunCET_plot_snr_trace
;
; PURPOSE:
;   Plot a trace of SNR
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   binning [integer]: The number of pixels binned over (in each direction). Will usually be snr_binning-1. Default is 2.
;   snr_binning [integer]: The number of pixels binned over (in each direction) just for SNR calculation. Must be odd. Default is 3.
;   mirror_coating [string]: Which mirror coating to use. Can be either 'b4c', 'alzr', or 'simo'. Default is 'b4c'.
;   exposure_time1 [float]: The first of the two exposures times in the merged file. If not using a merged contour, code drops this optional input. Default is 0.035.
;   exposure_time2 [float]: The second of the two exposure times in the merged file. If not using a merged contour, code only uses this optional input. Default is 15.0.
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
PRO SunCET_plot_snr_trace, binning=binning, snr_binning=snr_binning, mirror_coating=mirror_coating, exposure_time1=exposure_time1, exposure_time2=exposure_time2
kill

; Defaults
IF binning EQ !NULL THEN BEGIN
  binning = 2
ENDIF
IF snr_binning EQ !NULL THEN BEGIN
  snr_binning = 3 ; [pixels] The number of pixels used for binning for the SNR calculation (must be odd)
ENDIF
IF mirror_coating EQ !NULL THEN BEGIN
  mirror_coating = 'b4c'
ENDIF
IF exposure_time1 EQ !NULL THEN BEGIN
  exposure_time1 = 0.035
ENDIF
IF exposure_time2 EQ !NULL THEN BEGIN
  exposure_time2 = 15.
ENDIF
fontsize = 20

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
filename_config = 'snr_' + JPMPrintNumber(exposure_time1) + 'sec_' + JPMPrintNumber(exposure_time2) + 'sec_rebin_' + JPMPrintNumber(binning, /NO_DECIMALS) + '_' + mirror_coating
filename = dataloc + filename_config + '.sav'
IF file_test(filename) NE 1 THEN BEGIN
  snr_plotter, snr_neighborhood_size=snr_binning, rebin_size=binning, mirror_coating=mirror_coating, dataloc=dataloc_maps, saveloc=dataloc
ENDIF
restore, filename
im_filename = dataloc + 'composite_' + filename_config + '_filtered.png'
  
; Array tracing distance in Rs
fov_deg = 1. ; half-width field of view of SunCET [deg] 
au_cm = 1.5e13 ; [cm] 1 AU in cm
rs_cm = 6.96e10 ; [cm] 1 Rs in cm
fov_rs = fov_deg * !pi/180. * au_cm / rs_cm
distance_rs = [jpmrange(-fov_rs, 0, npts=dim_x/2.), jpmrange(0, fov_rs, npts=dim_x/2.)]

; Get the CME front SNR around 3.5 Rs
trace_fixed_y = dim_x/2.-50
cme_front_ind = closest(3.5, distance_rs)
cme_front_snr = snr_smooth[cme_front_ind, trace_fixed_y]
print, 'CME front SNR is ' + JPMPrintNumber(cme_front_snr, /NO_DECIMALS) + ' for long exposure of ' + JPMPrintNumber(exposure_time2) + ' sec' + ' and binning of ' + JPMPrintNumber(binning, /NO_DECIMALS)

p1 = plot(distance_rs, snr_smooth[*, trace_fixed_y], '3--', color='lime green', font_size=fontsize, dimensions=[600, 1500], $
          xtitle='distance [R$_\Sun^N$]', $ 
          ytitle='signal to noise ratio')
p1.save, saveloc + 'SNR trace.png'
STOP
  
kill
END