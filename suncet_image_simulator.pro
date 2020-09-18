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

;  What’s included in these images:
;    Randomly saturated pixels (spikes)
;    Random dark frame (Gaussian distribution)
;    Shot noise on the dark frame (Poisson distribution)
;    Random read noise (Gaussian distribution)
;    Photon shot noise (Poisson distribution)
;    171 + 193 Å AIA bandpasses (SunCET bandpass coming this week)
;    SunCET aperture size
;    Two mirror coating bounces with mean reflectivity
;    Transmission through entrance AND detector filters
;    Detector quantum efficiency, yield, mean dark, read noise, full well, readout # bits, gain
;    SHDR compositing (but NOT yet median stack)
;  
;  Not yet included but planned (not order of operations, this is priority and order of implementation)
;  TODO:
;    Get it working with Meng's SunCET optimized MHD simulation
;      SunCET bandpass -- telecon with Meng
;      Pixel scale -- telecon with Meng
;      
;    Make quantum yield wavelength dependent (James)
;    Image stack median (James)
;     Jitter from exposure to exposure (James)
;    Image 2x2 binning (James)
;    Spikes based on actuals from PROBA2/SWAP (or whatever.. just need streaks: 2100 spikes/second/cm2) (Dan)
;    Blooming around saturated pixels (do last pending lab blooming analysis) (James)
;    Jitter within a single exposure time (Dan) + PSF placeholder until we get input from Alan Hoskins (Dan)
;    
;    Electron shot noise (Poisson distribution?) (Dan)
;    
;    Shadows from focal plane filter mesh (effect should be removable in post) (Dan)
;    Scattered light (Dan)
;    
;    Dead pixels (based on knowledge of our detector)
;    Loop over time to create movie (James)
;    Diffraction from entrance filter mesh (Not going to do)


; Question to address: optimization of time -- SNR pushes longer exposure, noise (read and jitter) pushes shorter exposures


PRO SunCET_image_simulator, HIGHLIGHT_SUB_IMAGES=HIGHLIGHT_SUB_IMAGES
kill
; Defaults
IF keyword_set(HIGHLIGHT_SUB_IMAGES) THEN BEGIN
  sub1 = 'RED TEMPERATURE'
  sub2 = 'CB-Oranges'
  sub3 = 'BLUE/WHITE'
ENDIF ELSE BEGIN
  sub1 = 'B-W LINEAR'
  sub2 = sub1
  sub3 = sub1
ENDELSE

; Constants
h = 6.62606957d-34 ; [Js]
c = 299792458.d    ; [m/s]
aia_plate_scale = 0.6 ; [arcsec/pixel]
SunCET_plate_scale = 4.8 ; [arcsec/pixel]
SunCET_pixel_bin = 4 ; number of pixels that go into one spatial resolution element
SunCET_spatial_resolution = SunCET_plate_scale * SunCET_pixel_bin
exposure_short = 0.025 ; [sec]
exposure_long = 3.0 ; [sec]
SunCET_image_size = [1500, 1500]

;restore, '/Users/jmason86/Dropbox/Research/Data/AIA/aia_response.sav'
;restore, '/Users/jmason86/Dropbox/Research/Data/MHD/For SunCET Phase A/aia_sim/aia_sim_049.sav'
restore, '/Users/jmason86/Dropbox/Research/Data/MHD/For SunCET Phase A/euv_sim/euv_sim_200.sav'

; Pull out the simulation plate scale and wavelengths
sim_plate_scale = euv171_image.dx
waves = [171, 177, 180, 195, 202]*1e-10 ; [m]

sim_array = [[[euv171_image.data]], $
             [[euv177_image.data]], $
             [[euv180_image.data]], $
             [[euv195_image.data]], $
             [[euv202_image.data]]]

; Convert from /sr to to image simulation /pixels
; Convert this to an array (each 
sim_array = sim_array * (sim_plate_scale / 3600. * !PI/180.) * (sim_plate_scale / 3600. * !PI/180.) ; [erg/cm2/s/pix] -- simulation pixel

; Pass into image_simulator here (need also to pass in sim_plate_scale)

; Loop over im array to congrid each one separately
im_array = dblarr(SunCET_image_size[0], SunCET_image_size[1], n_elements(sim_array[0, 0, *]))
FOR i = 0, n_elements(sim_array[0, 0, *]) - 1 DO BEGIN
  im_array[*, *, i] = congrid(sim_array[*, *, i] * (SunCET_plate_scale/sim_plate_scale)^2., SunCET_image_size[0], SunCET_image_size[1], cubic=-0.5) ; [erg/cm2/s/pix] -- SunCET pixel now
ENDFOR

; Merge model images
; im = aia93_image.data ; [DN/s]
FOR i = 0, n_elements(im_array[0, 0, *]) - 1 DO BEGIN
  im_array[*, *, i] = im_array[*, *, i] * (h*c/waves[i]) ; [photons/cm2/s/pix]
ENDFOR

; Pass to image simulator
; Fold in all optical effects (wavelength dependent)
; Then shot noise
; Then quantum yield (which is also wavelength dependent)
; Then merge the 5 (total)
; Then noise again with all other effects

; get the conversion to photons at the response peak
; dumb assumption that all counts originate here
; we can do this much smarter, used for illustrative purposes
;resp_peak1 = where(max(resp.a193.ea) eq resp.a193.ea) ; maybe want to use the mean instead of the max across a reasonable range of the response (e.g., FWHM)
;resp_peak2 = where(max(resp.a171.ea) eq resp.a171.ea)
;resp_dn_to_phot_ea1 = resp.a193.ea[resp_peak1[0]]
;resp_dn_to_phot_ea2 = resp.a171.ea[resp_peak2[0]]

;phot_flux_image = im/resp_dn_to_phot_ea1 ; aia*_image.data has units dn/s, AIA response is cm^2 DN phot^-1 px^-1
;phot_flux_image = im ; [photons/cm2/s/sr]

; boost to make the input image a little more viable
; TODO: need to remove this and do the conversion to photons properly!!
;phot_flux_image = phot_flux_image * (20./aia_plate_scale)^2  ; Fine tune if DN/s is really low -- this is a geometric scaling ; TODO: check if Meng does flux conservation in what he provide


image_simulator, im_array, exposure_time_sec = exposure_short, output_SNR=snr_short, output_image_noise=image_noise_short, output_image_final=image_short
image_simulator, im_array, exposure_time_sec = exposure_long, output_SNR=snr_long, output_image_noise=image_noise_long, output_image_final=image_long

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

i1 = image(im_outer^0.2, rgb_table=sub1, dimensions=SunCET_IMAGE_SIZE, margin=0, BACKGROUND_COLOR='black', TITLE='No Min Max')
i2 = image(im_mid^0.2, rgb_table=sub2, /OVERPLOT)
i3 = image(im_disk^0.2, rgb_table=sub3, /OVERPLOT)

i1 = image((im_outer)^0.2, max_value=4320000.0^0.2, min_value=0, rgb_table=sub1, dimensions=SunCET_IMAGE_SIZE, margin=0, BACKGROUND_COLOR='black', TITLE='Min Max Scaled')
i2 = image((im_mid)^0.2, max_value=4320000.0^0.2, min_value=0, rgb_table=sub2, /OVERPLOT)
i3 = image((im_disk)^0.2, max_value=4320000.0^0.2, min_value=0, rgb_table=sub3, /OVERPLOT)

i1 = image(alog10(im_outer), max_value=alog10(4320000.0), min_value=0, rgb_table=sub1, dimensions=SunCET_IMAGE_SIZE, margin=0, BACKGROUND_COLOR='black', TITLE='Log')
i2 = image(alog10(im_mid), max_value=alog10(4320000.0), min_value=0, rgb_table=sub2, /OVERPLOT)
i3 = image(alog10(im_disk), max_value=alog10(4320000.0), min_value=0, rgb_table=sub3, /OVERPLOT)



STOP
END