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
resp_peak = where(max(resp.a193.ea) eq resp.a193.ea)
resp_dn_to_phot_ea = resp.a193.ea[resp_peak[0]]

;; image has units dn/s
;; response is cm^2 DN phot^-1 px^-1
phot_flux_image = image/resp_dn_to_phot_ea

;; boost to make the input image a little more viable
;; need to remove this and do the conversion to photons properly!!
phot_flux_image = phot_flux_image * 1000.


;; phot flux image has units of photon cm^-2 s^-1 px^-1
;; SunCET aperture is 44.9 cm^2
;; Assume a 10-s effective exposure
sc_aperture = 44.9 ; cm^2
sc_reflectivity = 0.25 * 0.25 ; two mirrors
sc_transmission = 0.5 * 0.5 ; filter transmission 
sc_qe = 0.5 ; possibly also need to include quantum yield later on, but I have ignored this here 

sc_eff_area =  sc_aperture * sc_reflectivity * sc_transmission ; cm^2
sc_exposure = 10.

;; sc photon image will have units of phot^-1 px^-1
sc_phot_image = phot_flux_image * sc_eff_area * sc_exposure

;; simulate shot noise by randomizing with poisson distribution
;; use a specific random number seed for repeatability
sc_phot_sn_image = fltarr(1024, 1024)
for x = 0, 1023 do for y = 0, 1023 do sc_phot_sn_image[x, y] = (RANDOMU(10272011L, poisson = (sc_phot_image[x, y]) > 1e-8, /double) > 0.)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate base camera performance ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Average Dark Current
sc_dark_mean = 20D ; 20 e-/px/s

;; Average Bias
sc_bias_mean = 20D ; e-/px 

;; Read Noise
sc_read_noise = 60D ; e- 

;; Camera Gain
sc_gain = 10 ; phot/e- (totally imaginary gain number)

;; Camera Full Well
sc_fw = 100D3 ; e- in full well (totally imaginary)

;; Camera Readout Bits
sc_readout_bits = 12  ; (totally imaginary)

;; Camera Readout Conversion 
;; This is a bit of a kludge here 
;; I'm sure there's a smarter way to do this if you fully 
;; understand the camera performance and readout characteristics 
sc_conversion = sc_fw/2.^sc_readout_bits ; e-/DN 

;; Generate a bias frame 
BiasFrame = RANDOMU(921979L, 1024, 1024, POISSON = sc_bias_mean)

;; Generate a dark frame
DarkFrame_Base = RANDOMU(979129L, 1024, 1024, POISSON = sc_dark_mean)

;; Just for fun, add some crazy pixels
DarkFrame_DeadPix = Float((randomn(1122008L, 1024, 1024) * 5 + 18) gt 0)
DarkFrame_HotPix = (Float((randomn(8675309L, 1024, 1024) * 5 + 15) > 25) - 25) * 10.

;; Generate a synthetic dark frame with proper exposure 
DarkFrame = DarkFrame_Base * sc_exposure * DarkFrame_DeadPix + DarkFrame_HotPix

;; Synthetic Read Noise
ReadFrame = RANDOMU(4271979L, 1024, 1024, NORMAL = sc_read_noise)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate in-camera behavior ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Dark Shot Noise 
Dark_Final = fltarr(1024, 1024)
for x = 0, 1023 do for y = 0, 1023 do Dark_Final[x, y] = (randomn(5212014L, poisson = (darkframe[x, y]) > 1e-8) > 0.)

;; image in electrons 
Image_Elec = sc_phot_sn_image * sc_qe/sc_gain * DarkFrame_DeadPix
Image_Elec_Final = floor(Image_Elec + Dark_Final + BiasFrame + ReadFrame) < sc_fw
Noise_Final = Dark_Final + BiasFrame + ReadFrame

;; Signal/Noise 
Image_SigNoise = Image_Elec/noise_final

Image_DN_Final = floor(Image_Elec_Final / sc_conversion)
