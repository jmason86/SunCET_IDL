;+
; NAME:
;   SuncetDetectorBloomingFromCsol
;
; PURPOSE:
;   Determine the magnitude (intensity) and extent (distance) of blooming around saturated pixels
;   in the Teledyne e2v CIS115 detector based on the images it took as part of the CSOL instrument
;   during the NASA EVE sounding rocket flight 33.336 in 2018
;
; INPUTS:
;   None (but require access to the raw data)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plots, images, quatifications on console
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires the CSOL processing code
;   Requires the CSOL data
;
; EXAMPLE:
;   Just run it!
;-
PRO SuncetDetectorBloomingFromCsol

; Defaults
dataloc = '/Users/jmason86/Dropbox/minxss_dropbox/rocket_eve_docs/36.336/TM_Data/Flight/CSOL_SDcard/'
saveloc = '/Users/jmason86/Dropbox/Research/ResearchScientist_LASP/Proposals/2020 SunCET Phase A CSR/Analysis/Detector Blooming/'

files = file_search(dataloc + '*.hex')

im = csol_hex2img(dataloc + 'FrameData_SDAddr_0211.hex', 1)
i1 = image(im, MARGIN=0, FONT_COLOR='white', DIMENSIONS=[2000, 1504])
t1 = text(0.5, 0.9, 'Frame 02' + strmid(files[-1], 108, 2), color='white', alignment=0.5, font_size=18)

STOP

movieObject = IDLffVideoWrite(saveloc + 'CSOL Flight.mp4')
xsize = 2000
ysize = 1504
fps = 3
bitrate = 1e7
vidStream = movieObject.AddVideoStream(xsize, ysize, fps, BIT_RATE = bitrate)

w = window(DIMENSIONS = [xsize, ysize], /DEVICE, /BUFFER)

FOREACH file, files DO BEGIN
  csol_image = csol_hex2img(file, 1)
  
  i1 = image(im, MARGIN=0, /CURRENT)
  t1 = text(0.5, 0.9, 'Frame 02' + strmid(file, 108, 2), color='white', alignment=0.5, font_size=18)
  timeInMovie = movieObject.Put(vidStream, w.CopyWindow()) ; time returned in seconds
  w.erase

ENDFOREACH
movieObject.Cleanup

END