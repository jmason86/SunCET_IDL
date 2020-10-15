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
;   dark_current [double]: Not used normally, except to override the hardcoded cold/warm detector associated dark currents. [e-/px/s] units.
;                          Overrides /WARM_DETECTOR keyword if both are used. 
;
; KEYWORD PARAMETERS:
;   HIGHLIGHT_SUB_IMAGES: Set to make the sub images clearly distinct
;   MAKE_SAVESET: Set this to save the components of the SHDR composite as an IDL saveset
;   MAKE_MOVIE: Set this to run through all of the images, save them to disk, and create a movie saved to disk
;   VERBOSE: Set to get console log messages
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
;    Random dark frame (Gaussian distribution)
;    Dark frame subtraction -- the mean behavior underlying additional shot noise
;    Shot noise on the dark frame (Poisson distribution)
;    Random read noise (Gaussian distribution)
;    Photon shot noise (Poisson distribution)
;    SunCET aperture size
;    Two mirror coating bounces with mean reflectivity
;    Transmission through entrance and detector filters
;    Detector quantum efficiency, yield, full well, readout # bits, gain
;    SHDR compositing (James)
;    Image stack median (James)
;    Spikes based on actuals from PROBA2/SWAP (or whatever.. just need streaks: 2100 spikes/second/cm2) (Dan)
;    Image 2x2 binning (James)
;    Jitter from exposure to exposure (James)
;    Make quantum yield wavelength dependent (James)
;    Loop over time to create movie (James)
;    1 AU scaling (Dan)
;    PSF placeholder until we get input from Alan Hoskins (Dan)
;  
;  Not yet included but planned (not order of operations, this is priority and order of implementation)
;  TODO:
;    Get it working with Meng's SunCET optimized MHD simulation -- JPM 2020-09-19: nearly there but we're totally saturated right now
;      SunCET bandpass -- derived from DEM that Meng provided (Dan)
;      SUVI 195 bandpass -- the Si/Mo coating is our backup so want to be able to get SNR for that as well (Dan) 
;      Pixel scale (Dan)
;    
;    Blooming around saturated pixels (do pending lab blooming analysis) (James)
;    Jitter within a single exposure time (Dan)
;    
;    Shadows from focal plane filter mesh (effect should be removable in post) (Dan)
;    Scattered light (Dan)
;    
;    Handle the burst data (rapid cadence) (James)
;    
;    Update dead pixel likeliehood based on knowledge of our detector 
;    Diffraction from entrance filter mesh (Not going to do)


; Question to address: optimization of time -- SNR pushes longer exposure, noise (read and jitter) pushes shorter exposures


PRO SunCET_image_simulator, dark_current=dark_current, $ 
                            HIGHLIGHT_SUB_IMAGES=HIGHLIGHT_SUB_IMAGES, MAKE_SAVESET=MAKE_SAVESET, MAKE_MOVIE=MAKE_MOVIE, VERBOSE=VERBOSE
kill
tic

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
saveloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/SunCET Image Simulation/Image Simulation Results/'

; Configuration (flexible numbers)
exposure_short = 0.025 ; [sec] Up to 23 seconds
exposure_long = 10.0 ; [sec] Up to 23 seconds
num_short_im_to_stack = 5 ; Up to 1 minute when combined with exposure_short
num_long_im_to_stack = 3 ; Up to 1 minute when combined with exposure_long

; Firm numbers
SunCET_image_size = [1500, 1500] ; [pixels]
SunCET_fov_deg = 2. ; [deg] Assumes that the other direction FOV is the same (i.e., square FOV)
binning = 2. ; [pixels] The number of pixels to bin in each axis, e.g., 2 x 2 should be specified as 2.
jitter = 0.6372 ; [arcsec/s] 1 sigma RMS jitter from MinXSS (comparable to CSIM average across axes)
plate_scale = 4.8 ; [arcsec/pixel]
WARM_DETECTOR = 0 ; Keyword flag passthrough, so only use 0/1 (should really be True/False if IDL had that)

files = file_search('/Users/jmason86/Dropbox/Research/Data/MHD/For SunCET Phase A/euv_sim/euv_sim_3*.sav')

; Prepare image stack
bigger_num_to_stack = num_short_im_to_stack > num_long_im_to_stack
im_outer_stack = dblarr(SunCET_image_size[0], SunCET_image_SIZE[1], bigger_num_to_stack)
im_mid_stack = im_outer_stack
im_disk_stack = im_outer_stack

; Prepare for movie
IF keyword_set(MAKE_MOVIE) THEN BEGIN
  files = file_search('/Users/jmason86/Dropbox/Research/Data/MHD/For SunCET Phase A/euv_sim/euv_sim_*.sav') ; all files instead of a subselection
  last_movie_index = n_elements(files) - bigger_num_to_stack - 1
  fps = 20
  
  movie_object_power = IDLffVideoWrite(saveloc + 'Power.mp4')
  vid_stream_power = movie_object_power.AddVideoStream(SunCET_image_size[0] / binning, SunCET_image_size[1] / binning, fps)
  movie_object_log = IDLffVideoWrite(saveloc + 'Log.mp4')
  vid_stream_log = movie_object_log.AddVideoStream(SunCET_image_size[0] / binning, SunCET_image_size[1] / binning, fps)
ENDIF ELSE BEGIN
  last_movie_index = 0
ENDELSE

; Loop through all files to create movie if applicable
FOR movie_index = 0, last_movie_index, bigger_num_to_stack DO BEGIN
  files_one_integration = files[movie_index: movie_index + bigger_num_to_stack]
  
  ; Loop through time
  FOR time_index = 0, bigger_num_to_stack - 1 DO BEGIN
    restore, files_one_integration[time_index] ; [erg/cm2/s/pixel] -- simulation pixel
    
    ; Pull out the simulation plate scale and wavelengths
    sim_plate_scale = euv171_image.dx  ; [arcsec]
    
    sim_array = [[[euv171_image.data]], $
                 [[euv177_image.data]], $
                 [[euv180_image.data]], $
                 [[euv195_image.data]], $
                 [[euv202_image.data]]]
    
    image_simulator, sim_array, sim_plate_scale, exposure_time_sec=exposure_short, WARM_DETECTOR=WARM_DETECTOR, dark_current=dark_current, output_SNR=snr_short, output_image_noise=image_noise_short, output_image_final=image_short
    image_simulator, sim_array, sim_plate_scale, exposure_time_sec=exposure_long, WARM_DETECTOR=WARM_DETECTOR, dark_current=dark_current, output_SNR=snr_long, output_image_noise=image_noise_long, output_image_final=image_long
    
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
    mask2d = array_indices(xgrid, mask1d)
    im_disk = fltarr(SunCET_image_size)
    FOR i = 0, n_elements(mask2d[0, *]) - 1 DO BEGIN
      im_disk[mask2d[0, i], mask2d[1, i]] = image_short[mask2d[0, i], mask2d[1, i]]
    ENDFOR
    ; Re-NaN since somehow ended up turning the NaNs to 0s
    im_disk[where(im_disk EQ 0)] = !VALUES.F_NAN
    
    ; Off disk pixels
    im_outer = im_disk
    im_mid = im_disk
    im_outer[bound0:bound1, *] = image_long[bound0:bound1, *] ; left
    im_mid[bound1:bound2, *] = image_long[bound1:bound2, *] ; middle
    im_outer[bound2:bound3, *] = image_long[bound2:bound3, *] ; right
    
    ; Normalize by exposure time
    im_outer /= exposure_long
    im_mid /= exposure_long
    im_disk /= exposure_short
      
    ; Apply jitter between frames
    jitter_short = JPMrandomn(seed, stddev=(jitter * exposure_short)) ; [arcsec]
    jitter_long = JPMrandomn(seed, stddev=(jitter * exposure_long)) ; [arcsec]
    shift_short = jitter_short / plate_scale ; [pixels] If < 1, then shift() won't move the image, which is what we want
    shift_long = jitter_long / plate_scale ; [pixels]
    random_negative = (randomu(seed) LT 0.5) ? 1:-1
    shift_short_x = randomu(seed) * shift_short
    shift_short_y = sqrt(shift_short^2. - shift_short_x^2.) * random_negative
    shift_long_x = randomu(seed) * shift_long
    shift_long_y = sqrt(shift_long^2. - shift_long_x^2.) * random_negative
    im_outer = shift(im_outer, shift_long_x, shift_long_y)
    im_mid = shift(im_mid, shift_long_x, shift_long_y)
    im_disk = shift(im_disk, shift_short_x, shift_short_y)
    
    IF keyword_set(VERBOSE) THEN BEGIN
      print, 'short = ' + strtrim(shift_short, 2) + ' | long = ' + strtrim(shift_long, 2)
      print, 'long_x = ' + strtrim(shift_long_x, 2) + ' | long_y = ' + strtrim(shift_long_y, 2) + ' | sanity = ' + strtrim(sqrt(shift_long_x^2. + shift_long_y^2.), 2)
    END
    
    ; Add to image stack for median noise reduction
    im_outer_stack[*, *, time_index] = im_outer
    im_mid_stack[*, *, time_index] = im_mid
    im_disk_stack[*, *, time_index] = im_disk
    
    IF keyword_set(VERBOSE) THEN BEGIN
      message, /INFO, JPMsystime() + ' Completed ' + strtrim(time_index, 2) + '/' + strtrim(bigger_num_to_stack, 2) + ' images'
    ENDIF
  ENDFOR ; loop through time 
  
  ; Apply median to image stack to clean up particle hits and other random noise
  im_outer_median = median(im_outer_stack[*, *, 0:num_long_im_to_stack - 1], DIMENSION=3)
  im_mid_median = median(im_mid_stack[*, *, 0:num_long_im_to_stack - 1], DIMENSION=3)
  im_disk_median = median(im_disk_stack[*, *, 0:num_short_im_to_stack - 1], DIMENSION=3)
  
  ; 2x2 binning
  im_outer_median_binned = rebin(im_outer_median, n_elements(im_outer_median[0, *]) / binning, n_elements(im_outer_median[*, 0]) / binning) * binning^2. ; * binning^2 is to preserve counts
  im_mid_median_binned = rebin(im_mid_median, n_elements(im_mid_median[0, *]) / binning, n_elements(im_mid_median[*, 0]) / binning) * binning^2.
  im_disk_median_binned = rebin(im_disk_median, n_elements(im_disk_median[0, *]) / binning, n_elements(im_disk_median[*, 0]) / binning) * binning^2.
  
  ; Create image composites
  path_filename = ParsePathAndFilename(files_one_integration[time_index - 1])
  save_filename_base = saveloc + strmid(path_filename.filename, 6, 3, /REVERSE_OFFSET) + '_' + strtrim(num_short_im_to_stack, 2) + '_' + JPMPrintNumber(exposure_short) + '_' + strtrim(num_long_im_to_stack, 2) + '_' + JPMPrintNumber(exposure_long) + '_'
  
  ; Ensure uniform scaling by defining set minimum and maximums
  max_log = alog10(4320000.0)
  min_log = 0
  max_power = 4320000.0^0.2
  min_power = 0
  
  i1 = image(alog10(im_outer_median_binned), max_value=max_log, min_value=min_log, rgb_table=sub1, dimensions=SunCET_IMAGE_SIZE/binning, margin=0, BACKGROUND_COLOR='black', WINDOW_TITLE='Log, Median Stack', BUFFER=MAKE_MOVIE)
  i2 = image(alog10(im_mid_median_binned), max_value=max_log, min_value=min_log, rgb_table=sub2, /OVERPLOT)
  i3 = image(alog10(im_disk_median_binned), max_value=max_log, min_value=min_log, rgb_table=sub3, /OVERPLOT)
  i1.save, save_filename_base + 'log.png'

  i4 = image((im_outer_median_binned)^0.2, max_value=max_power, min_value=min_power, rgb_table=sub1, dimensions=SunCET_IMAGE_SIZE/binning, margin=0, BACKGROUND_COLOR='black', WINDOW_TITLE='^0.2', BUFFER=MAKE_MOVIE)
  i5 = image((im_mid_median_binned)^0.2, max_value=max_power, min_value=min_power, rgb_table=sub2, /OVERPLOT)
  i6 = image((im_disk_median_binned)^0.2, max_value=max_power, min_value=min_power, rgb_table=sub3, /OVERPLOT)
  i4.save, save_filename_base + 'Power.png'
  
  IF keyword_set(MAKE_MOVIE) THEN BEGIN
    timeInMovie = movie_object_log.Put(vid_stream_log, i1.CopyWindow())
    timeInMovie = movie_object_power.Put(vid_stream_power, i4.CopyWindow())
    i1.Close
    i4.CLose
  ENDIF
  
  IF keyword_set(MAKE_SAVESET) THEN BEGIN
    save, im_outer_median_binned, im_mid_median_binned, im_disk_median_binned, filename=saveloc+'simulated_images.sav', /COMPRESS
  ENDIF
  
  IF keyword_set(VERBOSE) THEN BEGIN
    message, /INFO, JPMsystime() + ' Completed ' + strtrim(movie_index, 2) + '/' + strtrim(last_movie_index, 2) + ' movie steps'
  ENDIF
  
ENDFOR ; movie_index loop

IF keyword_set(MAKE_MOVIE) THEN BEGIN
  movie_object_log.Cleanup
  movie_object_power.Cleanup
ENDIF

toc
;STOP
kill
END