pro	dst_rad_plot

nlines = file_lines('~/Documents/IDL/milh/dst.dat')
openr, unit, '~/Documents/IDL/milh/dst.dat', /get_lun
format = '(3x,2I2,x,I2,4x,I2,4x,24I4,4x,I2)'

juls = dblarr(nlines*24)
dst = intarr(nlines*24)
ev = intarr(nlines)

tdst = intarr(24)
nl = 0L
while ~eof(unit) do begin
    readf, unit, year2, month, day, year1, tdst, tev, format=format
    juls[nl*24:(nl*24+23)] = julday(month, day, year1*100L+year2, indgen(24))
    dst[nl*24:(nl*24+23)] = tdst
    ev[nl] = tev
    nl++
endwhile
free_lun, unit

clear_page
loadct, 9
position = define_panel(1,1,0,0)
xrange = [juls[0],juls[nlines*24-1]]
yrange = [-200,100]

plot, [0,0], /nodata, xstyle=5, ystyle=5, $
    yrange=yrange, xrange=xrange, position=position

for n=0,nl-1 do begin
    if ev[n] eq 1 then begin
	POLYFILL,[juls[n*24],juls[n*24],juls[n*24+23],juls[n*24+23]], $
		[-200,100,100,-200], $
		COL=220,NOCLIP=0
    endif
endfor

dum = label_date(date_format='%D')
plot, juls[0:(nl-1)*24], dst[0:(nl-1)*24], $
    xrange=xrange, yrange=yrange, charsize=1, $
    xtickformat='label_date', xstyle=9, ytitle='DST [nT]', $
    xtickunits='days', ystyle=1, xtitle='Date', $
    position=position, nsum=2, ticklen=1, xtickinterval=10
axis, xaxis=1, xstyle=1, xrange=xrange, $ 
    xtitle='Month', xtickunits='Months', xminor=1

end