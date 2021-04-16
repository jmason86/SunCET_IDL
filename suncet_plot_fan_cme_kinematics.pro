;+
; NAME:
;   SunCET_plot_fan_cme_kinematics
;
; PURPOSE:
;   Take the data from Yuhong Fan's 2016 paper and use it to calculate acceleration and plot height-time, speed-time, and acceleration-time.
;   Originally intended for the SunCET 2019 H-FORT proposal
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   dataloc [string]: The path to the extracted data csv files. Default is '/Users/jmason86/Google Drive/Proposals/SunCET CubeSat/Figures and files dump/Fan 2016 CME Figure/'
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Stack plot of height, speed, and acceleration versus time
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   NOne
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2019-08-14: James Paul Mason: Wrote script.
;-
PRO SunCET_plot_fan_cme_kinematics, dataloc = dataloc

; Defaults
IF dataloc EQ !NULL THEN dataloc = '/Users/jmason86/Google Drive/Proposals/SunCET CubeSat/Figures and files dump/Fan 2016 CME Figure/'
fontSize = 20

; Load the data 
restore, dataloc + 'fan16_cavfront.sav'

; Convert to km/s and km/s2 instead of cm/s and cm/s2
v_cavfront *= 1e-5
dvdt_cavfront *= 1e-5

; Plot height, speed, and acceleration vs time
w = window(DIMENSIONS = [800, 2000], FONT_SIZE=fontSize)
p1 = plot(t_cavfront / 60., r_cavfront, THICK=3, /CURRENT, FONT_SIZE=fontSize, POSITION=[0.23, 0.58, 0.95, 0.78], $
          YTITLE='Height [R$_\Sun$]', $
          XSHOWTEXT = 0)
p2 = plot(t_cavfront / 60., v_cavfront, THICK=3, /CURRENT, FONT_SIZE=fontSize, POSITION=[0.23, 0.33, 0.95, 0.53], $
          YTITLE='Speed [km s$^{-1}$]', $
          XSHOWTEXT = 0)
p3 = plot(t_cavfront / 60., dvdt_cavfront, THICK=3, /CURRENT, FONT_SIZE=fontSize, POSITION=[0.23, 0.08, 0.95, 0.28], $
          YTITLE='Acceration [km s$^{-2}$]', $
          XTITLE = 'Time [minutes]')
STOP
p1.save, 'Fan 2016 Plots.png'

END