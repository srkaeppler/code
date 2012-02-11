pro	map_rmax, date, time, ps=ps

common rt_data_blk

; base = '~/Documents/Research/NRL/'
base = '~/Desktop/'

; Longitude
lonbeg = -180.
lonend = 180.
lonstp = 5.
nlons = fix((lonend - lonbeg)/lonstp)
; Latitude
latbeg = -70.
latend = 70.
latstp = 5.
nlats = fix((latend-latbeg)/latstp)

hmax = fltarr(nlats+1, nlons+1)
nmax = fltarr(nlats+1, nlons+1)
elmax = fltarr(nlats+1, nlons+1)
lats = latbeg + findgen(nlats+1)*latstp
lons = lonbeg + findgen(nlons+1)*lonstp

for ilat=0,nlats do begin
	for ilon=0,nlons do begin
		geopos = [lats[ilat], lons[ilon], 90.]
		rt_run, date, 'custom', time=time, sti='LT', geopos=geopos;, /force
		rt_get_hmax, time, hmax=hm, nmax=nm
		hmax[ilat,ilon] = hm
		nmax[ilat,ilon] = nm
	endfor
endfor


openw, unit, '~/Desktop/rtmax.dat', /get_lun
writeu, unit, hmax, nmax
free_lun, unit

openr, unit, '~/Desktop/rtmax.dat', /get_lun
readu, unit, hmax, nmax
free_lun, unit


h0 = where(hmax gt 0.)

if keyword_set(ps) then $
	ps_open, base+'RT_'+STRTRIM(date,2)+'_'+STRTRIM(time,2)+'.ps', /no_init

parse_date, date, year, month, day
parse_time, time,  hour, minutes

legend = 'h!Imax!N [km]'
scale = [fix(min(hmax[h0])/10L)*10.,fix(max(hmax[h0])/10L)*10.]
; print, scale
set_format, /portrait, /sardines, /tokyo
clear_page
position = define_panel(1, 2, 0, 0, /bar, /no_title)
bpos = define_cb_position(position, /vertical, gap=0.01, width=0.02)
charsize = get_charsize(1,2)
title = 'Ray-tracing - '+STRTRIM(month,2)+'/'+STRTRIM(day,2)+'/'+STRTRIM(year,2)+', ' $
	+STRTRIM(string(hour,format='(I02)'),2)+':'+STRTRIM(string(minutes,format='(I02)'),2)+'LT'
MAP_SET, /cylindrical, title=title, /noerase, charsize=charsize, $
	/continents, position=position, $
	limit=[-90.,-180.,90.,180.]

for ilat=0,nlats do begin
    slat = lats[ilat] - latstp/2.
    blat = lats[ilat] + latstp/2.
	for ilon=0,nlons do begin
		slon = lons[ilon] - lonstp/2.
		blon = lons[ilon] + lonstp/2.
		
		if hmax[ilat,ilon] gt 0. then begin
			col = bytscl(hmax[ilat,ilon], min=scale[0], max=scale[1], top=252) + 2
		
			; finally plot the point
			POLYFILL,[slon,slon,blon,blon], [slat,blat,blat,slat], $
				COL=col,NOCLIP=0
		endif
	endfor
endfor

MAP_CONTINENTS, /coast, /NOERASE
MAP_GRID, charsize=charsize, color=255., $
	letdel=30., londel=60., /label
plot_colorbar, /vert, charthick=2, /bar, /continuous, /no_rotate, $
	scale=scale, position=bpos, charsize=charsize, $
	legend=legend, level_format='(F5.1)', nlevels=5

n0 = where(nmax gt 0.)

legend = 'N!Imax!N [m!E-3!N]'
; print, [transpose(hmax[h0]),transpose(nmax[h0])]
scale = [floor(min(alog10(nmax[n0]))*10L)/10.,ceil(max(alog10(nmax[n0]))*10L)/10.]
; print, scale
position = define_panel(1, 2, 0, 1, /bar, /no_title)
bpos = define_cb_position(position, /vertical, gap=0.01, width=0.02)
MAP_SET, /cylindrical, /noerase, charsize=charsize, $
	/continents, position=position, $
	limit=[-90.,-180.,90.,180.]

for ilat=0,nlats do begin
    slat = lats[ilat] - latstp/2.
    blat = lats[ilat] + latstp/2.
	for ilon=0,nlons do begin
		slon = lons[ilon] - lonstp/2.
		blon = lons[ilon] + lonstp/2.
		
		if nmax[ilat,ilon] gt 0. then begin
			col = bytscl(alog10(nmax[ilat,ilon]), min=scale[0], max=scale[1], top=252) + 2
			
			; finally plot the point
			POLYFILL,[slon,slon,blon,blon], [slat,blat,blat,slat], $
				COL=col,NOCLIP=0
		endif
	endfor
endfor

MAP_CONTINENTS, /coast, /NOERASE
MAP_GRID, charsize=charsize, color=255., $
	letdel=30., londel=60., /label
plot_colorbar, /vert, charthick=2, /bar, /continuous, /no_rotate, $
	scale=scale, position=bpos, charsize=charsize, $
	legend=legend, level_format='(F5.1)', nlevels=5

if keyword_set(ps) then $
	ps_close, /no_init

end