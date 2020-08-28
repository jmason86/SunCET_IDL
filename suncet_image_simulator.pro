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
;   None
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
PRO SunCET_image_simulator

  print, 'This is the IDL header template written by James Paul Mason.'

END