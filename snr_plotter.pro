;+
; NAME:
;   snr_plotter
;
; PURPOSE:
;   Plot the signal to noise ratio as contours on an image
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   SNR_NEIGHBORHOOD_SIZE: Specify the scale in rebinned macropixels over which we compute noise levels for SNR analysis (default: 3)
;                          This must be an odd number to ensure SNR calculation window remains centered on corresponding image pixels
;   REBIN_RESOLUTION: 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Images with contours on screen and on disk
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to the synthetic EUV images
;
; EXAMPLE:
;   Just run it!
;-
PRO snr_plotter, snr_neighborhood_size=snr_neighborhood_size, rebin_size=rebin_size, mirror_coating=mirror_coating

; Defaults
dataloc = getenv('SunCET_base') + 'MHD/Rendered_EUV_Maps/'
saveloc = getenv('SunCET_base') + 'SNR/'
if ~keyword_set(snr_neighborhood_size) then snr_neighborhood_size = 3
if ~keyword_set(rebin_size) then rebin_size = 2
IF mirror_coating EQ !NULL THEN mirror_coating = 'b4c'

; ~Constants
SunCET_image_size = [1500, 1500]

;; Ensure snr_neighborhood_size is odd
if (snr_neighborhood_size mod 2) eq 0 then message, "SNR Neighborhood must be odd."

;; recover an EUV map 
;; leading edge of CME is approaching the edge of our sim at frame 150
restore, dataloc + '/euv_sim_150.sav', /VERBOSE

;; configure some values we need for the sim and plotter
sc_plate_scale = 4.8
exptime = 15.
rsun = 960./sc_plate_scale
theta = findgen(361) * !pi/180.
;; this is the box over which we calculate statistics
;; it has a bad variable name but I don't want to change it 

;; run the simulator
synth_image_arr = fltarr(SunCET_image_size[0], SunCET_image_size[1], 4)
for n = 0, 3 do begin 
	image_simulator, rendered_maps, map_metadata.dx, lines.wvl, exposure=exptime, mirror_coating=mirror_coating, /no_spike, $
		               output_pure = pure_image, output_image_noise=noise_image, output_image_final=image
	synth_image_arr[*, *, n] = image
endfor

;; rebin to the real image scale 
rebin_pure_image = rebin(pure_image, SunCET_image_size[0]/rebin_size, SunCET_image_size[1]/rebin_size) * rebin_size^2.
rebin_standard_image = rebin(median(synth_image_arr, dim = 3), SunCET_image_size[0]/rebin_size, SunCET_image_size[1]/rebin_size) * rebin_size^2.

;; sub_stack is a holder array we use for fast neighborhood calculations
sub_stack = fltarr(SunCET_image_size[0]/rebin_size, SunCET_image_size[1]/rebin_size, snr_neighborhood_size^2)
;; this is the image we insert for calculating
subimage = rebin_pure_image

;; generate an array where neighborhood calculations can be performed in the z direction
i = 0
for x = 0, snr_neighborhood_size - 1 do begin & $
	for y = 0, snr_neighborhood_size - 1 do begin & $
		sub_stack[*, *, i++] = shift(subimage,  x - (snr_neighborhood_size - 1)/2, y - (snr_neighborhood_size - 1)/2) & $
	endfor & $
endfor

;; move the result to a new holder, because we want to do this again 
pure_sub_stack = sub_stack 

;;  same as above
sub_stack = fltarr(SunCET_image_size[0]/rebin_size, SunCET_image_size[1]/rebin_size, snr_neighborhood_size^2)
subimage = rebin_standard_image

i = 0
for x = 0, snr_neighborhood_size - 1 do begin & $
	for y = 0, snr_neighborhood_size - 1 do begin & $
		sub_stack[*, *, i++] = shift(subimage,  x - (snr_neighborhood_size - 1)/2, y - (snr_neighborhood_size - 1)/2) & $
	endfor & $
endfor

;; Here are some things we might want to calculate, following discussion in 
;; https://www.irjet.net/archives/V4/i1/IRJET-V4I1156.pdf ;;;

local_rms = sqrt( total( (pure_sub_stack - sub_stack)^2, 3 ) )/snr_neighborhood_size^2
MSE =  total( (pure_sub_stack - sub_stack)^2, 3 ) /snr_neighborhood_size^2

local_max = max(pure_sub_stack, dim = 3)
PSNR = 10 * alog10( local_max^2/MSE^2 )

snr_smooth = smooth(rebin_pure_image/local_rms, 20, /edge_truncate)
contour_x = findgen(SunCET_image_size[1]/rebin_size)
contour_y = findgen(SunCET_image_size[1]/rebin_size)
save, contour_x, contour_y, snr_smooth, filename=saveloc + 'snr_' + jpmprintnumber(exptime) + 'sec_' + 'rebin_' + jpmprintnumber(rebin_size, /NO_DECIMALS) + '_' + mirror_coating + '.sav' 

;; make a plot 

rsun_use = rsun/rebin_size
xcen = SunCET_image_size[0]/(rebin_size * 2)
ycen = SunCET_image_size[1]/(rebin_size * 2)

saturated_normal = 65535L
saturated_log = alog10(saturated_normal)

; IDL plotting function method
i1 = image(alog10(rebin_standard_image), max_value=saturated_log, min_value=0, dimensions=SunCET_image_size/rebin_size, $
	         background_color='black', margin=0, window_title='SNR Contours')
FOR r_index = 1, 4 DO e = ellipse(xcen, ycen, major=rsun_use * r_index, /data, color='white', target=i1, fill_background=0)
c = contour(smooth(rebin_pure_image/local_rms, 20, /edge_truncate), findgen(SunCET_image_size[0]/rebin_size), $
			      findgen(SunCET_image_size[1]/rebin_size), color='tomato', /OVERPLOT, $
            c_value = [30, 10, 1], c_thick=3, c_label_interval=[0.3, 0.5, 0.4], /C_LABEL_SHOW)
c.font_size = 16
i1.save, saveloc + 'snr_image_' + jpmprintnumber(exptime) + 'sec_' + 'rebin_' + jpmprintnumber(rebin_size, /NO_DECIMALS) + '_' + mirror_coating +'.png' 



STOP



; ; SSW / contour procedure method
; set_plot, 'ps'
; device, filename = 'snr_plot.eps', /encapsulated
; device, xsize = 6, ysize = 6, /inches
; device, bits_per_pixel = 8, /color 


; loadct, 0
; xmargin_default = !x.margin
; ymargin_default = !y.margin
; !x.margin = [4, 3]
; !y.margin = [4, 3]
; plot_image, alog10(rebin_standard_image), min = 0, $
; 	          origin = [-xcen/rsun_use, -ycen/rsun_use], scale = [1./rsun_use, 1./rsun_use], charsi = 0.75, $
;             xtitle = 'Distance (R!dSun!n)', ytitle = 'Distance (R!dSun!n)', charthick = 1.5
; !x.margin = xmargin_default
; !y.margin = ymargin_default

; loadct, 39
; xcir = 0 + 1 * cos(theta)
; ycir = 0 + 1 * sin(theta)
; oplot, xcir, ycir, color = 100

; xcir = 0 + 2 * cos(theta)
; ycir = 0 + 2 * sin(theta)
; oplot, xcir, ycir, color = 100

; xcir = 0 + 3 * cos(theta)
; ycir = 0 + 3 * sin(theta)
; oplot, xcir, ycir, color = 100

; xcir = 0 + 4 * cos(theta)
; ycir = 0 + 4 * sin(theta)
; oplot, xcir, ycir, color = 100

; contour, smooth(rebin_pure_image/local_rms , 20, /edge_truncate), $
; 	(findgen(SunCET_image_size[0]/rebin_size) - xcen)/rsun_use, (findgen(SunCET_image_size[1]/rebin_size) - xcen)/rsun_use, $
; 	levels = [1, 3, 10, 30, 100, 300], c_label = [1, 3, 10, 30, 100, 300], $
; 	/overplot, c_charsi = 0.65, color = 255

; device, /close 

; set_plot, 'x'

END