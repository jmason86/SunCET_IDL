;+
; NAME:
;   image_simulator
;
; PURPOSE:
;   Take input images and realistically noise them up according to instrument parameters.
;
; INPUTS:
;   sim_array [dblarr]:      The 2D simulation images to generate noise for and merge, stacked into different wavelengths (if applicable) [x, y, lambda]
;                            Intensity units should be [erg/cm2/s/sr]
;   sim_plate_scale [float]: The plate scale of the input simulation in arcsec -- i.e., how many arcsecs does a single pixel subtend?
;   waves [fltarr]:          Array with wavelengths (in Angstroms) of each individual image in sim_array
; 
; OPTIONAL INPUTS:
;   exposure_time_sec [float]:         Duration of the exposure. Used to convert from intensity (DN, counts, whatever) / time (sec) to total DN, counters, whatever
;                                      Default is 10 [seconds].
;   dark_current [double]:             Not used normally, except to override the hardcoded cold/warm detector associated dark currents. [e-/px/s] units.
;                                      Overrides /WARM_DETECTOR keyword if both are used.
;   missing_line_scale_factor [float]: Set this to a value to use to scale data up to account for weak non-modeled lines
;   mirror_coating [string]:           Which mirror coating to use. Either 'B4C' (Default; shorthand for B4C/Mo/Al), 'SiMo', or 'AlZr'. Case insensitive.
;
; KEYWORD PARAMETERS:
;   NO_SPIKES:   Set to disable application of spikes to data from particle hits (e.g., while in the SAA or during an SEP storm)
;   NO_DEAD_PIX: Set this to disable application of dead pixels in the detector
;   WARM_DETECTOR: Set this to set the detector temperature to +20 ºC rather than the nominal -10 ºC. This increases the dark current from 1 e-/sec/pix to 20.
;   NO_DARK_SUBTRACT: Set this to turn off dark subtraction.
;   MODEL_PSF: Use modeled PSF instead of ray-trace PSF files
;   NO_PSF: Do not simulate the PSF
;
; OUTPUTS:
;   Multiple, which means have to use IDL's bad syntax for this situation using optional outputs
;
; OPTIONAL OUTPUTS:
;   output_pure [float]:         The final image in DN with no added noise (i.e. pure model conversion to DN)
;   output_image_noise [lonarr]: The noise-only component of the image
;   output_image_final [lonarr]: The simulated image with noise included
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   image_simulator, image, exposure_time_sec=1.0, output_SNR=snr, output_image_noise=image_noise, output_image_final=image_final
;-
PRO image_simulator, sim_array, sim_plate_scale, waves, $
                     exposure_time_sec=exposure_time_sec, dark_current=dark_current, missing_line_scale_factor=missing_line_scale_factor, mirror_coating=mirror_coating, $
                     NO_SPIKES=NO_SPIKES, NO_DEAD_PIX=NO_DEAD_PIX, NO_PSF=NO_PSF, WARM_DETECTOR=WARM_DETECTOR, NO_DARK_SUBTRACT=NO_DARK_SUBTRACT, MODEL_PSF=MODEL_PSF, $
                     output_pure=output_pure, output_image_noise=output_image_noise, output_image_final=output_image_final
                     
                     
; Input check and defaults
IF sim_array EQ !NULL THEN BEGIN
  message, /INFO, 'You must supply sim_array as a regular input'
  return
ENDIF
IF exposure_time_sec EQ !NULL THEN BEGIN
  exposure_time_sec = 10.0
ENDIF
IF mirror_coating EQ !NULL THEN BEGIN
  mirror_coating = 'B4C'
ENDIF

; set up environment variable
base_path = getenv('SunCET_base')
reflectivity_path = base_path + 'Mirror_Data/'
psf_path = base_path + 'PSF_Data/'

; Check keywords (upfront for safety)
no_spikes = keyword_set(NO_SPIKES)
no_dead_pix = keyword_set(NO_DEAD_PIX)
model_psf = keyword_set(MODEL_PSF)
no_psf = keyword_set(NO_PSF)
warm_detector = keyword_set(WARM_DETECTOR)
no_dark_subtract = keyword_set(NO_DARK_SUBTRACT)
suvi_mirror = keyword_set(SUVI_MIRROR)

; Constants
h = 6.62606957d-34     ; [Js]
c = 299792458.d        ; [m/s]
j2ev = 6.242d18        ; [ev/J] Conversion from Joules to electron volts
j2erg = 1e7            ; [erg/J] Conversion from Joules to ergs
arcsec2rad = 4.8481e-6 ; [radian/arcsec] Conversion from arcsec to radians
fixed_seed1 = 979129L
fixed_seed2 = 1122008L
one_au_cm = 1.496e13 ; [cm] Earth-Sun Distance in cm
average_rsun_arc = 959.63 ; [arcsec] Average solar radius in arcsecons
rsun_cm = 6.957e10 ; [cm] solar radius in cm 
one_au_sun_sr = 6.7993e-5 ; [sr] angular diameter of sun at 1 AU in steradians

; Simulation parameters
sim_dimensions = size(sim_array, /DIMENSIONS)
num_waves = n_elements(waves)
sim_fov_deg = sim_dimensions[0] * (sim_plate_scale / 3600.) ; [deg] Assumes that the other direction FOV is the same (i.e., square FOV)
sim_cm2_per_pix = (sim_plate_scale/average_rsun_arc * rsun_cm)^2 ; [cm^2] physical area per simulation pixel 
if ~keyword_set(missing_line_scale_factor) then  missing_line_scale_factor = 1.3 ; empirical scale factor to account for contributions from unmodeled minor lines 

;
; Telescope and detector parameters
;
entrance_aperture = 6.5            ; [cm] diameter, AKA entrance pupil diameter
primary_mirror_truncation = 0.0    ; [cm^2] area lost due the primary mirror being so big it has to be truncated from the nominal circle
;secondary_mirror_obscuration = 4.8 ; [cm] diameter, the secondary mirror blocks some of the light coming into the system
;sc_aperture = entrance_aperture*!PI^2. - secondary_mirror_obscuration*!PI^2. - primary_mirror_truncation ; [cm^2] effective aperture
secondary_mirror_obscuration = 0.35 ; [% as a fraction] what percentage of the entrance aperture is blocked by the secondary mirror
sc_aperture = (entrance_aperture*!PI^2 * (1 - secondary_mirror_obscuration)) - primary_mirror_truncation
sc_image_dimensions = [1500, 1500] ; [pixels]
SunCET_fov_deg = 2.                ; [deg] Assumes that the other direction FOV is the same (i.e., square FOV)
sc_reflectivity = 0.223 * 0.223    ; [% but as fraction] two mirrors -- each of those is the average reflectance; TODO: make wavelength dependent
sc_transmission = 0.6 * 0.85       ; [% but as fraction] entrance filter transmission * detector filter; TODO: make wavelength dependent
sc_qe = 0.85                       ; [% but as a fraction] ; TODO: make wavelength dependent (find that goddard plot)
sc_read_noise = 5D                 ; [e-] Read noise
pixel_full_well = 27e3             ; [e-] Actually the peak linear charge. The saturation charge is 33e3.
num_binned_pixels = 4D             ; [#] The number of pixels to bin
sc_readout_bits = 16               ; [bits] Bit depth of readout electronics
;sc_bias_mean = 20D                ; [e-/px] Average bias ; TODO: May not apply to CMOS, need to check -- there's e- shot noise if bias is low
sc_gain = 1.8                      ; [DN/e-] From Alan ; TODO reconcile units vs above with Dan
sc_detector_size = 1.1             ; [cm2]
sc_plate_scale = 4.8               ; [arcsec/pixel]
sc_num_pixels_per_bin = 4          ; number of pixels that go into one spatial resolution element
spike_rate = 2100.0                ; [spikes/s/cm2] based on SWAP analysis of worst case (most times will be ~40 spikes/s/cm2)
                                   ; SPENVIS predicts about 1/3 the particle flux at 550 km vs SWAP's 725 km
psf_80pct_arcsec = 20.             ; [arcsec] PSF 80% encircled energy width, using typical value from Alan's analysis 
IF WARM_DETECTOR THEN BEGIN
  sc_dark_current_mean = 20D       ; [e-/px/s] Average Dark Current
  sc_dark_current_stddev = 12D     ; [e-/px/s] Dark current standard deviation (DSNU in spec sheet)
ENDIF ELSE BEGIN
  sc_dark_current_mean = 1D        ; [e-/px/s] Average Dark Current
  sc_dark_current_stddev = 0.6D    ; [e-/px/s] Dark current standard deviation (DSNU in spec sheet)
ENDELSE
IF dark_current NE !NULL THEN BEGIN
  sc_dark_current_mean = dark_current ; [e-/px/s]
  calculated_temperature = alog2(dark_current/20.) * 5.5 + 20.
  message, /INFO, 'The input dark current of ' + JPMPrintNumber(sc_dark_current_mean) + ' e-/px/s corresponds to a temperature of ' + JPMPrintNumber(calculated_temperature) + ' ºC'
  sc_dark_current_stddev = 12. * 2.^((calculated_temperature - 20.) / 5.5) ; [e-/px/s] Dark current standard deviation (DSNU in spec sheet)
ENDIF

;; load and interpolate mirror reflectivity data
IF strcmp(mirror_coating, 'b4c', /FOLD_CASE) THEN BEGIN
  restore, reflectivity_path + 'b4c_ascii_template.sav'
  b4c = read_ascii(reflectivity_path + 'XRO47864_TH=5.0.txt', template=b4c_template)
  r_wave = b4c.wave * 10. ; [Å] Comes in nm, so convert to Å
  reflect = b4c.reflectance
ENDIF ELSE IF strcmp(mirror_coating, 'alzr', /FOLD_CASE) THEN BEGIN
  restore, reflectivity_path + 'alzr_ascii_template.sav'
  alzr = read_ascii(reflectivity_path + 'AlZr_195A_TH=5.0.txt', template=alzr_template)
  r_wave = alzr.wave ; Å
  reflect = alzr.reflectance
ENDIF ELSE IF strcmp(mirror_coating, 'simo', /FOLD_CASE) THEN BEGIN
  restore, reflectivity_path + 'simo_ascii_template.sav'
  simo = read_ascii(reflectivity_path + 'SiMo_195A_TH=5.0.txt', template=simo_template)
  r_wave = simo.wave ; Å
  reflect = simo.reflectance
ENDIF ELSE BEGIN
  message, /INFO, 'No matching mirror coating supplied. Must be either "B4C", "AlZr", or "SiMo".'
  return
ENDELSE
sc_reflectivity_wvl = interpol(reflect, r_wave, waves) ; [unitless] reflectivities at target wavelengths, r_wave in [Å]

; Telescope/detector calculations
sc_plate_scale_sr = (sc_plate_scale * arcsec2rad)^2.           ; [sr/pixel^2] Even though it should be labeled as /pixel^2 everywhere, convention is to just call this /pixel
sc_fw = pixel_full_well * num_binned_pixels                    ; [e-] full well -- it's 1.08e5  ; Ask Alan if binning allows an actual larger full well
sc_eff_area =  sc_aperture * sc_reflectivity_wvl^2. * sc_transmission ; [cm^2] TODO: can fold in sc_qe here
sc_conversion = sc_fw/(2.^sc_readout_bits)                     ; [e-/DN] Camera readout conversion (kludge); TODO: double check this
sc_spatial_resolution = sc_plate_scale * sc_num_pixels_per_bin ; [arcsec] The spatial resolution of the binned image
sc_qy = (h*c / (waves * 1e-10)) * j2ev / 3.63                  ; [e-/phot] Quantum yield: how many electrons are produced for each absorbed photon, wavelength dependent (171Å = 72.9 ev/3.63; 200Å = 62 ev/3.63)

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
  im_array[*, *, i] = congrid(sim_array_punchout[*, *, i] * (sc_plate_scale/sim_plate_scale)^2., sc_image_dimensions[0], sc_image_dimensions[1], cubic=-0.5) ; [erg/cm2/s/sr] - no change to the units of the actual data here
ENDFOR

; Drop the sr and bring in the /pixel2 instead. This also accounts for scaling to 1 AU. 
im_array *= sc_plate_scale_sr ; [erg/cm2/s/pixel2]

; Apply the PSF
if ~no_psf then begin 
   if model_psf then begin 

    psf_80pct_px = psf_80pct_arcsec/sc_plate_scale ; get 80% encircled in pixels
    psf_sigma = psf_80pct_px/(2 * 1.28155) ; compute sigma required for 80% encircled energy at desired width

    ; compute the PSF -- 99.99% of energy falls within a box 3 times as wide as the 80% level so no need to go wider
    ; PSF is normalized to preserve total energy
    psf = gaussian_function( psf_sigma * [1., 1.], /double, /normalize, width = 3 * psf_80pct_px)

    ; convolve the PSF into the image, protect image edges, keep centered to ensure no image translation
    for i = 0, num_waves - 1 do $
      im_array[*, *, i] = convol(im_array[*, *, i], psf, /edge_zero, /center)
  endif else begin 
    ; read the CSV and convert to something usable
    raw_data = rd_tfile(psf_path + '/SunCet_PSF_0SolarRad_s3.0A_185A_Normalized.csv')
;    raw_data = rd_tfile(psf_path + '/SunCet_PSF_0SolarRad_s6.8A_185A_Normalized.csv')
    data_str = strsplit(raw_data, ',', /extract)
    psf = fltarr(n_elements(data_str[0]), n_elements(data_str))
    for n = 0, n_elements(data_str) - 1 do $
      psf[*, n] = data_str[n]

    ; need to normalize to ensure proper photon accounting
    psf_norm = psf/total(psf)
    psf_norm = psf_norm[2:-3, 2:-3]

    ; padding to avoid edge effects 
    psf_cent = floor(sc_image_dimensions[0]/2)
    psf_pad = dblarr(sc_image_dimensions[0] * 2, sc_image_dimensions[1] * 2)
    psf_pad(0: sc_image_dimensions[0] - 1, sc_image_dimensions[1]: *) = psf_norm
    psf_pad = shift(psf_pad, psf_cent * [-1, 1]) ; shift PSF for correct FFT result
    psf_hat = fft(psf_pad, 1)                    ; compute FFT'ed psf for convolution

    ;;; pad the image and do the convolution
    for i = 0, num_waves - 1 do begin 
      image_pad = dblarr(sc_image_dimensions[0] * 2, sc_image_dimensions[0] * 2)
      image_pad(0: sc_image_dimensions[0] - 1, sc_image_dimensions[1]: *) = im_array[*, *, i]
      image_hat = fft(image_pad, 1)

      image_convol = real_part(fft(image_hat * psf_hat, -1)) ; Deconvolve and apply inverse FFT
      image_convol = image_convol(0: sc_image_dimensions[0] - 1, sc_image_dimensions[1]: *)   ; Remove padding

      im_array[*, *, i] = shift_img(image_convol, [0.5, 0.5]) ; psf isn't quite centered so do a 0.5 px shift to recenter
    endfor 
  endelse 
endif 

; Convert from erg to photons
FOR i = 0, num_waves - 1 DO BEGIN
  im_array[*, *, i] = im_array[*, *, i] / (j2erg * (h*c / (waves[i] * 1e-10))) ; [photons/cm2/s/pixel2]
ENDFOR

;;; 2022-07-22 The below turns out to be wrong. The input units should've been photons/cm2/s/sr, not /pix. 
; Convert simulation into pixels observed at Earth, i.e., scale the flux down according to distance from the source
; sim enters in [photons/cm2/s/pix] and is multiplied by [cm^2 (in simulation) / cm^2 (at earth)]
;im_array = im_array * (sim_cm2_per_pix) / one_au_cm^2 ; [photons/cm2/s/pix]

; 2022-07-22 correct way of doing what is just above -- convert the "flux" to 1 AU
; im_array *= one_au_sun_sr ; [photons/cm2/s]


;
; Start creating images
;

; Apply effective area and exposure time
sc_phot_images = im_array
FOR i = 0, num_waves - 1 DO BEGIN
  sc_phot_images[*, *, i] = im_array[*, *, i] * sc_eff_area[i] * exposure_time_sec ; [photons / (per lambda)]
ENDFOR

; TODO: Add in scattered light psf here, accounting for secondary mirror and spider mounts
; TODO: See what results Alan provides and see if that can be used directly as input

; Note: Photon shot noise isn't wavelength dependent -- so instead we factor it in later as part of electron shot
; Which ultimately creates images whose noise profile behaves as expected
;; simulate photon generation shot noise by randomizing with poisson distribution
;; use a specific random number seed for repeatability
sc_phot_sn_images = sc_phot_images
; FOR x = 0, sc_image_dimensions[0] - 1 DO BEGIN
;   FOR y = 0, sc_image_dimensions[1] - 1 DO BEGIN
;     FOR i = 0, num_waves - 1 DO BEGIN
;       sc_phot_sn_images[x, y, i] = (randomu(seed1, poisson = (sc_phot_images[x, y, i]) > 1e-8, /double) > 0.)
;     ENDFOR
;   ENDFOR
; ENDFOR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate base camera performance ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Generate a bias frame 
;BiasFrame = RANDOMU(921979L, sc_image_dimensions[0], sc_image_dimensions[1], POISSON = sc_bias_mean)

;; Generate a dark frame
darkframe_base = (jpmrandomn(fixed_seed1, d_i=sc_image_dimensions, mean=sc_dark_current_mean, stddev=sc_dark_current_stddev) * exposure_time_sec) > 0 ; Note: stddev defaults to 1

;; Just for fun, add some crazy pixels
darkframe_hotpix = (float((randomn(seed2, sc_image_dimensions[0], sc_image_dimensions[1]) * 5 + 15) > 25) - 25) * 10.
dead_pix = float((randomn(fixed_seed2, sc_image_dimensions[0], sc_image_dimensions[1]) * 5 + 18) gt 0)

;; Generate a synthetic dark frame with proper exposure 
darkframe = (darkframe_base * dead_pix) + darkframe_hotpix

;; Synthetic Read Noise
readframe = jpmrandomn(seed3, d_i=sc_image_dimensions, mean=0, stddev=sc_read_noise)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; simulate in-camera behavior ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Dark Shot Noise
dark_final = fltarr(sc_image_dimensions[0], sc_image_dimensions[1])
FOR x = 0, sc_image_dimensions[0] - 1 DO FOR y = 0, sc_image_dimensions[1] - 1 DO dark_final[x, y] = (randomu(seed4, poisson = (darkframe[x, y]) > 1e-8, /DOUBLE) > 0.)

;
; Handle wavelength dependences
;

; images in electrons
image_elec = sc_phot_sn_images
image_pure_elec = sc_phot_images
FOR i = 0, num_waves - 1 DO BEGIN
  image_elec[*, *, i] = sc_phot_sn_images[*, *, i] * sc_qe * sc_qy[i] 
  image_pure_elec[*, *, i] = sc_phot_images[*, *, i] * sc_qe * sc_qy[i] 
ENDFOR

; Merge the separate emission line images according to the SunCET bandpass responsivity
image_elec_bandpass_merged = total(image_elec, 3) ; TODO: need to apply weighting when summing
image_pure_elec_merged = total(image_pure_elec, 3) ; TODO: as above 

; Adjust for minor lines not modeled
image_elec_bandpass_merged = image_elec_bandpass_merged * missing_line_scale_factor
image_pure_elec_merged = image_pure_elec_merged * missing_line_scale_factor

; Add electron shot noise
image_elec_shot_noise_bandpass_merged = image_elec_bandpass_merged
FOR x = 0, sc_image_dimensions[0] - 1 DO BEGIN
  FOR y = 0, sc_image_dimensions[1] - 1 DO BEGIN
    image_elec_shot_noise_bandpass_merged[x, y] = (randomu(seed5, poisson=(image_elec_bandpass_merged[x, y]) > 1e-8, /DOUBLE) > 0.)
  ENDFOR
ENDFOR

; Combine signal electrons with noise electrons
signal_with_noise_elec = image_elec_shot_noise_bandpass_merged + dark_final + readframe
noise_final = (dark_final - darkframe_base) + readframe ; Realistic to subtract out the typical dark frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate Spikes Frame ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

nspikes = sc_detector_size * spike_rate * exposure_time_sec

;; make an array of random numbers
random_array = randomu(seed6, sc_image_dimensions[0], sc_image_dimensions[1])

;; get the index of the [nspikes] lowest valued pixels 
spike_list = sort(random_array)
spike_list = spike_list[0: nspikes - 1]

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Make the final image ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

image_dn_final = round(signal_with_noise_elec * sc_gain, /L64) < sc_fw ; TODO: Decide whether to do a > 0 as well, are negative DN allowed?
image_pure_dn_final = image_pure_elec_merged * sc_gain

;; Signal/Noise
; image_signoise = signal_with_noise_elec/noise_final ; An SNR image! Pretty neat! Can then smooth and contour map

;; Add spikes to the image
IF NOT no_spikes THEN BEGIN
	image_dn_final[spike_list] = sc_fw
ENDIF

; Apply dead pixels (these can't be stimulated by anything)
IF NOT no_dead_pix THEN BEGIN
  image_dn_final *= dead_pix
ENDIF

; Handle dark subtraction
IF NOT no_dark_subtract THEN BEGIN
  image_dn_final -= (darkframe_base * sc_gain)
ENDIF

; Sanity check: there should be no counts gt the full well
IF max(image_dn_final) GT sc_fw THEN BEGIN
  message, /INFO, 'Warning: Max value in image (' + JPMPrintNumber(max(image_dn_final)) + ' DN) exceeds full well (' + JPMPrintNumber(sc_fw) + ' DN)' 
ENDIF

; Outputs
output_pure = image_pure_dn_final 
output_image_noise = noise_final + (image_pure_elec_merged - image_elec_shot_noise_bandpass_merged)
output_image_final = image_dn_final

END
