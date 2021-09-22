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
PRO SunCET_get_snr_of_cme_at_3_5Rs, exposure_time1=exposure_time1, exposure_time2=exposure_time2, binning=binning

; Defaults
IF exposure_time1 EQ !NULL THEN BEGIN
  exposure_time1 = 0.035
ENDIF
IF exposure_time2 EQ !NULL THEN BEGIN
  exposure_time2 = 5.0
ENDIF
exposure_time1_str = jpmprintnumber(exposure_time1)
exposure_time2_str = jpmprintnumber(exposure_time2)
IF binning EQ !NULL THEN BEGIN
  binning = 2
ENDIF

; Generate the SNR contours 
snr_plotter, snr_neighborhood_size=binning+1, rebin_size=binning, expsoure_time_sec=exposure_time1, n_images_to_stack=10
snr_plotter, snr_neighborhood_size=binning+1, rebin_size=binning, expsoure_time_sec=exposure_time2, n_images_to_stack=4

; Merge the SNR contours
SunCET_snr_merger, exposure_time1=exposure_time1, exposure_time2=exposure_time2, binning=binning

; Get the SNR of the CME at 3.5 Rs
SunCET_plot_snr_trace, snr_binning=binning+1, binning=binning, exposure_time1=exposure_time1, exposure_time2=exposure_time2

END