;+
; NAME:
;   SunCET_get_snr_of_cme_at_3_5Rs
;
; PURPOSE:
;   It's hard to remember all of these steps, so script it. Get the SNR of the CME at 3.5 Rs.
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   mhd_sim [string]:       Which of the MHD simulations to load. 
;                           Can be the worst-case-for-snr dim CME event. That is 'dimmest', which is the default.
;                           Or the bright CME moving slow. That is 'bright_slow'. 
;                           Or the bright CME moving fast. That is 'bright_fast'.
;   exposure_time1 [float]: The first of the two exposures times to merge resultant SNRs for
;   exposure_time2 [float]: The second of the two exposure times to merge resultant SNRs for
;   binning [integer]:      The number of pixels binned over (in each direction). Default is 2.
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   None, but prints to the console
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to all the SunCET_base data.
;
; EXAMPLE:
;   Just run it!
;-
PRO SunCET_get_snr_of_cme_at_3_5Rs, mhd_sim=mhd_sim, exposure_time1=exposure_time1, exposure_time2=exposure_time2, binning=binning

; Defaults
IF mhd_sim EQ !NULL THEN BEGIN
  mhd_sim = 'dimmest'
ENDIF
IF exposure_time1 EQ !NULL THEN BEGIN
  exposure_time1 = 0.035
ENDIF
IF exposure_time2 EQ !NULL THEN BEGIN
  exposure_time2 = 15.0
ENDIF
exposure_time1_str = jpmprintnumber(exposure_time1)
exposure_time2_str = jpmprintnumber(exposure_time2)
IF binning EQ !NULL THEN BEGIN
  binning = 2
ENDIF

; Directory config
IF mhd_sim EQ 'dimmest' THEN BEGIN
  dataloc_rendered_maps = getenv('SunCET_base') + 'MHD/dimmest/Rendered_EUV_Maps/'
  dataloc_snr = getenv('SunCET_base') + '/SNR/dimmest/'
  saveloc = getenv('SunCET_base') + 'SNR/dimmest/'
ENDIF ELSE IF mhd_sim EQ 'bright_slow' THEN BEGIN
  dataloc_rendered_maps = getenv('SunCET_base') + 'MHD/bright_slow/Rendered_EUV_Maps/'
  dataloc_snr = getenv('SunCET_base') + '/SNR/bright_slow/'
  saveloc = getenv('SunCET_base') + 'SNR/bright_slow/'
ENDIF ELSE IF mhd_sim EQ 'bright_fast' THEN BEGIN
  dataloc_rendered_maps = getenv('SunCET_base') + 'MHD/bright_fast/Rendered_EUV_Maps/'
  dataloc_snr = getenv('SunCET_base') + '/SNR/bright_fast/'
  saveloc = getenv('SunCET_base') + 'SNR/bright_fast/'
ENDIF ELSE BEGIN
  message, /INFO, JPMsystime() + ' Please select an MHD simulation to run from the available options.'
  return
ENDELSE


; Generate the SNR contours 
snr_plotter, snr_neighborhood_size=binning+1, rebin_size=binning, exposure_time_sec=exposure_time1, n_images_to_stack=10, dataloc=dataloc_rendered_maps, saveloc=saveloc
snr_plotter, snr_neighborhood_size=binning+1, rebin_size=binning, exposure_time_sec=exposure_time2, n_images_to_stack=4, dataloc=dataloc_rendered_maps, saveloc=saveloc

; Merge the SNR contours
SunCET_snr_merger, exposure_time1=exposure_time1, exposure_time2=exposure_time2, binning=binning, dataloc=dataloc_snr, saveloc=saveloc

; Get the SNR of the CME at 3.5 Rs
SunCET_plot_snr_trace, snr_binning=binning+1, binning=binning, exposure_time1=exposure_time1, exposure_time2=exposure_time2, dataloc_rendered_maps=dataloc_rendered_maps, dataloc_snr=dataloc_snr, saveloc=saveloc

END