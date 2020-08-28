;+
; NAME:
;   image_simulator
;
; PURPOSE:
;   Take input images and realistically noise them up according to instrument parameters.
;
; INPUTS:
;   input_image [fltarr]: The 2D image to generate noise for
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

PRO image_simulator, input_image, $
                     exposure_time_sec=exposure_time_sec, $
                     output_SNR=output_SNR, output_image_noise=output_image_noise, output_image_final=output_image_final

; Input check and defaults
IF input_image EQ !NULL THEN BEGIN
  message, /INFO, 'You must supply input_image as a regular input'
  return
ENDIF
IF exposure_time_sec EQ !NULL THEN BEGIN
  exposure_time_sec = 10.0
ENDIF

; Grab image dimensions for use throughout code
image_size = size(input_image, /DIMENSIONS)

;
; Telescope and detector parameters
;
sc_aperture = 44.9              ; [cm^2]
sc_reflectivity = 0.223 * 0.223 ; [% but as fraction] two mirrors -- each of those is the average reflectance
sc_transmission = 0.6 * 0.85    ; [% but as fraction] entrance filter transmission * detector filter
sc_qe = 0.85                    ; [% but as a fraction]
sc_qy = 18.46                   ; [e-/phot] This is average and could have it's own shot noise and wavelength dependence -- (171Å = 72.9 ev/3.63; 200Å = 62 ev/3.63
sc_dark_mean = 1D               ; [e-/px/s] Average Dark Current
sc_read_noise = 5D              ; [e-] Read noise
pixel_full_well = 27e3          ; [e-] Actually the peak lienar charge. The saturation charge is 33e3.
num_binned_pixels = 4D          ; [#] The number of pixels to bin
sc_readout_bits = 16            ; [bits] Bit depth of readout electronics
;sc_bias_mean = 20D             ; [e-/px] Average bias ; TODO: May not apply to CMOS, need to check -- there's e- shot noise if bias is low
;sc_gain = 10                   ; [phot/e-] ; (totally imaginary gain number)
sc_gain = 1.8                   ; [DN/e-] From Alan ; TODO reconcile units vs above with Dan

; Telescope/detector calculations
sc_fw = pixel_full_well * num_binned_pixels                    ; [e-] full well -- it's 1.08e5
sc_eff_area =  sc_aperture * sc_reflectivity * sc_transmission ; [cm^2] TODO: can fold in sc_qe here
sc_conversion = sc_fw/(2.^sc_readout_bits)                     ; [e-/DN] Camera readout conversion (kludge); TODO: double check this

;
; Start creating images
;
sc_phot_image = input_image * sc_eff_area * exposure_time_sec  ; [phot px^-1] 

; TODO: Consider adding in scattered light psf here, accounting for secondary mirror and spider mounts
; TODO: See what results Alan provides and see if that can be used directly as input

;; simulate photon generation shot noise by randomizing with poisson distribution
;; use a specific random number seed for repeatability
sc_phot_sn_image = fltarr(image_size[0], image_size[1])
for x = 0, 1023 do for y = 0, 1023 do sc_phot_sn_image[x, y] = (RANDOMU(10272011L, poisson = (sc_phot_image[x, y]) > 1e-8, /double) > 0.)
; TODO: sanity check on the Poisson here
; TODO: sanity check by looking at before and after images


; TODO: sc_qy has to go into the algorithm after this point once we have done photon shot noise


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate base camera performance ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Generate a bias frame 
;BiasFrame = RANDOMU(921979L, image_size[0], image_size[1], POISSON = sc_bias_mean)

;; Generate a dark frame
DarkFrame_Base = RANDOMU(979129L, image_size[0], image_size[1], POISSON = (sc_dark_mean * exposure_time_sec)) ; Use fixed seed

;; Just for fun, add some crazy pixels
DarkFrame_DeadPix = Float((randomn(1122008L, image_size[0], image_size[1]) * 5 + 18) gt 0) ; Use another fixed seed
DarkFrame_HotPix = (Float((randomn(8675309L, image_size[0], image_size[1]) * 5 + 15) > 25) - 25) * 10. ; Use random seed

;; Generate a synthetic dark frame with proper exposure 
DarkFrame = DarkFrame_Base * DarkFrame_DeadPix + DarkFrame_HotPix

;; Synthetic Read Noise
ReadFrame = RANDOMU(4271979L, image_size[0], image_size[1], NORMAL = sc_read_noise)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate in-camera behavior ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Dark Shot Noise 
Dark_Final = fltarr(image_size[0], image_size[1])
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


; Outputs
output_SNR = Image_SigNoise
output_image_noise = Noise_Final
output_image_final = Image_DN_Final

END
