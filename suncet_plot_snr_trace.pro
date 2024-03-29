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
;   binning [integer]:              The number of pixels binned over (in each direction). Will usually be snr_binning-1. Default is 2.
;   snr_binning [integer]:          The number of pixels binned over (in each direction) just for SNR calculation. Must be odd. Default is 3.
;   mirror_coating [string]:        Which mirror coating to use. Can be either 'b4c', 'alzr', or 'simo'. Default is 'b4c'.
;   exposure_time1 [float]:         The first of the two exposures times in the merged file. If not using a merged contour, code drops this optional input. Default is 0.035.
;   exposure_time2 [float]:         The second of the two exposure times in the merged file. If not using a merged contour, code only uses this optional input. Default is 15.0.
;   dataloc_rendered_maps [string]: Path to the rendered EUV maps that are loaded as input.
;   dataloc_snr [string]:           Path to the SNR contours that are loaded as input.
;   saveloc [string]:               Path to save the plot to.  
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
PRO SunCET_plot_snr_trace, binning=binning, snr_binning=snr_binning, mirror_coating=mirror_coating, exposure_time1=exposure_time1, exposure_time2=exposure_time2, dataloc_rendered_maps=dataloc_rendered_maps, dataloc_snr=dataloc_snr, saveloc=saveloc

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
IF dataloc_rendered_maps EQ !NULL THEN BEGIN
  dataloc_rendered_maps = getenv('SunCET_base') + 'MHD/dimmest/Rendered_EUV_Maps/'
ENDIF
IF dataloc_snr EQ !NULL THEN BEGIN
  dataloc_snr = getenv('SunCET_base') + 'SNR/dimmest/'
ENDIF
IF saveloc EQ !NULL THEN BEGIN
  saveloc = dataloc_snr
ENDIF
fontsize = 20

; ~Constants / config
plate_scale = 4.8 ; [arcsec/pixel]
rsun_binned_pixels = 960./plate_scale / binning
rs_ellipse = 3.5
SunCET_image_size = [1500, 1500]
dim_x = SunCET_image_size[0]/binning
dim_y = SunCET_image_size[1]/binning


; Load the contours and get the filtered image filename
filename_config = 'snr_' + JPMPrintNumber(exposure_time1) +'sec_' + JPMPrintNumber(exposure_time2) + 'sec_rebin_' + JPMPrintNumber(binning, /NO_DECIMALS) + '_' + mirror_coating
filename = dataloc_snr + filename_config + '.sav'
IF file_test(filename) NE 1 THEN BEGIN
  message, /IOERROR, JPMsystime() + ' Expected file ' + filename + ' that was not there. Make sure to run suncet_snr_merger.pro'
  return
ENDIF
message, /INFO, 'Restoring file: ' + filename
restore, filename

; Calculate some distances for annotations
imsize = size(snr_smooth)
x_arr = findgen(imsize[1], imsize[2]) mod imsize[1]
y_arr = rotate( findgen(imsize[1], imsize[2]) mod imsize[2], 1)
dist_arr = sqrt( (x_arr - imsize[1]/2.)^2 + (y_arr - imsize[2]/2.)^2 )
solar_radius_contour = fltarr(imsize[1], imsize[2])
solar_radius_contour[where(dist_arr GT rsun_binned_pixels * 1.0)] = 1.
requirement_radius_contour = fltarr(imsize[1], imsize[2])
requirement_radius_contour[where(dist_arr GT rsun_binned_pixels * 3.5)] = 1.

; Array tracing distance in Rs
fov_deg = 1. ; half-width field of view of SunCET [deg] 
au_cm = 1.5e13 ; [cm] 1 AU in cm
rs_cm = 6.96e10 ; [cm] 1 Rs in cm
fov_rs = fov_deg * !pi/180. * au_cm / rs_cm
distance_rs = [jpmrange(-fov_rs, 0, npts=dim_x/2.), jpmrange(0, fov_rs, npts=dim_x/2.)]

; Get the CME front SNR around 3.5 Rs
trace_fixed_y = dim_x/2.5
cme_front_ind = closest(3.5, distance_rs)
cme_front_snr = snr_smooth[cme_front_ind, trace_fixed_y]
print, 'CME front SNR is ' + JPMPrintNumber(cme_front_snr, /NO_DECIMALS) + ' for long exposure of ' + JPMPrintNumber(exposure_time2) + ' sec' + ' and binning of ' + JPMPrintNumber(binning, /NO_DECIMALS)

;im_filename = dataloc_snr + 'composite_' + JPMPrintNumber(exposure_time2) + 'sec_rebin_' + JPMPrintNumber(binning, /NO_DECIMALS) + '_' + mirror_coating + '_filtered.png'
im_filename = dataloc_snr + 'composite_15.00sec_rebin_2_b4c_filtered.png'
i1 = image(im_filename, image_dimensions=[dim_x, dim_y])
l1 = polyline([0, dim_x], [trace_fixed_y, trace_fixed_y], /DATA, /CURRENT, color='lime green', '3--')
i1.save, saveloc + 'snr_trace_image_' + filename_config + '.png'

c1 = contour(snr_smooth, contour_x, contour_y, c_value=[10, 40], c_label_show=[1, 1], $
             aspect_ratio = 1, /xstyle, /ystyle, c_color=['tomato', 'dodger blue'], c_thick=3)
c2 = contour(solar_radius_contour, contour_x, contour_y, c_value = 1, /OVERPLOT, color = 'goldenrod', c_label_show = 0)
c3 = contour(requirement_radius_contour, contour_x, contour_y, c_value = 1, /OVERPLOT, color='black', c_label_show = 0)
l2 = polyline([0, dim_x], [trace_fixed_y, trace_fixed_y], /DATA, dimensions=[dim_x, dim_y], /CURRENT, color='lime green', '3--')
c1.save, saveloc + 'snr_trace_contours_' + filename_config + '.png'

max_snr = max(snr_smooth[*, trace_fixed_y], max_snr_loc)
max_distance = distance_rs[max_snr_loc]
p1 = plot(distance_rs, snr_smooth[*, trace_fixed_y], '3--', color='lime green', font_size=fontsize, dimensions=[700, 700], $
          title='max SNR = ' + JPMPrintNumber(max_snr, /NO_DECIMALS) + ' at ' + JPMPrintNumber(max_distance) + 'Rs', $
          xtitle='distance [R$_\Sun^N$]', $ 
          ytitle='signal to noise ratio', yrange=[0, 50])
p2 = plot([3.5, 3.5], p1.yrange, '--', /OVERPLOT)
p1.save, saveloc + 'snr_trace_plot_' + filename_config + '.png'
  
END