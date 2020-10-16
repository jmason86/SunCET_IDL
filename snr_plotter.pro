;; recover an EUV map 
restore, '/Users/dbseaton/Documents/Ongoing_Research/SunCET/Rendered_EUV_Maps/euv_sim_320.sav', /verbose

;; configure some values we need for the sim and plotter
sc_plate_scale = 4.8
exptime = 10.
rsun = 960./sc_plate_scale
theta = findgen(361) * !pi/180.
;; this is the box over which we calculate statistics
;; it has a bad variable name but I don't want to change it 
sd_box = 3 ;;; always odd to maintain centering!

;; run the simulator
image_simulator, rendered_maps, map_metadata.dx, lines.wvl, exposure = exptime, /no_spike, $
	output_pure = pure_image, output_image_noise=noise_image, output_image_final=image

;; rebin to the real image scale 
rebin_pure_image = rebin(pure_image, 750, 750) * 4.
rebin_standard_image = rebin(image, 750, 750) * 4.

;; sub_stack is a holder array we use for fast neighborhood calculations
sub_stack = fltarr(750, 750, sd_box^2)
;; this is the image we insert for calculating
subimage = rebin_pure_image

;; generate an array where neighborhood calculations can be performed in the z direction
i = 0
for x = 0, sd_box - 1 do begin & $
	for y = 0, sd_box - 1 do begin & $
		sub_stack[*, *, i++] = shift(subimage,  x - (sd_box - 1)/2, y - (sd_box - 1)/2) & $
	endfor & $
endfor

;; mvoe the result to a new holder, because we want to do this again 
pure_sub_stack = sub_stack 

;;  same as above
sub_stack = fltarr(750, 750, sd_box^2)
subimage = rebin_standard_image

i = 0
for x = 0, sd_box - 1 do begin & $
	for y = 0, sd_box - 1 do begin & $
		sub_stack[*, *, i++] = shift(subimage,  x - (sd_box - 1)/2, y - (sd_box - 1)/2) & $
	endfor & $
endfor

;; Here are some things we might want to calculate, following discussion in 
;; https://www.irjet.net/archives/V4/i1/IRJET-V4I1156.pdf ;;;

local_rms = sqrt( total( (pure_sub_stack - sub_stack)^2, 3 ) )/sd_box^2
MSE =  total( (pure_sub_stack - sub_stack)^2, 3 ) /sd_box^2

local_max = max(pure_sub_stack, dim = 3)
PSNR = 10 * alog10( local_max^2/MSE^2 )

;; make a plot 

rsun_use = rsun/2.
xcen = 750/2.
ycen = 750/2.

set_plot, 'ps'
device, filename = 'snr_plot.eps', /encapsulated
device, xsize = 6, ysize = 6, /inches
device, bits_per_pixel = 8, /color 


loadct, 0
xmargin_default = !x.margin
ymargin_default = !y.margin
!x.margin = [4, 3]
!y.margin = [4, 3]
plot_image, alog10(rebin_standard_image), min = 0, $
	origin = [-xcen/rsun_use, -ycen/rsun_use], scale = [1./rsun_use, 1./rsun_use], charsi = 0.75, $
	xtitle = 'Distance (R!dSun!n)', ytitle = 'Distance (R!dSun!n)', charthick = 1.5
!x.margin = xmargin_default
!y.margin = ymargin_default

loadct, 39
xcir = 0 + 1 * cos(theta)
ycir = 0 + 1 * sin(theta)
oplot, xcir, ycir, color = 100

xcir = 0 + 2 * cos(theta)
ycir = 0 + 2 * sin(theta)
oplot, xcir, ycir, color = 100

xcir = 0 + 3 * cos(theta)
ycir = 0 + 3 * sin(theta)
oplot, xcir, ycir, color = 100

xcir = 0 + 4 * cos(theta)
ycir = 0 + 4 * sin(theta)
oplot, xcir, ycir, color = 100

contour, smooth(rebin_pure_image/local_rms , 20, /edge_truncate), (findgen(750) - xcen)/rsun_use, (findgen(750) - xcen)/rsun_use, $
	levels = [1, 3, 10, 30, 100, 300], c_label = [1, 3, 10, 30, 100, 300], $
	/overplot, c_charsi = 0.65, color = 255

device, /close 

set_plot, 'x'