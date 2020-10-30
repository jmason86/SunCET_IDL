;+
; NAME:
;   SunCET_plot_kinematic_profiles
;
; PURPOSE:
;   Load and plot CME kinematic profiles for CSR
;
; INPUTS:
;   None directly, but need access to the files
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plots on screen and saved on disk
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to the csv data sources
;
; EXAMPLE:
;   Just run it
;-
PRO SunCET_plot_kinematic_profiles

; Defaults
dataloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/Kinematic Profiles/'
saveloc = dataloc
csrloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/latex/images/'
mhdloc = '/Users/jmason86/Dropbox/Research/Data/SunCET Base Data/MHD/'
fontSize = 24
thickness = 4
rs2km = 695700.

; Load the data
restore, dataloc + 'observation_csv_template.sav'
obs = read_ascii(dataloc + 'SunCET Phase A Kinematic Profiles.csv', template=obs_template)
restore, mhdloc + 'Model Height Time.sav'

; Extract some stuff
good_indices = where(obs.height_rs GE 1 AND obs.speed LT 5e3)
t = obs.time_since_start_min[good_indices]
t_model_minutes = t_model / 60.

; Get model speed and acceleration
height_model_km = height_model * rs2km
speed_model = deriv(t_model, height_model_km)
acceleration_model = deriv(t_model, speed_model)

; Create plot
w = window(DIMENSIONS = [1200, 1200], FONT_SIZE=fontSize)
p1 = plot(t, obs.height_rs[good_indices], thick=thickness, /CURRENT, font_size=fontSize, position=[0.13, 0.74, 0.95, 0.99], $
          xshowtext=0, $
          ytitle='height [R$_\Sun$]', yrange=[0, 4], $
          name='observed')
p1m = plot(t_model_minutes, height_model, thick=thickness, /OVERPLOT, color='tomato', linestyle='--', name='model')
p2 = plot(t, obs.speed[good_indices], thick=thickness, /CURRENT, font_size=fontSize, position=[0.13, 0.41, 0.95, 0.66], $
          xshowtext=0, $
          ytitle='speed [km s$^{-1}$]', yrange=[0, 3000])
p2m = plot(t_model_minutes, speed_model, thick=thickness, /OVERPLOT, color='tomato', linestyle='--')
p3 = plot(t, obs.acceleration[good_indices], thick=thickness, /CURRENT, font_size=fontSize, position=[0.13, 0.08, 0.95, 0.33], $
          xtitle='elapsed time [minutes]', $
          ytitle='Acceration [km s$^{-2}$]')
p3m = plot(t_model_minutes, acceleration_model, thick=thickness, /OVERPLOT, color='tomato', linestyle='--')
l = legend(target=[p1, p1m], position=[0.91, 0.88], font_size=fontSize-2)

p1.save, saveloc + 'Kinematic Profiles.png'
p1.save, csrloc + 'kinematic_profiles.png'

STOP


END