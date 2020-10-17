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
dataloc = getenv('SunCET_base') + 'Mirror_Data/'
saveloc = dataloc
csrloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/latex/images/'
fontSize = 16

; Load data
restore, dataloc + 'alzr_ascii_template.sav'
restore, dataloc + 'b4c_ascii_template.sav'
restore, dataloc + 'simo_ascii_template.sav'
alzr = read_ascii(dataloc + 'AlZr_195A_TH=5.0.txt', template=alzr_template)
b4c = read_ascii(dataloc + 'XRO47864_TH=5.0.txt', template=b4c_template)
simo = read_ascii(dataloc + 'SiMo_195A_TH=5.0.txt', template=simo_template)

; Make sure all in the same units
b4c.wave *= 10.

; Get consistent range from all
alzr_indices = where(alzr.wave GE 160 AND alzr.wave LE 226)
b4c_indices = where(b4c.wave GE 160 AND b4c.wave LE 226)
simo_indices = where(simo.wave GE 160 AND simo.wave LE 226)

; This roundabout method of restricting the range is required to hack around some weird IDL bugs
tmp_wave = alzr.wave[alzr_indices]
tmp_refl = alzr.reflectance[alzr_indices]
alzr = !NULL
alzr = {wave:tmp_wave, reflectance:tmp_refl}
tmp_wave = b4c.wave[b4c_indices]
tmp_refl = b4c.reflectance[b4c_indices]
b4c = !NULL
b4c = {wave:tmp_wave, reflectance:tmp_refl}
tmp_wave = simo.wave[simo_indices]
tmp_refl = simo.reflectance[simo_indices]
simo = !NULL
simo = {wave:tmp_wave, reflectance:tmp_refl}

; Integrate to get area under the curve
int_alzr = int_tabulated(alzr.wave, alzr.reflectance)
int_b4c = int_tabulated(b4c.wave, b4c.reflectance)
int_simo = int_tabulated(simo.wave, simo.reflectance)

; Make plot
p1 = plot(b4c.wave, b4c.reflectance, thick=2, font_size=fontSize, $
          xtitle='wavelength [Å]', $
          ytitle='reflectance', $
          name='B$_4$C Mo Al')
p2 = plot(alzr.wave, alzr.reflectance, 'dodger blue', thick=2, /OVERPLOT, $
          name='Al Zr')
p3 = plot(simo.wave, simo.reflectance, 'tomato', thick=2, /OVERPLOT, $
          name='Si Mo')
p1.xrange = [160, 226]
p1.yrange = [0, 0.6]
t1 = text(0.19, 0.80, 'B$_4$C/Mo/Al, area = ' + JPMPrintNumber(int_b4c), font_size=fontSize-2)
t2 = text(0.19, 0.75, 'Al/Zr, area = ' + JPMPrintNumber(int_alzr), font_size=fontSize-2, color=p2.color)
t3 = text(0.19, 0.70, 'Si/Mo, area = ' + JPMPrintNumber(int_simo), font_size=fontSize-2, color=p3.color)
p1.save, saveloc + 'coating_comparison.png'
p1.save, csrloc + 'coating_comparison.png'

END