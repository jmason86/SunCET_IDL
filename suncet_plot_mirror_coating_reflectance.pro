;+
; NAME:
;   SunCET_plot_mirror_coating_reflectance
;
; PURPOSE:
;   Plot a comparison of mirror coatings
;
; INPUTS:
;   None, but need access to the data
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plots on screen and on disk
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to the data
;
; EXAMPLE:
;   Just run it!
;
;-
PRO SunCET_plot_mirror_coating_reflectance

; Defaults
dataloc = getenv('SunCET_base')+ 'mirror_reflectivity/'
saveloc = dataloc
fontSize = 16

; Load data
restore, dataloc + 'b4c_model_template.sav'
restore, dataloc + 'alzr_ascii_template.sav'
restore, dataloc + 'XRO47864_TH=5.0_Windt_Measurements_template.sav'
restore, dataloc + 'simo_ascii_template.sav'
restore, dataloc + '2024-03-21 rigaku measurements final/b4c_rigaku_final_template.sav'
alzr = read_ascii(dataloc + 'AlZr_195A_TH=5.0.txt', template=alzr_template)
simo = read_ascii(dataloc + 'SiMo_195A_TH=5.0.txt', template=simo_template)
model = read_ascii(dataloc + 'B4C_Mo_Al_1-11000A.txt', template=b4c_model_template)
windt_measurement = read_ascii(dataloc + 'XRO47864_TH=5.0_Windt_Measurements.txt', template=windt_measurement_template)
rigaku_m1 = read_ascii(dataloc + '2024-03-21 rigaku measurements final/m1_sn2_final.csv', template=b4c_rigaku_final_template)
rigaku_m2 = read_ascii(dataloc + '2024-03-21 rigaku measurements final/m2_sn3_final.csv', template=b4c_rigaku_final_template)

; Make sure all in the same units
windt_measurement.wavelength_nm *= 10.
rigaku_m1.wavelength_nm *= 10.
rigaku_m2.wavelength_nm *= 10.

; Average the M1 and M2 mirror measurements from Rigaku
common_wavelength = jpmrange(min([min(rigaku_m1.wavelength_nm), min(rigaku_m2.wavelength_nm)]), max([max(rigaku_m1.wavelength_nm), max(rigaku_m2.wavelength_nm)]), npts=200)
interp_reflectivity_m1 = interpol(rigaku_m1.reflectivity, rigaku_m1.wavelength_nm, common_wavelength, /spline)
interp_reflectivity_m2 = interpol(rigaku_m2.reflectivity, rigaku_m2.wavelength_nm, common_wavelength, /spline)
average_reflectivity = (interp_reflectivity_m1 + interp_reflectivity_m2) / 2.0
rigaku = {wavelength_angstrom: common_wavelength, reflectivity: average_reflectivity}


; Get consistent range from all
wave_short = 160
wave_long = 226
alzr_indices = where(alzr.wave GE wave_short AND alzr.wave LE wave_long)
simo_indices = where(simo.wave GE wave_short AND simo.wave LE wave_long)
model_indices = where(model.wavelength GE wave_short AND model.wavelength LE wave_long)
windt_measurement_indices = where(windt_measurement.wavelength_nm GE wave_short AND windt_measurement.wavelength_nm LE wave_long)
rigaku_indices = where(rigaku.wavelength_angstrom GE wave_short AND rigaku.wavelength_angstrom LE wave_long)

; This roundabout method of restricting the range is required to hack around some weird IDL bugs
tmp_wave = alzr.wave[alzr_indices]
tmp_refl = alzr.reflectance[alzr_indices]
alzr = !NULL
alzr = {wave:tmp_wave, reflectance:tmp_refl}
tmp_wave = simo.wave[simo_indices]
tmp_refl = simo.reflectance[simo_indices]
simo = !NULL
simo = {wave:tmp_wave, reflectance:tmp_refl}
tmp_wave = windt_measurement.wavelength_nm[windt_measurement_indices]
tmp_refl = windt_measurement.reflectance[windt_measurement_indices]
windt_measurement = !NULL
windt_measurement = {wave:tmp_wave, reflectance:tmp_refl}
tmp_wave = model.wavelength[model_indices]
tmp_refl = model.reflectance[model_indices]
model = !NULL
model = {wave:tmp_wave, reflectance:tmp_refl}
tmp_wave = rigaku.wavelength_angstrom[rigaku_indices]
tmp_refl = rigaku.reflectivity[rigaku_indices]
rigaku = !NULL
rigaku = {wave:tmp_wave, reflectance:tmp_refl}

; Integrate to get area under the curve
int_alzr = int_tabulated(alzr.wave, alzr.reflectance)
int_simo = int_tabulated(simo.wave, simo.reflectance)
int_windt_measurement = int_tabulated(windt_measurement.wave, windt_measurement.reflectance)
int_model = int_tabulated(model.wave, model.reflectance)
int_rigaku = int_tabulated(rigaku.wave, rigaku.reflectance)

; Make plot
p1 = plot(rigaku.wave, rigaku.reflectance, thick=2, font_size=fontSize, $
          xtitle='wavelength [Å]', $
          ytitle='reflectance', $
          name='Rigaku B$_4$C Mo Al - Final Measurements (M1SN2, M2SN3)')
p2 = plot(windt_measurement.wave, windt_measurement.reflectance, thick=2, color='grey', /OVERPLOT, $
          name='Windt B$_4$C Mo Al - Measurement (2020)')
p3 = plot(model.wave, model.reflectance, thick=2, linestyle='--', color='light grey', /OVERPLOT, $
          name='B$_4$C Mo Al - IMD model')
p4 = plot(alzr.wave, alzr.reflectance, 'dodger blue', thick=2, /OVERPLOT, $
          name='Al Zr')
p5 = plot(simo.wave, simo.reflectance, 'tomato', thick=2, /OVERPLOT, $
          name='Si Mo')
p1.xrange = [wave_short, wave_long]
p1.yrange = [0, 0.7]
t1 = text(0.17, 0.80, 'B$_4$C/Mo/Al model, area = ' + JPMPrintNumber(int_model), font_size=fontSize-6, color=p3.color)
t2 = text(0.17, 0.75, 'Rigaku B$_4$C/Mo/Al - Final Measurements (M1SN2, M2SN3), area = ' + JPMPrintNumber(int_rigaku), font_size=fontSize-6, color=p1.color)
t3 = text(0.17, 0.70, 'Windt B$_4$C/Mo/Al - Measurement (2020), area = ' + JPMPrintNumber(int_windt_measurement), font_size=fontSize-6, color=p2.color)
t4 = text(0.17, 0.65, 'Al/Zr, area = ' + JPMPrintNumber(int_alzr), font_size=fontSize-6, color=p4.color)
t5 = text(0.17, 0.60, 'Si/Mo, area = ' + JPMPrintNumber(int_simo), font_size=fontSize-6, color=p5.color)
p1.save, saveloc + 'coating_comparison.png'

END