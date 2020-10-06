;+
; NAME:
;   SunCET_detector_sensitivity
;
; PURPOSE:
;   Run through different detector temperatures and produce simulated images
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Images and savesets on disk
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires the rest of the SunCET image processing code and source data
;
; EXAMPLE:
;   Just run it!
;-
PRO SunCET_detector_sensitivity

; Paths
path_simulator_output = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/SunCET Image Simulation/Image Simulation Results/'
saveloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/Cold vs Warm Detector/'

dark_currents = [1, 20, 40, 80, 160, 320, 640, 1280, 2560] * 1D
temperatures = [-10, 20, 26, 31, 37, 42, 48, 53, 59]

FOR i = 0, n_elements(dark_currents) - 1 DO BEGIN
  SunCET_image_simulator, dark_current=dark_currents[i], /MAKE_SAVESET
  
  file_move, path_simulator_output + 'simulated_images.sav', saveloc + 'SunCET_' + strtrim(temperatures[i], 2) + 'C_detector.sav'
  file_copy, path_simulator_output + '304_5_0.02_3_10.00_Power.png', saveloc + 'power_' + strtrim(temperatures[i], 2) + 'C.png'
  file_copy, path_simulator_output + '304_5_0.02_3_10.00_log.png', saveloc + 'log_' + strtrim(temperatures[i], 2) + 'C.png'
ENDFOR

END