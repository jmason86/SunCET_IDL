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
PRO SunCET_plot_snr_trace, binning=binning, snr_binning=snr_binning, mirror_coating=mirror_coating, exposure_time_sec=exposure_time_sec
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
IF exposure_time_sec EQ !NULL THEN BEGIN
  exposure_time_sec = 15.
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
filename_config = 'snr_0.03sec_' + JPMPrintNumber(exposure_time_sec) + 'sec_rebin_' + JPMPrintNumber(binning, /NO_DECIMALS) + '_' + mirror_coating
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
distance_rs = [jpmrange(-fov_rs, 0, npts=750./2.), jpmrange(0, fov_rs, npts=750./2.)]

; Get the CME front SNR around 3.5 Rs
trace_fixed_y = 750/2.-50
cme_front_ind = closest(3.5, distance_rs)
cme_front_snr = snr_smooth[cme_front_ind, trace_fixed_y]
print, 'CME front SNR is ' + JPMPrintNumber(cme_front_snr, /NO_DECIMALS) + ' for long exposure of ' + JPMPrintNumber(exposure_time_sec) + ' sec'

p1 = plot(distance_rs, snr_smooth[*, trace_fixed_y], '3--', color='lime green', font_size=fontsize, dimensions=[600, 1500], $
          xtitle='distance [R$_\Sun^N$]', $ 
          ytitle='signal to noise ratio')
;p2 = plot(distance_rs, snr_smooth[*, 750/2.-50], '3--', color='lime green', layout=[1, 2, 2], /CURRENT, font_size=fontsize, $
;          xtitle='distance [R$_\Sun^N$]', $
;          ytitle='signal to noise ratio', yrange=[0, 200])
p1.save, saveloc + 'SNR trace.png'
;p1.save, saveloc + 'SNR trace.pdf', height=11, page_size=[7, 10]
STOP
  
kill
END