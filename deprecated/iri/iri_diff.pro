pro iri_diff, date, times, ps=ps, scale=scale

base = '~/Desktop/'

parse_date, date, day, month, year
parse_time, times[0], hour0, minutes0
parse_time, times[1], hour1, minutes1

; Longitude
lonbeg = -180.
lonend = 180.
lonstp = 2.
nlons = fix((lonend - lonbeg)/lonstp)
; Latitude
latbeg = -88.
latend = 88.
latstp = 2.
nlats = fix((latend-latbeg)/latstp)

thmf2 = fltarr(nlats+1, nlons+1)
tnmf2 = fltarr(nlats+1, nlons+1)
tnel = fltarr(nlats+1, nlons+1)
hmf2 = fltarr(nlats+1, nlons+1)
nmf2 = fltarr(nlats+1, nlons+1)
nel = fltarr(nlats+1, nlons+1)
lats = latbeg + findgen(nlats+1)*latstp
lons = lonbeg + findgen(nlons+1)*lonstp

openr, unit, base+'IRI_'+STRTRIM(date,2)+'_'+STRTRIM(times[0],2)+'.dat', /get_lun
readu, unit, nlats, nlons
readu, unit, thmf2, tnmf2, tnel
free_lun, unit

openr, unit, base+'IRI_'+STRTRIM(date,2)+'_'+STRTRIM(times[1],2)+'.dat', /get_lun
readu, unit, nlats, nlons
readu, unit, hmf2, nmf2, nel
free_lun, unit

hmf2 = hmf2 - thmf2
nmf2 = nmf2 - tnmf2
nel = nel - tnel

zdata = nmf2

if keyword_set(ps) then $
	ps_open, base+'IRI_'+STRTRIM(date,2)+'_diff.ps', /no_init

ymaps = 1
charsize = get_charsize(1,ymaps)

legend = 'NmF!I2!N [10!E11!Nm!E-3!N]'
title = 'IRI - '+STRTRIM(month,2)+'/'+STRTRIM(day,2)+'/'+STRTRIM(year,2)+', ' $
	+STRTRIM(string(hour1,format='(I02)'),2)+':'+STRTRIM(string(minutes1,format='(I02)'),2)+'-' $
	+STRTRIM(string(hour0,format='(I02)'),2)+':'+STRTRIM(string(minutes0,format='(I02)'),2)+'LT'
; if ~keyword_set(scale) then $
; 	scale = [-ceil(max(alog10(abs(nel)))*10L)/10.,ceil(max(alog10(abs(nel)))*10L)/10.]
if ~keyword_set(scale) then $
	scale = [-ceil(max(abs(zdata))*10L)/10.,ceil(max(abs(zdata))*10L)/10.]
print, scale
clear_page
position = define_panel(1, ymaps, 0, 0, /bar, /no_title)
bpos = define_cb_position(position, /vertical, gap=0.01, width=0.02)
MAP_SET, /cylindrical, /noerase, charsize=charsize, $
	position=position, title=title, $
	limit=[-90.,-180.,90.,180.]

for ilat=0,nlats do begin
    slat = lats[ilat] - latstp/2.
    blat = lats[ilat] + latstp/2.
	for ilon=0,nlons do begin
		slon = lons[ilon] - lonstp/2.
		blon = lons[ilon] + lonstp/2.
		
; 		col = bytscl(nel[ilat,ilon]/abs(nel[ilat,ilon])*alog10(abs(nel[ilat,ilon])), min=scale[0], max=scale[1], top=252) + 2
		col = bytscl(zdata[ilat,ilon], min=scale[0], max=scale[1], top=252) + 2
		
		; finally plot the point
		POLYFILL,[slon,slon,blon,blon], [slat,blat,blat,slat], $
			COL=col,NOCLIP=0
	endfor
endfor

MAP_CONTINENTS, /coast, /NOERASE
MAP_GRID, charsize=charsize, color=255., $
	letdel=30., londel=60., /label
plot_colorbar, /vert, charthick=2, /bar, /continuous, /no_rotate, $
	scale=scale, position=bpos, charsize=charsize, $
	legend=legend, level_format='(F5.2)', nlevels=4

if keyword_set(ps) then $
	ps_close, /no_init


end