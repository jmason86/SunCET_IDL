;+
; NAME:
;   suncet_calculate_effective_area_and_electrons.pro
;
; PURPOSE:
;   Description of algorithm. Turns what input into what output, in broad terms.
;
; INPUTS:
;   variableName [data type (e.g., string)]: Description
;
; OPTIONAL INPUTS:
;   mirror_coating [string]: Which mirror coating to use. Either 'B4C' (Default; shorthand for B4C/Mo/Al), 'SiMo', or 'AlZr'. Case insensitive.
;
; KEYWORD PARAMETERS:
;   KEYWORD1: Description
;
; OUTPUTS:
;   variableName [data type]: Description
;
; OPTIONAL OUTPUTS:
;   variableName [data type]: Description
;
; RESTRICTIONS:
;   Custom dependencies e.g., minxss-specific IDL code, custom time libraries, and limitations of this code in its forseeable usage
;+

PRO suncet_calculate_effective_area_and_electrons, mirror_coating=mirror_coating

; Defaults
IF mirror_coating EQ !NULL THEN BEGIN
  mirror_coating = 'flight_fm1'
ENDIF

; set up environment variable
base_path = getenv('SunCET_base')
reflectivity_path = base_path + 'mirror_reflectivity/'

; Constants
h = 6.62606957d-34     ; [Js]
c = 299792458.d        ; [m/s]
j2ev = 6.242d18        ; [ev/J] Conversion from Joules to electron volts
j2erg = 1e7            ; [erg/J] Conversion from Joules to ergs
arcsec2rad = 4.8481e-6 ; [radian/arcsec] Conversion from arcsec to radians
one_au_cm = 1.496e13 ; [cm] Earth-Sun Distance in cm
average_rsun_arc = 959.63 ; [arcsec] Average solar radius in arcsecons
rsun_cm = 6.957e10 ; [cm] solar radius in cm
one_au_sun_sr = 6.7993e-5 ; [sr] angular diameter of sun at 1 AU in steradians

; Load full solar spectrum
solar_spectrum = suncet_read_whi_reference_spectrum()

; Instrument parameters
entrance_aperture = 6.5 ; [cm] diameter, AKA entrance pupil diameter
secondary_mirror_obscuration = 0.413 ; [% as a fraction] what percentage of the entrance aperture is blocked by the secondary mirror
aperture = (!PI * (entrance_aperture/2.)^2. * (1 - secondary_mirror_obscuration))
mesh_transmission =  0.95 ; [% but as a fraction] 5lpi nickel mesh = 0.98, 70 LPI nickel mesh = 0.83, fitting line to those two suggests 20 LPI = 0.95
quantum_efficiency = 0.85
exposure_time = 15. ; [seconds]

; Load and interpolate filter transmission data
restore, base_path + 'filter_transmission/filter_log_template.sav'
single_filter_transmission = read_ascii(base_path + 'filter_transmission/Al_150nm_thick_0.01-1250nm_range.csv', template=filter_log_template) ; 150 nm Al
filter_wavelength = single_filter_transmission.wavelength_angstrom / 10. ; [nm]
carbon_transmission = read_ascii(base_path + 'filter_transmission/C_20nm_thick_0.01-2066nm_range.csv', template=filter_log_template) ; 5 nm C
carbon_wavelength = carbon_transmission.wavelength_angstrom / 10. ; [nm]
carbon_transmission = reform(interpol(carbon_transmission.transmittance, carbon_wavelength, filter_wavelength))
filter_transmission_raw = single_filter_transmission.transmittance * single_filter_transmission.transmittance * carbon_transmission * mesh_transmission
filter_transmission = reform(interpol(filter_transmission_raw, filter_wavelength, solar_spectrum.wavelength))

; Load and interpolate mirror reflectivity data
IF strcmp(mirror_coating, 'flight_fm1', /FOLD_CASE) THEN BEGIN
  b4c = suncet_load_final_mirror_coating_measurements(fm=1)
  r_wave = b4c.wavelength_nm
  reflect = b4c.reflectivity
ENDIF ELSE IF strcmp(mirror_coating, 'b4c', /FOLD_CASE) THEN BEGIN
  restore, reflectivity_path + 'XRO47864_TH=5.0_Windt_Measurements_template.sav'
  b4c = read_ascii(reflectivity_path + 'XRO47864_TH=5.0_Windt_Measurements.txt', template=windt_measurement_template)
  r_wave = b4c.wavelength_nm
  reflect = b4c.reflectance
ENDIF ELSE IF strcmp(mirror_coating, 'b4c_model', /FOLD_CASE) THEN BEGIN
  restore, reflectivity_path + 'b4c_model_template.sav'
  b4c = read_ascii(reflectivity_path + 'B4C_Mo_Al_1-11000A.txt', template=b4c_model_template)
  r_wave = b4c.wavelength / 10. ; [nm]
  reflect = b4c.reflectance
ENDIF ELSE IF strcmp(mirror_coating, 'alzr', /FOLD_CASE) THEN BEGIN
  restore, reflectivity_path + 'alzr_ascii_template.sav'
  alzr = read_ascii(reflectivity_path + 'AlZr_195A_TH=5.0.txt', template=alzr_template)
  r_wave = alzr.wave / 10. ; [nm]
  reflect = alzr.reflectance
ENDIF ELSE IF strcmp(mirror_coating, 'simo', /FOLD_CASE) THEN BEGIN
  restore, reflectivity_path + 'simo_ascii_template.sav'
  simo = read_ascii(reflectivity_path + 'SiMo_195A_TH=5.0.txt', template=simo_template)
  r_wave = simo.wave / 10.; [nm]
  reflect = simo.reflectance
ENDIF ELSE IF strcmp(mirror_coating, 'AlMoSiC', /FOLD_CASE) THEN BEGIN
  restore, reflectivity_path + 'AlMoSiC_template.sav'
  almosic = read_ascii(reflectivity_path + 'Aperiodique-ideal_AlMoSiC_5deg_fev2019_JR.txt', template=almosic_template)
  r_wave = almosic.wave ; [nm]
  reflect = almosic.reflectance
ENDIF ELSE IF strcmp(mirror_coating, 'AlMoB4C', /FOLD_CASE) THEN BEGIN
  restore, reflectivity_path + 'almob4c_template.sav'
  almob4c = read_ascii(reflectivity_path + 'IMD_195_AlMoB4C.txt', template=almob4c_template)
  r_wave = almob4c.wave ; [nm]
  reflect = almob4c.reflectance
ENDIF ELSE BEGIN
  message, /INFO, 'No matching mirror coating supplied. Must be either "B4C", "AlZr", or "SiMo".'
  return
ENDELSE
mirror_reflectivity = reform(interpol(reflect, r_wave, solar_spectrum.wavelength) > 0.0)

; Effective area calculation
effective_area = (aperture * mirror_reflectivity^2. * filter_transmission) > 0 ; [cm^2]
quantum_yield = (h*c / (solar_spectrum.wavelength * 1e-9)) * j2ev / 3.63 ; [e-/phot] Quantum yield: how many electrons are produced for each abs

; Import GOES/SUVI effective areas
restore, base_path + 'effective_area/suvi_effective_area_template.sav'
suvi_171_effective_area = read_ascii(base_path + 'effective_area/suvi_171_effective_area.csv', template=suvi_effective_area_template)
suvi_195_effective_area = read_ascii(base_path + 'effective_area/suvi_195_effective_area.csv', template=suvi_effective_area_template)

; Import SolO/EUI/FSI effective areas
restore, base_path + 'effective_area/fsi_effective_area_template.sav'
fsi_174_effective_area = read_ascii(base_path + 'effective_area/fsi_174_effective_area.txt', template=fsi_template)


; Some statistics
integrated_effective_area = int_tabulated(solar_spectrum.wavelength, effective_area)
main_bandpass_indices = where(solar_spectrum.wavelength GE 15 AND solar_spectrum.wavelength LE 25)
integrated_effective_area_main_bandpass = int_tabulated(solar_spectrum.wavelength[main_bandpass_indices], effective_area[main_bandpass_indices])
suvi_171_integrated = int_tabulated(suvi_171_effective_area.wavelength[1:-1], suvi_171_effective_area.effective_area[1:-1])
suvi_195_integrated = int_tabulated(suvi_195_effective_area.wavelength, suvi_195_effective_area.effective_area)
fsi_integrated = int_tabulated(fsi_174_effective_area.wavelength_nm[1:-1], fsi_174_effective_area.effective_area_cm2[1:-1])

; Push spectrum through effective area and detector
irradiance = solar_spectrum.irradiance * 1e-2^2 ; converts W/m2/nm to W/cm2/nm = J/s/cm2/nm
irradiance_photons = irradiance / (h*c / (solar_spectrum.wavelength * 1e-9)) ; [photons/s/cm2/nm] -- TODO: should the /nm be going away somehow here too?
instrument_response = reform(irradiance_photons * exposure_time * effective_area * quantum_efficiency * quantum_yield) ; [electrons/nm]

; Get per pixel response as well
radiance = irradiance_photons / 2.16E-5 ; [photons/s/cm2/nm/sr]
radiance = radiance * 5.42E-10 ; [photons/s/cm2/nm/pixel] (plate scale is 4.8 arcsec/pixel = 5.42E-10 sr/pixel)
instrument_response_per_pixel = reform(radiance * exposure_time * effective_area * quantum_efficiency * quantum_yield) ; [electrons/nm/pixel]
in_band_indices = where(solar_spectrum.wavelength GE 17 AND solar_spectrum.wavelength LE 20, complement=out_of_band_indices)
short_indices = where(solar_spectrum.wavelength LT 17)
long_indices = where(solar_spectrum.wavelength GT 20)
instrument_response_per_pixel_in_band = int_tabulated(solar_spectrum.wavelength[in_band_indices], instrument_response_per_pixel[in_band_indices]) ; [electrons/pixel]
instrument_response_per_pixel_short = int_tabulated(solar_spectrum.wavelength[short_indices], instrument_response_per_pixel[short_indices]) ; [electrons/pixel]
instrument_response_per_pixel_long = int_tabulated(solar_spectrum.wavelength[long_indices], instrument_response_per_pixel[long_indices]) ; [electrons/pixel]
instrument_response_per_pixel_out_of_band = instrument_response_per_pixel_short + instrument_response_per_pixel_long

; Create plots
p1 = plot(solar_spectrum.wavelength, effective_area, thick=2, font_size=16, $ 
          xtitle='wavelength [nm]', /XLOG, xrange=[10, 2500],$
          ytitle='effective area [cm$^2$]', yrange=[-0.1, 1.2], $
          title='SunCET baseline config')
t1 = text(0.6, 0.8, 'integral = ' + JPMPrintNumber(integrated_effective_area), font_size=16)
p1a = plot(p1.xrange, [0, 0], '--', color='tomato', /OVERPLOT)

p2 = plot(solar_spectrum.wavelength, effective_area, thick=2, font_size=16, $
          xtitle='wavelength [nm]', xrange=[15, 25],$
          ytitle='effective area [cm$^2$]', yrange=[-0.1, 1.2], $
          title='SunCET baseline config')
t2 = text(0.9, 0.8, 'SunCET integral = ' + JPMPrintNumber(integrated_effective_area_main_bandpass), font_size=16, alignment=1)
p2a = plot(suvi_171_effective_area.wavelength, suvi_171_effective_area.effective_area, color='grey', '--', /OVERPLOT)
p2b = plot(suvi_195_effective_area.wavelength, suvi_195_effective_area.effective_area, color='grey', '--', /OVERPLOT)
t2a = text(0.9, 0.75, 'GOES/SUVI 171 integral = ' + JPMPrintNumber(suvi_171_integrated), color='grey', font_size=16, alignment=1)
t2b = text(0.9, 0.70, 'GOES/SUVI 195 integral = ' + JPMPrintNumber(suvi_195_integrated), color='grey', font_size=16, alignment=1)
p2c = plot(fsi_174_effective_area.wavelength_nm, fsi_174_effective_area.effective_area_cm2, color='purple', '--', thick=4, /OVERPLOT)
t2c = text(0.9, 0.65, 'SolO/FSI integral = ' + JPMPrintNumber(fsi_integrated), color='purple', font_size=16, alignment=1)
p2z = plot(p2.xrange, [0, 0], '--', color='tomato', /OVERPLOT)


p3 = plot(solar_spectrum.wavelength, instrument_response, thick=2, font_size=16, $
          xtitle='wavelength [nm]', /XLOG, xrange=[ 10, 2500],$
          ytitle='instrument response [electrons/nm]', /YLOG, yrange=[-1e5, 2e12], $
          title='solar spectrum through SunCET in baseline config')

p4 = plot(solar_spectrum.wavelength, instrument_response_per_pixel, thick=2, font_size=16, $
          xtitle='wavelength [nm]', /XLOG, xrange=[10, 2500],$
          ytitle='instrument response [electrons/nm/pixel]', /YLOG, yrange=[1e-10, 1e10], $
          title='solar spectrum through SunCET in baseline config')
p4a = polygon([17, 17, 20, 20], [p4.yrange[0], p4.yrange[1], p4.yrange[1], p4.yrange[0]], /DATA, /FILL_BACKGROUND, fill_color='dodger blue', fill_transparency=70)
t4a = text(0.9, 0.80, 'in-band integrated response = ' + JPMPrintNumber(instrument_response_per_pixel_in_band, /NO_DECIMALS) + ' electrons/pixel', font_size=10, alignment=1, color='dodger blue')
t4b = text(0.9, 0.75, 'out-of-band integrated response = ' + JPMPrintNumber(instrument_response_per_pixel_out_of_band, /NO_DECIMALS) + ' electrons/pixel', font_size=10, alignment=1)
t4c = text(0.9, 0.70, 'ratio = ' + JPMPrintNumber(instrument_response_per_pixel_in_band/instrument_response_per_pixel_out_of_band, /NO_DECIMALS) + 'x', font_size=10, alignment=1)


STOP

END