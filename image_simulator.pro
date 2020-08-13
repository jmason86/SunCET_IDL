;; this is a simple approach for a single frame, a fancier approach would be to generate multiple frames
;; and then do the on-board image summation logic on those as well.



;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; generate a base image ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; get a model image
image = aia193_image.data

;; get the aia response 
resp = aia_get_response(/dn)

;; get the conversion to photons at the response peak 
;; dumb assumption that all counts originate here
;; we can do this much smarter, used for illustrative purposes
resp_peak = where(max(resp.a193.ea) eq resp.a193.ea) ; maybe want to use the mean instead of the max across a reasonable range of the response (e.g., FWHM)
resp_dn_to_phot_ea = resp.a193.ea[resp_peak[0]]

;; image has units dn/s
;; response is cm^2 DN phot^-1 px^-1
phot_flux_image = image/resp_dn_to_phot_ea
; TODO: check work above

;; boost to make the input image a little more viable
;; need to remove this and do the conversion to photons properly!!
phot_flux_image = phot_flux_image * 1000.

; TODO: convert to right plate scale: use congrid, then multiple by ratio of the image resolutions (20^2/7.8^2)

; TODO: play: if there's < 1 photon in many of the pixels, then the code doesn't work.. so need to scale up

;; phot flux image has units of photon cm^-2 s^-1 px^-1
;; SunCET aperture is 44.9 cm^2
;; Assume a 10-s effective exposure
sc_aperture = 44.9 ; cm^2
sc_reflectivity = 0.223 * 0.223 ; two mirrors
sc_transmission = 0.6 * 0.85 ; entrance filter transmission * detector filter
sc_qe = 0.85 ; possibly also need to include quantum yield later on, but I have ignored this here 
; TODO: Add quantum yield, consider doing it as a function of wavelength (171Å = 72.9 ev/3.63; 200Å = 62 ev/3.63)
; TODO: this quantum yield could have it's own shot noise as well: it's not always exactly 18.46 e-/ph -- could do random on it

sc_eff_area =  sc_aperture * sc_reflectivity * sc_transmission ; cm^2 ; TODO: can fold in sc_qe here
sc_exposure = 1. ; TODO: do the exposure compositing here; this brings the noise down but leaves the signal the same

;; sc photon image will have units of phot px^-1
sc_phot_image = phot_flux_image * sc_eff_area * sc_exposure

; TODO: Consider adding in scattered light psf here, accounting for secondary mirror and spider mounts

;; simulate shot noise by randomizing with poisson distribution
;; use a specific random number seed for repeatability
sc_phot_sn_image = fltarr(1024, 1024)
for x = 0, 1023 do for y = 0, 1023 do sc_phot_sn_image[x, y] = (RANDOMU(10272011L, poisson = (sc_phot_image[x, y]) > 1e-8, /double) > 0.)
; TODO: sanity check on the Poisson here
; TODO: sanity check by looking at before and after images


; TODO: sc_qy has to go into the algorithm after this point once we have done photon shot noise


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate base camera performance ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Average Dark Current
sc_dark_mean = 1D ; 1 e-/px/s

;; Average Bias
;sc_bias_mean = 20D ; e-/px ; TODO: May not apply to CMOS, need to check -- there's e- shot noise if bias is low

;; Read Noise
sc_read_noise = 5D ; e-

;; Camera Gain
;sc_gain = 10 ; phot/e- (totally imaginary gain number) ; TODO: find out what gain Alan applies

;; Camera Full Well
sc_fw = 1.08D6 ; e- in full well (totally imaginary)

;; Camera Readout Bits
sc_readout_bits = 16  ; (totally imaginary)

;; Camera Readout Conversion 
;; This is a bit of a kludge here 
;; I'm sure there's a smarter way to do this if you fully 
;; understand the camera performance and readout characteristics 
sc_conversion = sc_fw/2.^sc_readout_bits ; e-/DN ; TODO: double check this

;; Generate a bias frame 
;BiasFrame = RANDOMU(921979L, 1024, 1024, POISSON = sc_bias_mean)

;; Generate a dark frame
DarkFrame_Base = RANDOMU(979129L, 1024, 1024, POISSON = sc_dark_mean) ; Use fixed seed

;; Just for fun, add some crazy pixels
DarkFrame_DeadPix = Float((randomn(1122008L, 1024, 1024) * 5 + 18) gt 0) ; Use another fixed seed
DarkFrame_HotPix = (Float((randomn(8675309L, 1024, 1024) * 5 + 15) > 25) - 25) * 10. ; Use random seed

;; Generate a synthetic dark frame with proper exposure 
DarkFrame = DarkFrame_Base * sc_exposure * DarkFrame_DeadPix + DarkFrame_HotPix

;; Synthetic Read Noise
ReadFrame = RANDOMU(4271979L, 1024, 1024, NORMAL = sc_read_noise)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate in-camera behavior ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Dark Shot Noise 
Dark_Final = fltarr(1024, 1024)
; TODO: might not want to use Poisson here, could use a different distribution
for x = 0, 1023 do for y = 0, 1023 do Dark_Final[x, y] = (randomn(5212014L, poisson = (darkframe[x, y]) > 1e-8) > 0.) ; use random seed

;; image in electrons 
Image_Elec = sc_phot_sn_image * sc_qe * sc_qy * DarkFrame_DeadPix
Image_Elec_Final = floor(Image_Elec + Dark_Final + ReadFrame) < sc_fw ; TODO: consider adding read noise later
Noise_Final = Dark_Final + ReadFrame ; Useful for getting SNR ; TODO: need to account for shot noise

; TODO: Sanity check that there are still dead pixels (0 value)

;; Signal/Noise 
Image_SigNoise = Image_Elec/noise_final ; An SNR image! Pretty neat! Can then smooth and contour map

Image_DN_Final = floor(Image_Elec_Final / sc_conversion)
; TODO: Sanity check: there should be no counts gt the full well


; TODO: Make an Image_DN_per_sec_Final
