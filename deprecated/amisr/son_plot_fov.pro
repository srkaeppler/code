pro	son_plot_fov

;ps_open, '~/Desktop/son_fov_data.ps'

son_pos = [67., 309.]
son_pos_map = calc_stereo_coords(son_pos[0], son_pos[1])
date = 20110720
time = 400
parse_time, time, hour, minute
ut0 = hour + minute/60.
rotate = ut0*360./24.
lim = 31.
; scale = [1e10, 3e11]*1e-11
scale = [-600., 600.]

son_read, lat=lats, lon=lons, nel=nel, ut=ut, alt=alt, vo=vo

siz = size(lats)
nt = siz[1]
nalt = siz[2]

ialts = where(alt ge 340. and alt le 360., cc)
jalts = ialts[0:cc-2]

map_plot, date=date, time=time, coords='geog', /no_coast, xrange=[-lim,lim], yrange=[-lim,lim], $
	rotate=(hour + minute/60.)*360./24.

tmp = calc_stereo_coords(lats[jalts], lons[jalts])
rotate = ut[jalts]*360./24.
xx = tmp[0,*]
yy = tmp[1,*]
x1 = cos(rotate*!dtor)*xx - sin(rotate*!dtor)*yy
y1 = sin(rotate*!dtor)*xx + cos(rotate*!dtor)*yy
xx = x1
yy = y1

oplot, xx, yy, thick=2

sonx = cos(rotate*!dtor)*son_pos_map[0] - sin(rotate*!dtor)*son_pos_map[1]
sony = sin(rotate*!dtor)*son_pos_map[0] + cos(rotate*!dtor)*son_pos_map[1]

stp = 4
for i=0,n_elements(xx)-3,stp do begin
	
	ps_open, 'son_fov_data_'+STRTRIM(string((i+1)/4.,format='(I02)'),2)+'.ps'
	
	clear_page
	map_plot_panel,2,1,0,0, date=date, time=time, coords='geog', xrange=[-lim,lim], yrange=[-60.,60.], $
		rotate=ut[ialts[i]]*360./24., position=[.02, .3, .32, .7], /isotropic

	oplot, xx, yy
	oplot, [xx[i], sonx[i], xx[i+stp]], [yy[i], sony[i], yy[i+stp]]
	oplot, [xx[i], xx[i+stp]], [yy[i], yy[i+stp]], thick=6, color=200
	
	position = define_panel(2,1,1,0, /bar)
	position[0] = position[0]-.03
	position[2] = position[2]+.01
	plot, [0,0], /nodata, position=position, $
		xstyle=5, ystyle=5, xrange=[4, 5.5], yrange=[0., 500.]
	for it=0,i+stp do begin
		for ialt=0,nalt-2 do begin
			if vo[it, ialt,0] ne 9999.99 and alt[it,ialt] lt 450. and ut[it,ialt] ge 4. and alt[it,ialt] gt 70. then begin
				; col = bytscl(10^(nel[it, ialt,0])*1e-11, max=scale[1], min=scale[0], top=250) + 2
				col = bytscl(vo[it, ialt, 0], max=scale[1], min=scale[0], top=250) + 2
		
				polyfill, [ut[it,ialt], ut[it+1,ialt], ut[it+1,ialt+1], ut[it,ialt+1]], $
						[alt[it,ialt], alt[it,ialt], alt[it,ialt+1], alt[it,ialt+1]], $
						col=col
			endif
		endfor
	endfor
	plot, [0,0], /nodata, position=position, xtitle='Hour [UT]', $
		xstyle=1, ystyle=5, xrange=[4, 5.5], yrange=[0., 500.], $
		title='Sondrestrom - '+STRTRIM(fix(ut[i])-2L,2)+':'+STRTRIM(string((ut[i] - fix(ut[i]))*60L,format='(I02)'),2)+'LT'
	axis, yaxis=1, yrange=[0.,500.]/sin(33.*!dtor), ystyle=1, ytitle='Range [km]'
	axis, yaxis=0, yrange=[0.,500.], ystyle=1, ytitle='Altitude [km]'
	;plot_colorbar, 2,1,1,0, param='power', scale=scale, /continuous, legend='Ne [10!E11!Nm!E-3!N]', $
	plot_colorbar, 2,1,1,0, param='power', scale=scale, /continuous, legend='Vo [m.s!E-1!N]', $
		level_format='(F6.1)', /keep_first_last_label, panel_position=position, gap=.1
		
	ps_close
	spawn, '~/ps2png.sh son_fov_data_'+STRTRIM(string((i+1)/4.,format='(I02)'),2)+'.ps'
endfor

;ps_close

spawn, 'convert -delay 100  son_fov_data_??.png ~/Desktop/son_fov_data_vo.gif'


end

