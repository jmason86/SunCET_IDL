;+
; NAME:
;   image_simulator
;
; PURPOSE:
;   Take input images and realistically noise them up according to instrument parameters.
;
; INPUTS:
;   sim_array [dblarr]:      The 2D simulation images to generate noise for and merge, stacked into different wavelengths (if applicable) [x, y, lambda]
;                            Intensity units should be [erg/cm2/s/pix], where pix is simulation pixel
;   sim_plate_scale [float]: The plate scale of the input simulation in arcsec -- i.e., how many arcsecs does a single pixel subtend?
;
; OPTIONAL INPUTS:
;   exposure_time_sec [float]: Duration of the exposure. Used to convert from intensity (DN, counts, whatever) / time (sec) to total DN, counters, whatever
;                              Default is 10 [seconds].
;
; KEYWORD PARAMETERS:
;   NO_SPIKES:   Set to disable application of spikes to data from particle hits (e.g., while in the SAA or during an SEP storm)
;   NO_DEAD_PIX: Set this to disable application of dead pixels in the detector
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
PRO image_simulator, sim_array, sim_plate_scale, $
                     exposure_time_sec=exposure_time_sec, $
                     NO_SPIKES=NO_SPIKES, NO_DEAD_PIX=NO_DEAD_PIX, $
                     output_SNR=output_SNR, output_image_noise=output_image_noise, output_image_final=output_image_final
                     
; Input check and defaults
IF sim_array EQ !NULL THEN BEGIN
  message, /INFO, 'You must supply sim_array as a regular input'
  return
ENDIF
IF exposure_time_sec EQ !NULL THEN BEGIN
  exposure_time_sec = 10.0
ENDIF

; Check keywords (upfront for safety)
no_spikes = keyword_set(no_spikes)
no_dead_pix = keyword_set(no_dead_pix)

; Constants
h = 6.62606957d-34 ; [Js]
c = 299792458.d    ; [m/s]
; c *= 1e6 ; FIXME: Hack to scale the total intensity to avoid saturation or dim signal
fixed_seed1 = 979129L
fixed_seed2 = 1122008L

; Simulation parameters
sim_dimensions = size(sim_array, /DIMENSIONS)
num_waves = sim_dimensions[2]
sim_fov_deg = sim_dimensions[0] * (sim_plate_scale / 3600.) ; [deg] Assumes that the other direction FOV is the same (i.e., square FOV)
waves = [171, 177, 180, 195, 202]*1e-10 ; [m]

;
; Telescope and detector parameters
;
sc_aperture = 44.9                 ; [cm^2]
sc_image_dimensions = [1500, 1500] ; [pixels]
SunCET_fov_deg = 2.                ; [deg] Assumes that the other direction FOV is the same (i.e., square FOV)
sc_reflectivity = 0.223 * 0.223    ; [% but as fraction] two mirrors -- each of those is the average reflectance; TODO: make wavelength dependent
sc_transmission = 0.6 * 0.85       ; [% but as fraction] entrance filter transmission * detector filter; TODO: make wavelength dependent
sc_qe = 0.85                       ; [% but as a fraction] ; TODO: make wavelength dependent (find that goddard plot)
sc_qy = 18.46                      ; [e-/phot] This is average and could have it's own shot noise and wavelength dependence -- (171Å = 72.9 ev/3.63; 200Å = 62 ev/3.63); TODO: make wavelength dependent
sc_dark_mean = 1D                  ; [e-/px/s] Average Dark Current
sc_read_noise = 5D                 ; [e-] Read noise
pixel_full_well = 27e3             ; [e-] Actually the peak linear charge. The saturation charge is 33e3.
num_binned_pixels = 4D             ; [#] The number of pixels to bin
sc_readout_bits = 16               ; [bits] Bit depth of readout electronics
;sc_bias_mean = 20D                ; [e-/px] Average bias ; TODO: May not apply to CMOS, need to check -- there's e- shot noise if bias is low
sc_gain = 1.8                      ; [DN/e-] From Alan ; TODO reconcile units vs above with Dan
sc_detector_size = 1.47            ; [cm2]
sc_plate_scale = 4.8               ; [arcsec/pixel]
sc_num_pixels_per_bin = 4          ; number of pixels that go into one spatial resolution element
spike_rate = 2100.0                ; [spikes/s/cm2] based on SWAP analysis of worst case (most times will be ~40 spikes/s/cm2)

; Telescope/detector calculations
sc_fw = pixel_full_well * num_binned_pixels                    ; [e-] full well -- it's 1.08e5  ; Ask Alan if binning allows an actual larger full well
sc_eff_area =  sc_aperture * sc_reflectivity * sc_transmission ; [cm^2] TODO: can fold in sc_qe here
sc_conversion = sc_fw/(2.^sc_readout_bits)                     ; [e-/DN] Camera readout conversion (kludge); TODO: double check this
sc_spatial_resolution = sc_plate_scale * sc_num_pixels_per_bin ; [arcsec] The spatial resolution of the binned image

; Extract the instrument FOV from the simulation FOV (i.e., punch a square hole)
sim_x_deg = jpmrange(-sim_fov_deg, sim_fov_deg, NPTS=sim_dimensions[0])
fov_indices = where(sim_x_deg GE -SunCET_fov_deg AND sim_x_deg LE SunCET_fov_deg, num_punchout_pixels)
sim_array_punchout = dblarr(num_punchout_pixels, num_punchout_pixels, n_elements(sim_array[0, 0, *]))
FOR i = 0, num_waves - 1 DO BEGIN
  sim_array_punchout[*, *, i] = sim_array[fov_indices[0]:fov_indices[-1], fov_indices[0]:fov_indices[-1], i]
ENDFOR

; Rescale image from simulation resolution to instrument resolution (the plate scales... how many degress does a single pixel subtend?)
im_array = dblarr(sc_image_dimensions[0], sc_image_dimensions[1], n_elements(sim_array[0, 0, *]))
FOR i = 0, num_waves - 1 DO BEGIN
  im_array[*, *, i] = congrid(sim_array_punchout[*, *, i] * (sc_plate_scale/sim_plate_scale)^2., sc_image_dimensions[0], sc_image_dimensions[1], cubic=-0.5) ; [erg/cm2/s/pix] -- SunCET pixel now
ENDFOR

; Convert from erg to photons
FOR i = 0, num_waves - 1 DO BEGIN
  im_array[*, *, i] = im_array[*, *, i] / (h*c/waves[i]) ; [photons/cm2/s/pix]
ENDFOR

;
; Start creating images
;

; Apply effective area and exposure time
sc_phot_images = im_array
FOR i = 0, num_waves - 1 DO BEGIN
  sc_phot_images[*, *, i] = im_array[*, *, i] * sc_eff_area * exposure_time_sec ; [photons / pixel (per lambda)]
ENDFOR

; TODO: Add in scattered light psf here, accounting for secondary mirror and spider mounts
; TODO: See what results Alan provides and see if that can be used directly as input

;; simulate photon generation shot noise by randomizing with poisson distribution
;; use a specific random number seed for repeatability
sc_phot_sn_images = sc_phot_images
FOR x = 0, sc_image_dimensions[0] - 1 DO BEGIN
  FOR y = 0, sc_image_dimensions[1] - 1 DO BEGIN
    FOR i = 0, num_waves - 1 DO BEGIN
      sc_phot_sn_images[x, y, i] = (randomu(seed, poisson = (sc_phot_images[x, y, i]) > 1e-8, /double) > 0.)  ; TODO: Why does this always return round numbers? If our poisson mean happened to be < 1, we'd always get 0 returned
    ENDFOR
  ENDFOR
ENDFOR

; Merge the separate emission line images according to the SunCET bandpass responsivity
sc_phot_sn_image_bandpass_merged = total(sc_phot_sn_images, 3) ; TODO: need to apply weighting when summing

; TODO: sc_qy has to go into the algorithm after this point once we have done photon shot noise


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate base camera performance ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Generate a bias frame 
;BiasFrame = RANDOMU(921979L, sc_image_dimensions[0], sc_image_dimensions[1], POISSON = sc_bias_mean)

;; Generate a dark frame
darkframe_base = randomu(fixed_seed1, sc_image_dimensions[0], sc_image_dimensions[1], NORMAL = (sc_dark_mean * exposure_time_sec))

;; Just for fun, add some crazy pixels
darkframe_hotpix = (float((randomn(seed, sc_image_dimensions[0], sc_image_dimensions[1]) * 5 + 15) > 25) - 25) * 10.
dead_pix = float((randomn(fixed_seed2, sc_image_dimensions[0], sc_image_dimensions[1]) * 5 + 18) gt 0)

;; Generate a synthetic dark frame with proper exposure 
darkframe = (darkframe_base * dead_pix) + darkframe_hotpix

;; Synthetic Read Noise
readframe = randomu(seed, sc_image_dimensions[0], sc_image_dimensions[1], normal = sc_read_noise) ; TODO: Results in some negative numbers... is that okay?

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate in-camera behavior ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Dark Shot Noise
dark_final = fltarr(sc_image_dimensions[0], sc_image_dimensions[1])
FOR x = 0, sc_image_dimensions[0] - 1 DO FOR y = 0, sc_image_dimensions[1] - 1 DO dark_final[x, y] = (randomu(seed, poisson = (darkframe[x, y]) > 1e-8) > 0.)

;; images in electrons 
image_elec = sc_phot_sn_image_bandpass_merged * sc_qe * sc_qy
image_elec_shot_noise = image_elec
FOR x = 0, sc_image_dimensions[0] - 1 DO FOR y = 0, sc_image_dimensions[1] - 1 DO image_elec_shot_noise[x, y] = (randomu(seed, poisson = (image_elec[x, y]) > 1e-8, /double) > 0.)
image_elec = image_elec_shot_noise + dark_final + readframe
noise_final = dark_final + readframe


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate Spikes Frame ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

nspikes = sc_detector_size * spike_rate * exposure_time_sec

;; make an array of random numbers
random_array = randomu(seed, sc_image_dimensions[0], sc_image_dimensions[1])

;; get the index of the [nspikes] lowest valued pixels 
spike_list = sort(random_array)
spike_list = spike_list[0: nspikes - 1] ; TODO: This is a single number rather than a list

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Make the final image ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Signal/Noise
image_signoise = image_elec/noise_final ; An SNR image! Pretty neat! Can then smooth and contour map

image_dn_final = floor(image_elec * sc_gain, /L64) < sc_fw  

;; Add spikes to the image
IF NOT no_spikes THEN BEGIN
	image_dn_final[spike_list] = sc_fw
ENDIF

; Apply dead pixels (these can't be stimulated by anything)
IF NOT no_dead_pix THEN BEGIN
  image_dn_final *= dead_pix
ENDIF


; TODO: Sanity check: there should be no counts gt the full well


; TODO: Make an Image_DN_per_sec_Final


; Outputs
output_snr = image_signoise
output_image_noise = noise_final
output_image_final = image_dn_final

END
