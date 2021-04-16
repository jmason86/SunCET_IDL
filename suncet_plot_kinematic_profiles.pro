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
fontSize = 28
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



;
; Modify some real MHD results for animated traces
;
restore, '/Users/jmason86/Google Drive/Proposals/SunCET CubeSat/Figures and files dump/Fan 2016 CME Figure/fan16_cavfront.sav'
; Convert to km/s and km/s2 instead of cm/s and cm/s2
time = (t_cavfront - t_cavfront[0]) / 60 ; [minutes]
time = time/max(time) * 60 ; rescale slightly from 40 to 60 minutes
height = r_cavfront ; [Rs]
speed = v_cavfront * 1e-8 ; [Mm/s]
acceleration = dvdt_cavfront * 1e-5 ; [km/s2]

; Interpolate to crank up the number of points
n_frames = 90
time_int = JPMrange(0, 60, npts=n_frames)
height = interpol(height, time, time_int)
speed = interpol(speed, time, time_int)
acceleration = interpol(acceleration, time, time_int)
time = time_int

w = window(DIMENSIONS = [1200, 1200], background_color='black', FONT_SIZE=fontSize, /BUFFER)
p1 = plot(time, height, thick=thickness, /CURRENT, font_size=fontSize, 'white', font_color='white', position=[0.13, 0.74, 0.95, 0.99], $
          xshowtext=0, xrange=minmax(time), xcolor='white', $
          yrange=[1, 5], ycolor='white', $
          axis_style=4)
p1y = axis('Y', target=p1, color='white', minor=0, tickfont_size=fontSize, location=0)
p2 = plot(time, speed, thick=thickness, /CURRENT, font_size=fontSize, 'white', font_color='white', position=[0.13, 0.41, 0.95, 0.66], $
          xshowtext=0, xrange=minmax(time), xcolor='white', $
          yrange=[0, 2], ycolor='white', $
          axis_style=4)
p2y = axis('Y', target=p2, color='white', minor=0, tickfont_size=fontSize, location=0)
p3 = plot(time, acceleration, thick=thickness, /CURRENT, font_size=fontSize, 'white', font_color='white', position=[0.13, 0.08, 0.95, 0.33], $
          xtitle='elapsed time [minutes]', xrange=minmax(time), xcolor='white', xminor=0, $
          yrange=[-2, 8], ycolor='white', yminor=0, $
          axis_style=1)
t1 = text(0.04, 0.77, 'height [R$_\Sun$]', orientation=90, font_size=fontSize, color='white')
t2 = text(0.04, 0.42, 'speed [Mm s$^{-1}$]', orientation=90, font_size=fontSize, color='white')
t3 = text(0.04, 0.05, 'acceration [km s$^{-2}$]', orientation=90, font_size=fontSize, color='white')

; Make a nice grid like modern plots on NYTimes and 538
xb = p3.convertcoord(10, -2, /DATA, /TO_NORMAL)
xt = p1.convertcoord(10, 5, /DATA, /TO_NORMAL)
l1 = polyline([xb[0], xb[0]], [xb[1], xt[1]], color='dim grey', thick=2, transparency=30)

xb = p3.convertcoord(20, -2, /DATA, /TO_NORMAL)
xt = p1.convertcoord(20, 5, /DATA, /TO_NORMAL)
l2 = polyline([xb[0], xb[0]], [xb[1], xt[1]], color='dim grey', thick=2, transparency=30)

xb = p3.convertcoord(30, -2, /DATA, /TO_NORMAL)
xt = p1.convertcoord(30, 5, /DATA, /TO_NORMAL)
l3 = polyline([xb[0], xb[0]], [xb[1], xt[1]], color='dim grey', thick=2, transparency=30)

xb = p3.convertcoord(40, -2, /DATA, /TO_NORMAL)
xt = p1.convertcoord(40, 5, /DATA, /TO_NORMAL)
l4 = polyline([xb[0], xb[0]], [xb[1], xt[1]], color='dim grey', thick=2, transparency=30)

xb = p3.convertcoord(50, -2, /DATA, /TO_NORMAL)
xt = p1.convertcoord(50, 5, /DATA, /TO_NORMAL)
l5 = polyline([xb[0], xb[0]], [xb[1], xt[1]], color='dim grey', thick=2, transparency=30)

xb = p3.convertcoord(60, -2, /DATA, /TO_NORMAL)
xt = p1.convertcoord(60, 5, /DATA, /TO_NORMAL)
l6 = polyline([xb[0], xb[0]], [xb[1], xt[1]], color='dim grey', thick=2, transparency=30)

p3l = plot(p3.xrange, [0, 0], color='dim grey', thick=2, transparency=30, overplot=p3)
p3l.order, /SEND_TO_BACK
p3l = plot(p3.xrange, [4, 4], color='dim grey', thick=2, transparency=30, overplot=p3)
p3l.order, /SEND_TO_BACK
p3l = plot(p3.xrange, [8, 8], color='dim grey', thick=2, transparency=30, overplot=p3)
p3l.order, /SEND_TO_BACK

p2l = plot(p2.xrange, [0, 0], color='dim grey', thick=2, transparency=30, overplot=p2)
p2l.order, /SEND_TO_BACK
p2l = plot(p2.xrange, [1, 1], color='dim grey', thick=2, transparency=30, overplot=p2)
p2l.order, /SEND_TO_BACK
p2l = plot(p2.xrange, [2, 2], color='dim grey', thick=2, transparency=30, overplot=p2)
p2l.order, /SEND_TO_BACK

p1l = plot(p1.xrange, [1, 1], color='dim grey', thick=2, transparency=30, overplot=p1)
p1l.order, /SEND_TO_BACK
p1l = plot(p1.xrange, [4, 4], color='dim grey', thick=2, transparency=30, overplot=p1)
p1l.order, /SEND_TO_BACK

FOR i = 0, n_frames - 1 DO BEGIN
  p1.setdata, time[0:i], height[0:i]
  p2.setdata, time[0:i], speed[0:i]
  p3.setdata, time[0:i], acceleration[0:i]
  p1.save, saveloc + '/animation/' + JPMPrintNumber(i, /NO_DECIMALS) + '.png', /TRANSPARENT, RESOLUTION=100
ENDFOR
STOP







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