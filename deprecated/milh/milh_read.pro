; Read binary file with Madrigal data
PRO	milh_read, exdate, nlines, juls, alt, az, el, range, lat, lon, ti, te, nel, vo, dti, dtr, dnel, dvo

if ~FILE_TEST('~/Documents/IDL/milh/milh_data_idl'+strtrim(exdate,2)+'.dat',/READ) then $
	milh_read_to_idl, exdate

openr, unit, '~/Documents/IDL/milh/milh_data_idl.dat', /get_lun
; read number of lines in data arrays
nlines = 0L
readu, unit, nlines 
; Create data buffers
juls = dindgen(nlines)
az = findgen(nlines)
el = findgen(nlines)
range = findgen(nlines)
alt = findgen(nlines)
lat = findgen(nlines)
lon = findgen(nlines)
ti = findgen(nlines)
tr = findgen(nlines)
te = findgen(nlines)
nel = findgen(nlines)
vo = findgen(nlines)
dti = findgen(nlines)
dtr = findgen(nlines)
dte = findgen(nlines)
dnel = findgen(nlines)
dvo = findgen(nlines)
; Read data
readu, unit, juls, alt, az, el, range, lat, lon, ti, tr, nel, vo, dti, dtr, dnel, dvo
free_lun, unit

te = ti*tr
nel = ALOG10(nel)


END