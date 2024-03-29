pro sd_global

common radarinfo

ps_open, '~/Desktop/sd_global.ps'

map_set, /robi, /iso
loadct, 0
map_continents, /countries, /fill_cont, color=150

ArLat = -90. + findgen(181)
ArLon = 1. + fltarr(n_elements(ArLat))

loadct, 33
for n=0,n_elements(ArLat)-2 do begin
	polyfill, ArLon[n]*120.+10.*[-1,1,1,-1], ArLat[n]*[1,1,0,0] + ArLat[n+1]*[0,0,1,1], col=150
	polyfill, ArLon[n]*(-60.)+10.*[-1,1,1,-1], ArLat[n]*[1,1,0,0] + ArLat[n+1]*[0,0,1,1], col=150
endfor

; Find radars
ajul = systime(/jul,/utc)
caldat, ajul, mm, dd, year
tval = TimeYMDHMSToEpoch(year, mm, dd, 12, 0, 0)
nrad = 0L
radarS = ['']
radarN = ['']
radarSlat = [0]
radarNlat = [0]
radIDN = [0]
radIDS = [0]
load_usersym, /circle
for ir=1,n_elements(network)-1 do begin
; 	if network[ir].status eq 0 then continue
	if tval lt network[ir].st_time then continue
	if tval gt network[ir].ed_time then continue
	for s=0,31 do begin
		if (network[ir].site[s].tval eq -1) then break
		if (network[ir].site[s].tval ge tval) then break
	endfor
	radarsite = network[ir].site[s]
	magpos = cnvcoord(radarsite.geolat, radarsite.geolon, 0.)
	if magpos[0] gt 50. or magpos[0] lt 0. then continue
	ngates = 75
	nbeams = radarsite.maxbeam
	yrsec = (ajul-julday(1,1,year,0,0,0))*86400.d
	rad_define_beams, network[ir].id, nbeams, ngates, year, yrsec, coords='geog', $
			/normal, fov_loc_full=fov_loc_full
	fovlats = [reform(fov_loc_full[0,0,0,*]), reform(fov_loc_full[0,0,*,ngates]), reverse(reform(fov_loc_full[0,0,nbeams,*])), reverse(reform(fov_loc_full[0,0,*,0]))]
	fovlons = [reform(fov_loc_full[1,0,0,*]), reform(fov_loc_full[1,0,*,ngates]), reverse(reform(fov_loc_full[1,0,nbeams,*])), reverse(reform(fov_loc_full[1,0,*,0]))]
	plots, radarsite.geolon, radarsite.geolat, psym=8, symsize=.5
	loadct, 33
	if (network[ir].status ne 0) or (network[ir].code[0] eq 'azw' or network[ir].code[0] eq 'aze' or network[ir].code[0] eq 'aiw' or network[ir].code[0] eq 'aie') then $
		polyfill, fovlons, fovlats, col=100 $
	else $
		polyfill, fovlons, fovlats, col=180 
	loadct, 0
	oplot, fovlons, fovlats
endfor
loadct, 0
map_grid, /hori
map_continents, /countries, /continents
oplot, ArLon*120.+10., ArLat
oplot, ArLon*120.-10., ArLat
oplot, ArLon*(-60.)+10., ArLat
oplot, ArLon*(-60.)-10., ArLat

ps_close, /no_f

end