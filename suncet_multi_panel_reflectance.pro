eve_dataloc = getenv('SunCET_base') + 'EVE_Data/'
data = eve_read_whole_fits(eve_dataloc + 'EVS_L2_2012067_00_006_02.fit')

eve_wvln = data.spectrummeta.wavelength * 10
eve_irrad = median(data.spectrum.irradiance, dim = 2)

dataloc = getenv('SunCET_base') + 'Mirror_Data/'
saveloc = dataloc
csrloc = '.''
fontSize = 16

; Load data
restore, dataloc + 'alzr_ascii_template.sav'
restore, dataloc + 'b4c_ascii_template.sav'
restore, dataloc + 'simo_ascii_template.sav'
alzr = read_ascii(dataloc + 'AlZr_195A_TH=5.0.txt', template=alzr_template)
b4c = read_ascii(dataloc + 'XRO47864_TH=5.0.txt', template=b4c_template)
b4c.wave = b4c.wave * 10
simo = read_ascii(dataloc + 'SiMo_195A_TH=5.0.txt', template=simo_template)


valid_range = [160, 225]
valid_eve_points = where(eve_wvln ge valid_range[0] AND eve_wvln le valid_range[1])
eve_truncated_wvln = eve_wvln[valid_eve_points]
eve_truncated_irrad = eve_irrad[valid_eve_points]

b4c_ref_int = interpol(b4c.reflectance, b4c.wave, eve_truncated_wvln, /lsquadratic)
invalid_points = where(eve_truncated_wvln lt min(b4c.wave) OR eve_truncated_wvln gt max(b4c.wave))
b4c_ref_int[invalid_points] = 0
b4c_mod_spec = (eve_truncated_irrad * b4c_ref_int^2.)

simo_ref_int = interpol(simo.reflectance, simo.wave, eve_truncated_wvln, /lsquadratic)
invalid_points = where(eve_truncated_wvln lt min(simo.wave) OR eve_truncated_wvln gt max(simo.wave))
simo_ref_int[invalid_points] = 0
simo_mod_spec = (eve_truncated_irrad * simo_ref_int^2.)

alzr_ref_int = interpol(alzr.reflectance, alzr.wave, eve_truncated_wvln, /lsquadratic)
invalid_points = where(eve_truncated_wvln lt min(alzr.wave) OR eve_truncated_wvln gt max(alzr.wave))
alzr_ref_int[invalid_points] = 0
alzr_mod_spec = (eve_truncated_irrad * alzr_ref_int^2.)

spec_max = max([b4c_mod_spec, simo_mod_spec, alzr_mod_spec])

int_alzr = int_tabulated(eve_truncated_wvln, alzr_ref_int)
int_b4c = int_tabulated(eve_truncated_wvln, b4c_ref_int)
int_simo = int_tabulated(eve_truncated_wvln, simo_ref_int)


p1 = plot(eve_truncated_wvln, b4c_ref_int, thick=2, font_size=fontSize, $
          ytitle='reflectance', $
          name='B$_4$C Mo Al', POSITION=[.18, .55, .95, .95], xrange = valid_range, $
          xtickvalues = findgen(7) * 10 + 160, xtickname = replicate('', 7), $
          dimensions = [600, 800])
p2 = plot(eve_truncated_wvln, alzr_ref_int, 'dodger blue', thick=2, /OVERPLOT, $
          name='Al Zr')
p3 = plot(eve_truncated_wvln, simo_ref_int, 'tomato', thick=2, /OVERPLOT, $
		  name = 'Si Mo')
p1.yrange = [0, 0.6]
t1 = text(0.21, 0.90, 'B$_4$C/Mo/Al, area = ' + JPMPrintNumber(int_b4c), font_size=fontSize-2)
t2 = text(0.21, 0.87, 'Al/Zr, area = ' + JPMPrintNumber(int_alzr), font_size=fontSize-2, color=p2.color)
t3 = text(0.21, 0.84, 'Si/Mo, area = ' + JPMPrintNumber(int_simo), font_size=fontSize-2, color=p3.color)

p_spec = plot(eve_truncated_wvln, eve_truncated_irrad, ytitle = 'spectrum!C[mW/m!e2!n]', $
	          /current, position = [0.18, 0.35, 0.95, 0.55], $
	          xrange = valid_range, thick = 2, font_size = fontsize, $
	          xtickvalues = findgen(7) * 10 + 160, xtickname = replicate('', 7), $
	          ytickvalues = findgen(5) * 2e-4, ytickname = ['  0', ' 20', ' 40', ' 60', ''])


p_mod_spec1 = plot(eve_truncated_wvln, b4c_mod_spec/spec_max, $
	               /current, position = [0.18, 0.1, 0.95, 0.35], $
	               xrange = valid_range, thick = 2, font_size = fontsize, $
				   xtitle='wavelength [Å]')
p_mod_spec2 = plot(eve_truncated_wvln, alzr_mod_spec/spec_max, 'dodger blue', $
	               /overplot, thick = 2)
p_mod_spec3 = plot(eve_truncated_wvln, simo_mod_spec/spec_max, 'tomato', $
	               /overplot, thick = 2, ytitle = 'meas. spec.!C[normalized]')


int_alzr_spec = int_tabulated(eve_truncated_wvln, alzr_mod_spec)
int_b4c_spec = int_tabulated(eve_truncated_wvln, b4c_mod_spec)
int_simo_spec = int_tabulated(eve_truncated_wvln, simo_mod_spec)

int_spec_max = max([int_alzr_spec, int_b4c_spec, int_simo_spec])
int_alzr_spec /= int_spec_max
int_b4c_spec /= int_spec_max
int_simo_spec /= int_spec_max

t1 = text(0.21, 0.3, 'B$_4$C/Mo/Al, flux = ' + JPMPrintNumber(int_b4c_spec), font_size=fontSize-2)
t2 = text(0.21, 0.27, 'Al/Zr, flux = ' + JPMPrintNumber(int_alzr_spec), font_size=fontSize-2, color=p2.color)
t3 = text(0.21, 0.24, 'Si/Mo, flux = ' + JPMPrintNumber(int_simo_spec), font_size=fontSize-2, color=p3.color)


