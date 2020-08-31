;+
; NAME:
;   SunCET_image_simulator
;
; PURPOSE:
;   Wrap Dan's image_simulator code that processes a single image. Run for multiple images and with varying exposure times.
;   Apply the SHDR algorithm. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   HIGHLIGHT_SUB_IMAGES: Set to make the sub images clearly distinct
;
; OUTPUTS:
;   To disk and screen: simulated SunCET images
;   To disk and console: estimated SNR
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires Meng Jin's MHD synthetic image data as input (or really any image data will work, but set up to work specifically with that)
;
; EXAMPLE:
;   Just run it
;-
PRO SunCET_image_simulator, HIGHLIGHT_SUB_IMAGES=HIGHLIGHT_SUB_IMAGES
kill
; Defaults
exposure_short = 0.025 ; [sec]
exposure_long = 3.0 ; [sec]
SunCET_image_size = [1500, 1500]
IF keyword_set(HIGHLIGHT_SUB_IMAGES) THEN BEGIN
  sub1 = 'RED TEMPERATURE'
  sub2 = 'CB-Oranges'
  sub3 = 'BLUE/WHITE'
ENDIF ELSE BEGIN
  sub1 = 'B-W LINEAR'
  sub2 = sub1
  sub3 = sub1
ENDELSE


restore, '/Users/jmason86/Dropbox/Research/Data/AIA/aia_response.sav'
restore, '/Users/jmason86/Dropbox/Research/Data/MHD/For SunCET Phase A/aia_sim/aia_sim_049.sav'

; get a model image
image1 = aia193_image.data
image2 = aia171_image.data

; get the conversion to photons at the response peak
; dumb assumption that all counts originate here
; we can do this much smarter, used for illustrative purposes
resp_peak1 = where(max(resp.a193.ea) eq resp.a193.ea) ; maybe want to use the mean instead of the max across a reasonable range of the response (e.g., FWHM)
resp_peak2 = where(max(resp.a171.ea) eq resp.a171.ea)
resp_dn_to_phot_ea1 = resp.a193.ea[resp_peak1[0]]
resp_dn_to_phot_ea2 = resp.a171.ea[resp_peak2[0]]

; image has units dn/s
; response is cm^2 DN phot^-1 px^-1
phot_flux_image1 = image1/resp_dn_to_phot_ea1
phot_flux_image2 = image2/resp_dn_to_phot_ea2

; boost to make the input image a little more viable
; TODO: need to remove this and do the conversion to photons properly!!
phot_flux_image1 = phot_flux_image1 * (20./0.6)^2  ; Fine tune if DN/s is really low -- this is a geometric scaling ; TODO: check if Meng does flux conservation in what he provides
phot_flux_image2 = phot_flux_image2 * (20./0.6)^2
phot_flux_image = phot_flux_image1 + phot_flux_image2 ; [photon cm^-2 s^-1 px^-1] -- SHOULD be anyway... TODO: check

; TODO: Replace the above with the new model that covers SunCET bandpass

input_image = congrid(phot_flux_image, SunCET_image_size[0], SunCET_image_size[1], cubic=-0.5)

image_simulator, input_image, exposure_time_sec = exposure_short, output_SNR=snr_short, output_image_noise=image_noise_short, output_image_final=image_short
image_simulator, input_image, exposure_time_sec = exposure_long, output_SNR=snr_long, output_image_noise=image_noise_long, output_image_final=image_long

;
; SHDR
;

; Disk bounds in pixels
bound0 = 0    ; start pixel
bound1 = 500  ; pixels in to solar limb
bound2 = 1000  ; pixels in to opposite solar limb
bound3 = 1499 ; final pixel

; Disk pixels (circle)
xcen = SunCET_image_size[0] / 2
ycen = SunCET_image_size[1] / 2
radius = (bound2 - bound1) / 2.
x = indgen(SunCET_image_size[0])
y = indgen(SunCET_image_size[1])
xgrid = x # replicate(1, n_elements(y))
ygrid = replicate(1, n_elements(x)) # y
mask1d = where(((xgrid-xcen)^2. + (ygrid-ycen)^2.) LE radius^2.)
mask2d = array_indices(input_image, mask1d)
im_disk = fltarr(SunCET_image_size)
FOR i = 0, n_elements(mask2d[0, *]) - 1 DO BEGIN
  im_disk[mask2d[0, i], mask2d[1, i]] = image_short[mask2d[0, i], mask2d[1, i]]
ENDFOR
; Re-NaN since somehow ended up turning the NaNs to 0s
im_disk[where(im_disk EQ 0)] = !VALUES.F_NAN

; Off disk pixels
im_outer = im_disk
im_mid = im_disk
im_outer[bound0:bound1, *] = image_long[bound0:bound1, *]
im_mid[bound1 + 1:bound2, *] = image_long[bound1 + 1:bound2, *]
im_outer[bound2 + 1:bound3, *] = image_long[bound2 + 1:bound3, *]

; Normalize by exposure time
im_outer /= exposure_long
im_mid /= exposure_long
im_disk /= exposure_short

i1 = image(im_outer^0.2, rgb_table=sub1, dimensions=SunCET_IMAGE_SIZE, margin=0, BACKGROUND_COLOR='black')
i2 = image(im_mid^0.2, rgb_table=sub2, /OVERPLOT)
i3 = image(im_disk^0.2, rgb_table=sub3, /OVERPLOT)

i1 = image((im_outer)^0.2, max_value=4320000.0^0.2, min_value=0, rgb_table=sub1, dimensions=SunCET_IMAGE_SIZE, margin=0, BACKGROUND_COLOR='black')
i2 = image((im_mid)^0.2, max_value=4320000.0^0.2, min_value=0, rgb_table=sub2, /OVERPLOT)
i3 = image((im_disk)^0.2, max_value=4320000.0^0.2, min_value=0, rgb_table=sub3, /OVERPLOT)

i1 = image(alog10(im_outer), max_value=alog10(4320000.0), min_value=0, rgb_table=sub1, dimensions=SunCET_IMAGE_SIZE, margin=0, BACKGROUND_COLOR='black')
i2 = image(alog10(im_mid), max_value=alog10(4320000.0), min_value=0, rgb_table=sub2, /OVERPLOT)
i3 = image(alog10(im_disk), max_value=alog10(4320000.0), min_value=0, rgb_table=sub3, /OVERPLOT)



STOP
END