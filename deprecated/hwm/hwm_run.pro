pro	hwm_run, date, glat, glon, alt=alt

cd, '~/Documents/Research/HWM/HWM07'

if ~keyword_set(alt) then $
    alt = 100.

sfjul, date, [0,0], sjul, fjul, no_hours=nhrs
juls = sjul + dindgen(nhrs)/24.d

parse_date, date, year, month, day
iyd = year*1000L + day_no(date)

shourut = abs(0. - glon/15.)
ssec = shourut*3600.
fhourut = shourut
fsec = fhourut*3600.
hrstp = 1.
secstp = hrstp*3600.

; Execute hwm code
input = STRTRIM(iyd,2)+',0,'+STRTRIM(alt,2)+','+STRTRIM(glat,2)+','+STRTRIM(glon,2)+','+ $
    STRTRIM(ssec,2)+','+STRTRIM(fsec,2)+','+STRTRIM(secstp,2)+',1'
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

wm = twm[0:FIX(nhrs)-1]
wz = twz[0:FIX(nhrs)-1]

clear_page
plot, juls, wm, $
    xtitle='Time [LT]', xtickformat='label_date', $
    ytitle='Wind speed [m/s]', $
    xrange=[sjul,fjul], yrange=[-50.,80.], $
    xstyle=1, ystyle=1, $
    xtickinterval=4.d/24.d, xminor=4., $
    charsize=1., title=format_date(date,/human)
oplot, juls, wz, linestyle=2

end