;+
; NAME:
;   image_simulator
;
; PURPOSE:
;   Take input images and realistically noise them up according to instrument parameters.
;
; INPUTS:
;   im_array [dblarr]: The 2D image to generate noise for, stacked into different wavelengths (if applicable) [x, y, lambda]
;
; OPTIONAL INPUTS:
;   exposure_time_sec [float]: Duration of the exposure. Used to convert from intensity (DN, counts, whatever) / time (sec) to total DN, counters, whatever
;                              Default is 10 [seconds].
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Multiple, which means have to use IDL's bad syntax for this situation using optional outputs
;
; OPTIONAL OUTPUTS:
;   output_SNR [float]:          The signal to noise ratio
;   output_image_noise [lonarr]: The noise image alone
;   output_image_final [lonarr]: The image with noise included
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   image_simulator, image, exposure_time_sec=1.0, output_SNR=snr, output_image_noise=image_noise, output_image_final=image_final
;-

PRO image_simulator, im_array, $
                     exposure_time_sec=exposure_time_sec, $
                     output_SNR=output_SNR, output_image_noise=output_image_noise, output_image_final=output_image_final
                     no_spikes = no_spikes

; Input check and defaults
IF im_array EQ !NULL THEN BEGIN
  message, /INFO, 'You must supply im_array as a regular input'
  return
ENDIF
IF exposure_time_sec EQ !NULL THEN BEGIN
  exposure_time_sec = 10.0
ENDIF

no_spikes = keyword_set(no_spikes)

fixed_seed1 = 979129L
fixed_seed2 = 1122008L

; Grab image dimensions for use throughout code
image_size = size(im_array, /DIMENSIONS)

;
; Telescope and detector parameters
;
sc_aperture = 44.9              ; [cm^2]
sc_reflectivity = 0.223 * 0.223 ; [% but as fraction] two mirrors -- each of those is the average reflectance; TODO: make wavelength dependent
sc_transmission = 0.6 * 0.85    ; [% but as fraction] entrance filter transmission * detector filter; TODO: make wavelength dependent
sc_qe = 0.85                    ; [% but as a fraction] ; TODO: make wavelength dependent (find that goddard plot)
sc_qy = 18.46                   ; [e-/phot] This is average and could have it's own shot noise and wavelength dependence -- (171Å = 72.9 ev/3.63; 200Å = 62 ev/3.63); TODO: make wavelength dependent
sc_dark_mean = 1D               ; [e-/px/s] Average Dark Current
sc_read_noise = 5D              ; [e-] Read noise
pixel_full_well = 27e3          ; [e-] Actually the peak linear charge. The saturation charge is 33e3.
num_binned_pixels = 4D          ; [#] The number of pixels to bin
sc_readout_bits = 16            ; [bits] Bit depth of readout electronics
;sc_bias_mean = 20D             ; [e-/px] Average bias ; TODO: May not apply to CMOS, need to check -- there's e- shot noise if bias is low
sc_gain = 1.8                   ; [DN/e-] From Alan ; TODO reconcile units vs above with Dan
sc_detector_size = 1.47         ; [cm2]
spike_rate = 21.0               ; [spikes/s/cm2] based on SWAP analysis of worst case (most times will be ~40 spikes/s/cm2)

; Telescope/detector calculations
sc_fw = pixel_full_well * num_binned_pixels                    ; [e-] full well -- it's 1.08e5  ; Ask Alan if binning allows an actual larger full well
sc_eff_area =  sc_aperture * sc_reflectivity * sc_transmission ; [cm^2] TODO: can fold in sc_qe here
sc_conversion = sc_fw/(2.^sc_readout_bits)                     ; [e-/DN] Camera readout conversion (kludge); TODO: double check this

;
; Start creating images
;

; Apply effective area and exposure time
sc_phot_images = im_array
FOR i = 0, image_size[2] - 1 DO BEGIN
  sc_phot_images[*, *, i] = im_array[*, *, i] * sc_eff_area * exposure_time_sec ; [photons / pixel (per lambda)]
ENDFOR

; TODO: Consider adding in scattered light psf here, accounting for secondary mirror and spider mounts
; TODO: See what results Alan provides and see if that can be used directly as input

;; simulate photon generation shot noise by randomizing with poisson distribution
;; use a specific random number seed for repeatability
sc_phot_sn_image = fltarr(image_size[0], image_size[1])
for x = 0, image_size[0] - 1 do for y = 0, image_size[1] - 1 do sc_phot_sn_image[x, y] = (RANDOMU(seed, poisson = (sc_phot_image[x, y]) > 1e-8, /double) > 0.)
; TODO: sanity check on the Poisson here
; TODO: sanity check by looking at before and after images


; TODO: sc_qy has to go into the algorithm after this point once we have done photon shot noise


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate base camera performance ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Generate a bias frame 
;BiasFrame = RANDOMU(921979L, image_size[0], image_size[1], POISSON = sc_bias_mean)

;; Generate a dark frame
DarkFrame_Base = RANDOMU(fixed_seed1, image_size[0], image_size[1], NORMAL = (sc_dark_mean * exposure_time_sec))

;; Just for fun, add some crazy pixels
DarkFrame_DeadPix = Float((randomn(fixed_seed2, image_size[0], image_size[1]) * 5 + 18) gt 0)
DarkFrame_HotPix = (Float((randomn(seed, image_size[0], image_size[1]) * 5 + 15) > 25) - 25) * 10.

;; Generate a synthetic dark frame with proper exposure 
;DarkFrame = DarkFrame_Base * DarkFrame_DeadPix + DarkFrame_HotPix ; Removing dead pixels for now
DarkFrame = DarkFrame_Base + DarkFrame_HotPix

;; Synthetic Read Noise
ReadFrame = RANDOMU(seed, image_size[0], image_size[1], NORMAL = sc_read_noise)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate in-camera behavior ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Dark Shot Noise
Dark_Final = fltarr(image_size[0], image_size[1])
; TODO: might not want to use Poisson here, could use a different distribution
for x = 0, image_size[0] - 1 do for y = 0, image_size[1] - 1 do Dark_Final[x, y] = (randomn(seed, poisson = (darkframe[x, y]) > 1e-8) > 0.)

;; image in electrons 
Image_Elec = sc_phot_sn_image * sc_qe * sc_qy; * DarkFrame_DeadPix
Image_Elec_Shot_Noise = Image_Elec
for x = 0, image_size[0] - 1 do for y = 0, image_size[1] - 1 do Image_Elec_Shot_Noise[x, y] = (randomn(seed, poisson = (Image_Elec[x, y]) > 1e-8, /DOUBLE) > 0.)
Image_Elec_Final = floor(Image_Elec + Dark_Final + ReadFrame) ; TODO: consider adding read noise later
Noise_Final = Dark_Final + ReadFrame ; Useful for getting SNR


;;;;;l;;;;;;;;;;;;;;;;;;;;;
;; Generate Spikes Frame ;;
;;;;;l;;;;;;;;;;;;;;;;;;;;;

nspikes = sc_detector_size * spike_rate * exposure_time_sec

;; make an array of random numbers
random_array = randomu(seed, image_size[0], image_size[1])

;; get the index of the [nspikes] lowest valued pixels 
spike_list = sort(random_array)
spike_list = spike_list[0: nspikes - 1]

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Make the final image ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Signal/Noise
Image_SigNoise = Image_Elec/noise_final ; An SNR image! Pretty neat! Can then smooth and contour map

Image_DN_Final = floor(Image_Elec_Final * sc_gain) < sc_fw  

;; Add spikes to the image
if ~no_spikes then $
	Image_DN_Final[spike_list] = sc_fw


; TODO: Sanity check: there should be no counts gt the full well


; TODO: Make an Image_DN_per_sec_Final


; Outputs
output_SNR = Image_SigNoise
output_image_noise = Noise_Final
output_image_final = Image_DN_Final

END
