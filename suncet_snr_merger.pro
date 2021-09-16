;+
; NAME:
;   SunCET_snr_merger
;
; PURPOSE:
;   The SNR contours are generated separately for the short and long exposures. This code merges them. 
;
; INPUTS:
;   None, but requires access to files in SunCET_base
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plots to screen and disk
;   IDL saveset to disk with the merged contours
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to SunCET_base files and that environment variable to be set
;
; EXAMPLE:
;   Just run it
;-
PRO SunCET_snr_merger


;;; it takes a long time to generate the SNR plots because you have to run the image simulator multiple times
;;; so I am just saving them and recycling them
restore, getenv('SunCET_base') + '/SNR/2011-02-15/Contours/snr_0.03sec_rebin_2_b4c.sav'
snr_035_smooth = snr_smooth
restore, getenv('SunCET_base') + '/SNR/2011-02-15/Contours/snr_5.00sec_rebin_2_b4c.sav'
snr_5s_smooth = snr_smooth
restore, getenv('SunCET_base') + '/SNR/2011-02-15/Contours/snr_15sec_rebin_2_b4c.sav'

;;; In the model data one solar radius = 200 px, but we have rebinned so it is 100 px
solrad = 100 ; px

;;; generate some arrays we will need for plotting and merging
imsize = size(snr_smooth)
mask = fltarr(imsize[1], imsize[2])
sun = mask

;;; This generates an array where each pixel is its distance to sun-center
x_arr = findgen(imsize[1], imsize[2]) mod imsize[1]
y_arr = rotate( findgen(imsize[1], imsize[2]) mod imsize[2], 1)
dist_arr = sqrt( (x_arr - imsize[1]/2.)^2 + (y_arr - imsize[2]/2.)^2 )

;;; set the long/short merge point by adjusting the value below
mask[where(dist_arr gt solrad * 1.5)] = 1.

;;; this is just a super cheap way to draw a contour around the solar limb later on
sun[where(dist_arr gt solrad * 1.0)] = 1.

;;; merge the long/short SNR arrays at the merge point using the mask
;;; change the arrays below to select different sets of SNRs
merged_contours = mask * snr_5s_smooth + (1 - mask) * snr_035_smooth
snr_smooth = merged_contours
save, snr_smooth, contour_x, contour_y, filename = getenv('SunCET_base') + '/SNR/2011-02-15/Contours/snr_0.03sec_5.00sec_rebin_2_b4c.sav'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; the variable above is the one you want for plotting SNR across an authentic composite image ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Plot the contours, and some other details to help show how things fit together
graphic = contour(merged_contours, (contour_x - 375)/solrad, (contour_y - 375)/solrad, c_value = [10, 30, 100, 300], c_label_show = [1, 1, 1, 1], $
	aspect_ratio = 1, /xstyle, /ystyle, color = 'black')
graphic_2 = contour(mask, (contour_x - 375)/solrad, (contour_y - 375)/solrad, c_value = 1, /overplot, color = 'blue', c_label_show = 0)
graphic_3 = contour(sun, (contour_x - 375)/solrad, (contour_y - 375)/solrad, c_value = 1, /overplot, color = 'goldenrod', c_label_show = 0)
graphic_4 = contour(dist_arr/solrad, (contour_x - 375)/solrad, (contour_y - 375)/solrad, c_value = [1.5, 2, 2.5, 3.], /overplot, color = 'red', c_label_show = 0)



;;; this is just to generate some images for comparison – probably don't use these, it's better to use the 
;;; real ones that are more carefully generated, but useful for some quick analysis

;; set up some variables
snr_neighborhood_size = 3
rebin_size = 2
mirror_coating = 'b4c'
dataloc = getenv('SunCET_base') + '/MHD/Rendered_EUV_Maps_2011-02-15/fast_cme/'
SunCET_image_size = [1500, 1500]
restore, dataloc + '/euv_sim_150.sav', /VERBOSE

sc_plate_scale = 4.8
; exptime = 0.035  ; for solar disk
rsun = 960./sc_plate_scale
theta = findgen(361) * !pi/180.

;;; make some images
exptime = 15
image_simulator, rendered_maps, map_metadata.dx, lines.wvl, exposure=exptime, mirror_coating=mirror_coating, /no_spike, $
		               output_pure = pure_image15, output_image_noise=noise_image15, output_image_final=image15

exptime = 5
image_simulator, rendered_maps, map_metadata.dx, lines.wvl, exposure=exptime, mirror_coating=mirror_coating, /no_spike, $
		               output_pure = pure_image5, output_image_noise=noise_image5, output_image_final=image5

exptime = 0.035
image_simulator, rendered_maps, map_metadata.dx, lines.wvl, exposure=exptime, mirror_coating=mirror_coating, /no_spike, $
		               output_pure = pure_image035, output_image_noise=noise_image035, output_image_final=image035


;;; some quick and dirty plot making 
loadct, 0
plot_image, rebin(image5, 750, 750)^0.25
loadct, 39
contour, snr_smooth, levels = [10, 30, 100, 300], /overplot, color = 80, c_label = replicate(1, 4), c_charsi = 2
contour, snr_5s_smooth, levels = [10, 30, 100, 300], /overplot, color = 80, c_label = replicate(1, 4), c_charsi = 2
contour, dist_arr, levels = [1, 2] * solrad, color = 150, /overplot
contour, dist_arr, levels = [1.5] * solrad, color = 254, /overplot

loadct, 0
plot_image, rebin(image035, 750, 750)^0.25
loadct, 39
contour, merged_contours, levels = [10, 30, 100], /overplot, color = 80, c_label = replicate(1, 4), c_charsi = 2
contour, dist_arr, levels = [1.5] * solrad, color = 254, /overplot


contour, dist_arr, levels = [1, 2] * solrad, color = 150, /overplot

END