pro	hwm_plot_map_old, ymaps, ymap, date, time, alt=alt, res=res

cd, '~/Documents/Research/HWM/HWM07'

if ~keyword_set(alt) then $
    alt = 100.
if ~keyword_set(res) then $
    res = 2.

sfjul, date, [0,0], sjul, fjul, no_hours=nhrs
juls = sjul + dindgen(nhrs)/24.d

parse_date, date, year, month, day
iyd = year*1000L + day_no(date)

parse_time, time, hour, minutes
hour = hour + minutes/60.
sec = hour*3600.

slon = 0.
flon = 360.
lonstp = res

nlats = 180./res
nlons = 360./res
lat = -90. + findgen(nlats+1)*res
lon = -180. + findgen(nlons+1)*res

wm = fltarr(nlons+1,nlats+1)
wz = fltarr(nlons+1,nlats+1)
scale = [-100.,100.]
wmin = scale[0]
wmax = scale[1]

; clear_page
xmaps = 2
; ymaps = 1
xmap = 0
; ymap = 0
; charsize = get_charsize(xmaps, ymaps)
charsize=.5
yrange = [-90.,90.]
xrange = [-180.,180.]

; Execute hwm code
glat = 90.
for nlat=1,nlats-1 do begin
    input = STRTRIM(iyd,2)+','+STRTRIM(sec,2)+','+STRTRIM(alt,2)+','+STRTRIM(glat,2)+','+STRTRIM(0.,2)+','+ $
	STRTRIM(slon,2)+','+STRTRIM(flon,2)+','+STRTRIM(lonstp,2)+',2'
    print, input
    spawn, 'rm inp_file'
    spawn, 'echo '+input+' >> inp_file'
    spawn, '/home/sebastien/Documents/Research/HWM/HWM07/hwmOUT < inp_file'


    twm = fltarr(500)
    twz = fltarr(500)
    openr, unit, 'hwm.dat', /get_lun
    readf, unit, twm, format='(500F8.3)'
    readf, unit, twz, format='(500F8.3)'
    free_lun, unit

    wm[*,nlat] = twm[0:nlons]
    wz[*,nlat] = twz[0:nlons]
    
    glat -= res
endfor
wm = shift(wm,nlons/2,0)
wz = shift(wz,nlons/2,0)

; igrf_plot, date, /pdec, /pdip
; velovect,wz[0:*:4,0:*:4],wm[0:*:4,0:*:4],lon[0:*:4],lat[0:*:4], /overplot

position = define_panel(xmaps, ymaps, xmap, ymap, /bar, with_info=with_info)
title = 'HWM07, meridional '+STRMID(STRTRIM(alt,2),0,3)+'km - '+format_date(date,/human)+' - '+STRMID(STRTRIM(hour,2),0,2)+'LT'
plot_map_data, wm, scale, $
    position=position, title=title, $
    legend=legend, charsize=charsize

position = define_panel(xmaps, ymaps, 1, ymap, /bar, with_info=with_info)
title = 'HWM07, zonal '+STRMID(STRTRIM(alt,2),0,3)+'km - '+format_date(date,/human)+' - '+STRMID(STRTRIM(hour,2),0,2)+'LT'
plot_map_data, wz, scale, $
    position=position, title=title, $
    legend=legend, charsize=charsize


end