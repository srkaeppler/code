pro rt_new

spawn, 'echo /davit/lib/vt/fort/rtnew/Inputs_tpl.inp > inp_file'
spawn, '/davit/lib/vt/fort/rtnew/raydarn < inp_file'

r = 0.
theta = 0.
r0 = 0.
theta0 = 0.
grpran = 0.
ranelev = 0.
h = 0.
dum = 0L

clear_page
Rav = 6370.
maxr = 2000.
maxh = 500.
tht0 = maxr/Rav/2.
xmin = -(Rav + maxh) * sin (tht0)
xmax = (Rav + maxh) * sin (tht0)
xran = [xmin, xmax*1.01]
ymin = Rav * cos (tht0)
ymax = Rav + maxh
yran = [ymin, ymax*1.01]
plot, xran, yran, /nodata, xstyle=5, ystyle=5, /iso, position=[.1,.2,.9,.8]

rt_new_edens, theta=thetaNe, edens=edens

nl = 500
dalt = 1.
dthet = 5.
dens_range = [10., 12.]
for i=0,nl-2 do begin
	if thetaNe[i] lt maxr/Rav then begin
		for j=0,nl-2 do begin
			if 60. + j*dalt le maxh then begin
				alt = 60. + j*dalt
				xx = [(Rav+alt)*sin(-tht0 + thetaNe[i]), (Rav+alt)*sin(-tht0 + thetaNe[i+1]), $
					(Rav+alt+dalt)*sin(-tht0 + thetaNe[i+1]), (Rav+alt+dalt)*sin(-tht0 + thetaNe[i])]

				yy = [(Rav+alt)*cos(-tht0 + thetaNe[i]), (Rav+alt)*cos(-tht0 + thetaNe[i+1]), $
					(Rav+alt+dalt)*cos(-tht0 + thetaNe[i+1]), (Rav+alt+dalt)*cos(-tht0 + thetaNe[i])]

		; 		xx = [(Rav+alt)*sin(-tht0 + i*tht0/dthet), (Rav+alt)*sin(-tht0 + (i+1)*tht0/dthet), $
		; 			(Rav+alt+dalt)*sin(-tht0 + (i+1)*tht0/dthet), (Rav+alt+dalt)*sin(-tht0 + i*tht0/dthet)]
		; 
		; 		yy = [(Rav+alt)*cos(-tht0 + i*tht0/dthet), (Rav+alt)*cos(-tht0 + (i+1)*tht0/dthet), $
		; 			(Rav+alt+dalt)*cos(-tht0 + (i+1)*tht0/dthet), (Rav+alt+dalt)*cos(-tht0 + i*tht0/dthet)]

				cols = bytscl(alog10(edens[j,i]), min=dens_range[0], max=dens_range[1], top=255) + byte(2)

				polyfill, xx, yy, color=cols, noclip=0
			endif
		endfor
	endif
endfor

openr, unit, 'rays.dat', /get_lun

while ~eof(unit) do begin

	readu, unit, dum, r0, theta0, grpran, ranelev, h, dum
	if r0 eq 9999.99 then begin
		r = Rav
		theta = 0.
		grpran = 0.
	endif else begin
		oplot, [r*1e-3*sin(-tht0 + theta), r0*1e-3*sin(-tht0 + theta0)], $
				[r*1e-3*cos(-tht0 + theta), r0*1e-3*cos(-tht0 + theta0)], thick=2
		r = r0
		theta = theta0
; 		print, r0*1e-3-Rav, theta0, grpran*1e-3, ranelev, h*1e-3
	endelse
endwhile

free_lun, unit

oplot, [-Rav*sin(tht0),xmin], [ymin, (Rav+maxh)*cos(tht0)], thick=2
oplot, [Rav*sin(tht0),xmax], [ymin, (Rav+maxh)*cos(tht0)], thick=2

thetas = -tht0 + findgen(101)*(2.*tht0)/100.
oplot, Rav*sin(thetas), Rav*cos(thetas), thick=2
oplot, (Rav+maxh)*sin(thetas), (Rav+maxh)*cos(thetas), thick=2

vline = 100.
for nl=0,4 do begin
	oplot, (Rav+vline)*sin(thetas), (Rav+vline)*cos(thetas), thick=2, linestyle=2
	vline += 100.
endfor

hline = 500.
for nl=0,4 do begin
	oplot, [Rav*sin(-tht0 + hline/Rav),(Rav+maxh)*sin(-tht0 + hline/Rav)], $
			[Rav*cos(-tht0 + hline/Rav), (Rav+maxh)*cos(-tht0 + hline/Rav)], thick=2, linestyle=2
	hline += 500.
endfor

end