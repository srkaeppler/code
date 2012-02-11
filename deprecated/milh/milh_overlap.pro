pro milh_overlap, azim=azim, elev=elev, radar=radar, date=date, time=time

common radarinfo

ps_open, '~/Desktop/milh_overlap.ps'

; Millstone Hill coords
mh_lat = 42.6195
mh_lon = 288.50827
mh_rho = 0.14600+get_re(mh_lat)

if ~keyword_set(date) then $
  get_date, date=date
if ~keyword_set(time) then $
  get_date, time=time
parse_date, date, year, month, day
parse_time, time, hr, mn
if ~keyword_set(elev) then $
  elev = 12.
if ~keyword_set(azim) then $
  azim = -90.
if ~keyword_set(radar) then $
  radar = 'bks'
nazim = n_elements(azim)+1
nelev = n_elements(elev)+1
nrad = n_elements(radar)+1
nbeams = 16

beams = indgen(nbeams)
beam_info = dblarr(nelev,nazim,nbeams,nrad,2)

jul = julday(month, day, year, hr, mn)


; map_plot_panel, jul=jul, coords='mlt', /no_fill, $
;   xrange=[-50,50], yrange=[-50,50]
; ; overlay radar fov and ISR beams stations
; overlay_fov, name=radar, jul=jul, coords='mlt', /no_fill, /grid
; overlay_isr, 'MSH', jul=jul, coord='mlt',azim=azim

; We will track the MH beam for 2000 km in 20 km increments
mh_beam_arr = dblarr(101,3)
mh_beam_arr(0,0) = mh_rho - get_re(mh_lat)
mh_beam_arr(0,1) = mh_lat
mh_beam_arr(0,2) = mh_lon

; Iterate through elv angles in 5 degree increments starting at 5.5
for e=0,nelev-2 do begin
  ; Iterate backwards through azimuths starting at -80 degrees in 1 degree steps
  for a=0,nazim-2 do begin
    ; Iterate through all possible ranges, 0 to 2000 km (track the MH beam)
    for r=1,100 do begin
      range = r*20.
      ; Find the elevation of MH beam at this range
      temp = get_newcoords(mh_lat,mh_lon,mh_rho,azim[a],range,elev=elev[e])
      ; Store the coords of the beam
      frho = temp[2]
      flat = temp[0]
      flon = temp[1]
      mh_beam_arr(r,0) = frho - get_re(flat)
      mh_beam_arr(r,1) = flat
      mh_beam_arr(r,2) = flon

      ; Go through Radars
      for rad=0,nrad-2 do begin
	for b=0,nbeams-1 do begin
	  for range=1,75 do begin
	    ; The the coordinated for r-b cell
	    stid = network[where(network.code[0] eq radar[rad])].ID
	    pos = rbpos(range,height=300,station=stid,beam=b,lagfr=1200,smsep=300,/CENTER,/GEO,YEAR=2020,YRSEC=1)
	    if (pos(1) lt 0.) then pos(1) = pos(1) + 360.
	    d = get_distance(flat,flon,pos(0),pos(1))
	    ; The the MH beam is cutting through a r-b cell
	    if((d lt beam_info(e,a,b,rad,0) OR beam_info(e,a,b,rad,0) eq 0) AND d lt 40.) then begin
	      beam_info(e,a,b,rad,0) = mh_beam_arr(r,0)
	      beam_info(e,a,b,rad,1) = r*20.
	    endif
	  endfor
	endfor
      endfor

    endfor
  endfor
endfor

;plot the data
loadct,0
for rad=0,nrad-2 do begin
  for a=0,nazim-2 do begin
    clear_page
    for e=0,nelev-2 do begin
      color = 250/(nelev-1)*e
      plot,beams,beam_info(e,a,*,rad,0),xticks=15,title=' azimuth = '+strtrim(azim[a],2),$
	    thick=4,charthick=4,xthick=4,ythick=4,ytitle='Altitude of MH beam (km)',xtitle='SuperDARN beam number',yrange=[100.,500.], $
	    color=color
      xyouts,12.,(450.-e*10.),'elevation = '+strtrim(elev[e],2),charthick=4,color=color
    endfor
    plot,[0,0],[0,0],xticks=15,title=' azimuth = '+strtrim(azim[a],2), xrange=[0,nbeams-1], $
	thick=4,charthick=4,xthick=4,ythick=4,ytitle='Altitude of MH beam (km)',xtitle='SuperDARN beam number',yrange=[100.,500.], $
	color=0
  endfor
endfor

ps_close

END