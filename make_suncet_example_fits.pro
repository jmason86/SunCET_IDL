PRO make_suncet_example_fits

restore, getenv('SunCET_base') + 'mhd/dimmest/rendered_euv_maps/euv_sim_300.sav'


header = ["SIMPLE  =                    T / Written by IDL:  Wed Feb  8 20:18:32 2017", $
"BITPIX  =                  -64 /Real*8 (double precision)", $
"NAXIS   =                    2 / ", $
"NAXIS1  =                 4096 / ", $
"NAXIS2  =                 4096 / ", $
"DATE_OBS= '2017-02-08T18:00:45.35' / ", $
"BLD_VERS= 'V8R12X  '           / ", $
"LVL_NUM =        1.50000000000 / ", $
"T_REC   = '2017-02-08T18:00:46Z' / ", $
"TRECSTEP=        1.00000000000 / ", $
"TRECEPOC= '1977.01.01_00:00:00_TAI' / ", $
"TRECROUN=                    1 / ", $
"ORIGIN  = 'suncet     '           / ", $
"DATE    = '2017-02-08T18:05:21' / ", $
"TELESCOP= 'suncet     '           / ", $
"INSTRUME= 'suncet_3   '           / ", $
"DATE-OBS= '2017-02-08T18:00:45.35' / ", $
"T_OBS   = '2017-02-08T18:00:46.35Z' / ", $
"CAMERA  =                    3 / ", $
"IMG_TYPE= 'LIGHT   '           / ", $
"EXPTIME =        1.99957400000 / ", $
"EXPSDEV =    0.000157000000000 / ", $
"INT_TIME=        2.27343800000 / ", $
"WAVELNTH=                  193 / ", $
"WAVEUNIT= 'angstrom'           / ", $
"WAVE_STR= '193_THIN'           / ", $
"FSN     =            145672904 / ", $
"FID     =                    0 / ", $
"QUALLEV0=                    0 / ", $
"QUALITY =           1073741824 / ", $
"TOTVALS =             16777216 / ", $
"DATAVALS=             16777216 / ", $
"MISSVALS=                    0 / ", $
"PERCENTD=              100.000 / ", $
"DATAMIN =                  -39 / ", $
"DATAMAX =                 4412 / ", $
"DATAMEDN=                  129 / ", $
"DATAMEAN=              148.769 / ", $
"DATARMS =          7.98257E+08 / ", $
"DATASKEW=              3.00825 / ", $
"DATAKURT=              22.9500 / ", $
"DATACENT=              168.360 / ", $
"DATAP01 =              0.00000 / ", $
"DATAP10 =              5.00000 / ", $
"DATAP25 =              12.0000 / ", $
"DATAP75 =              226.000 / ", $
"DATAP90 =              332.000 / ", $
"DATAP95 =              432.000 / ", $
"DATAP98 =              590.000 / ", $
"DATAP99 =              737.000 / ", $
"NSATPIX =                    0 / ", $
"OSCNMEAN= '-nan    '           / ", $
"OSCNRMS = '-nan    '           / ", $
"FLAT_REC= 'suncet.flatfield[:#439]' / ", $
"NSPIKES =                17723 / ", $
"CTYPE1  = 'HPLN-TAN'           / ", $
"CUNIT1  = 'arcsec  '           / ", $
"CRVAL1  =        0.00000000000 / ", $
"CDELT1  =       0.600000023842 / ", $
"CRPIX1  =        2048.50000000 / ", $
"CTYPE2  = 'HPLT-TAN'           / ", $
"CUNIT2  = 'arcsec  '           / ", $
"CRVAL2  =        0.00000000000 / ", $
"CDELT2  =       0.600000023842 / ", $
"CRPIX2  =        2048.50000000 / ", $
"CROTA2  =        0.00000000000 / ", $
"R_SUN   =        1621.64452389 / ", $
"MPO_REC = 'suncet.master_pointing[:#999]' / ", $
"INST_ROT=      0.0193270000000 / ", $
"IMSCL_MP=       0.599489000000 / ", $
"X0_MP   =        2054.90991200 / ", $
"Y0_MP   =        2045.50000000 / ", $
"ASD_REC = 'suncet.lev0_asd_0004[:#55434668]' / ", $
"SAT_Y0  =       -3.42823600000 / ", $
"SAT_Z0  =        12.5083930000 / ", $
"SAT_ROT =   -5.70000000000E-05 / ", $
"ACS_MODE= 'SCIENCE '           / ", $
"ACS_ECLP= 'NO      '           / ", $
"ACS_SUNP= 'YES     '           / ", $
"ACS_SAFE= 'NO      '           / ", $
"ACS_CGT = 'GT3     '           / ", $
"ORB_REC = 'suncet.fds_orbit_vectors[2017.02.08_18:00:00_UTC]' / ", $
"DSUN_REF=        149597870691. / ", $
"DSUN_OBS=        147546548961. / ", $
"RSUN_REF=        696000000.000 / ", $
"RSUN_OBS=        972.986753000 / ", $
"GAEX_OBS=        26173649.7400 / ", $
"GAEY_OBS=       -27772526.2600 / ", $
"GAEZ_OBS=        17912769.8300 / ", $
"HAEX_OBS=       -112927253000. / ", $
"HAEY_OBS=        94960093777.0 / ", $
"HAEZ_OBS=        15168998.8100 / ", $
"OBS_VR  =       -861.212712000 / ", $
"OBS_VW  =        27925.7455330 / ", $
"OBS_VN  =       -3477.21656200 / ", $
"CRLN_OBS=        333.384033000 / ", $
"CRLT_OBS=       -6.51698800000 / ", $
"CAR_ROT =                 2187 / ", $
"HGLN_OBS=        0.00000000000 / ", $
"HGLT_OBS=       -6.51698800000 / ", $
"ROI_NWIN=          -2147483648 / ", $
"ROI_SUM =          -2147483648 / ", $
"ROI_NAX1=          -2147483648 / ", $
"ROI_NAY1=          -2147483648 / ", $
"ROI_LLX1=          -2147483648 / ", $
"ROI_LLY1=          -2147483648 / ", $
"ROI_NAX2=          -2147483648 / ", $
"ROI_NAY2=          -2147483648 / ", $
"ROI_LLX2=          -2147483648 / ", $
"ROI_LLY2=          -2147483648 / ", $
"PIXLUNIT= 'DN      '           / ", $
"DN_GAIN =              17.7000 / ", $
"EFF_AREA=              2.36000 / ", $
"EFF_AR_V=              3.00000 / ", $
"TEMPCCD = 'nan     '           / ", $
"TEMPGT  = 'nan     '           / ", $
"TEMPSMIR= 'nan     '           / ", $
"TEMPFPAD= 'nan     '           / ", $
"ISPSNAME= 'suncet.lev0_isp_0011'  / ", $
"ISPPKTIM= '2017-02-08T18:00:42.51Z' / ", $
"ISPPKTVN= '001.197 '           / ", $
"AIVNMST =                  453 / ", $
"AIMGOTS =           1865268083 / ", $
"ASQHDR  =        2293156552.00 / ", $
"ASQTNUM =                    2 / ", $
"ASQFSN  =            145672904 / ", $
"suncetHFSN =            145672896 / ", $
"AECDELAY=                 1539 / ", $
"suncetECTI =                    0 / ", $
"suncetSEN  =                    0 / ", $
"AIFDBID =                  241 / ", $
"AIMGOTSS=                 5770 / ", $
"AIFCPS  =                    6 / ", $
"AIFTSWTH=                    0 / ", $
"AIFRMLID=                 3255 / ", $
"AIFTSID =                40960 / ", $
"AIHISMXB=                    7 / ", $
"AIHIS192=                    0 / ", $
"AIHIS348=              3059552 / ", $
"AIHIS604=              7895581 / ", $
"AIHIS860=              8388608 / ", $
"AIFWEN  =                  204 / ", $
"AIMGSHCE=                 2000 / ", $
"AECTYPE =                    0 / ", $
"AECMODE = 'ON      '           / ", $
"AISTATE = 'CLOSED  '           / ", $
"suncetECENF=                    1 / ", $
"AIFILTYP=                    0 / ", $
"AIMSHOBC=        41.1080020000 / ", $
"AIMSHOBE=        26.0960010000 / ", $
"AIMSHOTC=        55.3040010000 / ", $
"AIMSHOTE=        69.2839970000 / ", $
"AIMSHCBC=        2040.77197300 / ", $
"AIMSHCBE=        2025.85595700 / ", $
"AIMSHCTC=        2054.83593800 / ", $
"AIMSHCTE=        2068.62402300 / ", $
"AICFGDL1=                    0 / ", $
"AICFGDL2=                  137 / ", $
"AICFGDL3=                  201 / ", $
"AICFGDL4=                  236 / ", $
"AIFOENFL=                    1 / ", $
"AIMGFSN =                    5 / ", $
"AIMGTYP =                    0 / ", $
"suncetWVLEN=                    7 / ", $
"suncetGP1  =                    0 / ", $
"suncetGP2  =                    0 / ", $
"suncetGP3  =                    0 / ", $
"suncetGP4  =                    0 / ", $
"suncetGP5  =                    0 / ", $
"suncetGP6  =                    0 / ", $
"suncetGP7  =                    0 / ", $
"suncetGP8  =                  393 / ", $
"suncetGP9  =                  457 / ", $
"suncetGP10 =                  748 / ", $
"AGT1SVY =                   -6 / ", $
"AGT1SVZ =                   -4 / ", $
"AGT2SVY =                   -8 / ", $
"AGT2SVZ =                  -14 / ", $
"AGT3SVY =                    2 / ", $
"AGT3SVZ =                    0 / ", $
"AGT4SVY =                   59 / ", $
"AGT4SVZ =                  119 / ", $
"AIMGSHEN=                    4 / ", $
"KEYWDDOC= 'http:   '           / ", $
"RECNUM  =            129636832 / ", $
"BLANK   =               -32768 / ", $
"CHECKSUM= 'ZRVoiOSnZOSnfOSn'   / HDU checksum updated 2017-02-09T03:18:33/ ", $
"DATASUM = '4087348687'         / data unit checksum updated 2017-02-09T03:18:33/ ", $
"COMMENT FITS (Flexible Image Transport System) format is defined in 'Astronomy/ ", $
"COMMENT and Astrophysics', volume 376, page 359; bibcode: 2001A&A...376..359H/ ", $
"COMMENT FITSHEAD2STRUCT/ ", $
"HISTORY FITSHEAD2STRUCT run at: Wed Feb  8 20:18:31 2017/ ", $
"HISTORY mreadfits_shm VERSION:  1.20/ ", $
"HISTORY read_suncet VERSION:  2.10/ ", $
"HISTORY suncet2wcsmin.pro VERSION:  5.10/ ", $
"HISTORY suncet2wcsmin/ ", $
"HISTORY suncet2wcsmin  MPO_date: 2017-02-07T01:25:35Z/ ", $
"HISTORY suncet2wcsmin  MPO_t_start: 2017-02-05T00:00:00Z/ ", $
"HISTORY suncet2wcsmin  MPO_t_stop: 2018-02-05T00:00:00Z/ ", $
"HISTORY suncet2wcsmin  MPO_version: 0/ ", $
"HISTORY ssw_reg.pro VERSION:  1.30/ ", $
"HISTORY ssw_reg/ ", $
"HISTORY ssw_reg  ROT called with cubic interpolation: cubic = -0.500000/ ", $
"HISTORY ssw_reg  Image registered to sun center, roll 0, and platescale = 0.6 ar/ ", $
"HISTORY suncet_fix_header.pro VERSION:  1.00/ ", $
"HISTORY suncet_prep.pro VERSION:  5.10/ ", $
"HISTORY suncet_reg.pro VERSION:  1.20/ ", $
"XCEN    =        0.00000000000 // ", $
"YCEN    =        0.00000000000 // ", $
"END/ "]

writefits, getenv('SunCET_base') + 'MHD/dimmest/rendered_euv_maps/euv_sim_300_193A.fits', rendered_maps[*, *, 6], header

END
