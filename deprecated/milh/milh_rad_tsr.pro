pro milh_rad_tsr, date=date, ps=ps

common rad_data_blk
common rt_data_blk

if ~keyword_set(date) then $
	date = 20101117

milh_rad_read, date
rt_run, date, 'bks', time=[2100,1300], /ionos, beam=beam, bin='ground'

data_index = rad_fit_get_data_index()

if ~keyword_set(ps) then $
	ps = '~/Desktop/milh_rad_tsr.ps'
ps_open, ps

xmaps=1
ymaps=3
scale=[-50.,50.]
beam = 10

set_format, /portrait, /sardines

clear_page

rad_fit_plot_rti_panel,xmaps, ymaps, 0, 0, $
	date=[date,date+1],time=[2100,1300],beam=beam,scale=scale, $
	param='velocity', xtitle='', /bar
plot_colorbar, xmaps, ymaps, 0, 0, scale=scale, param='velocity', /bar

njuls = n_elements((*rad_fit_data[data_index]).juls)
novelinds = where((*rad_fit_data[data_index]).velocity eq 10000.)
tvelocity = (*rad_fit_data[data_index]).velocity
tpower = (*rad_fit_data[data_index]).power
(*rad_fit_data[data_index]).power = 0.*(*rad_fit_data[data_index]).power
for i=0,n_elements(rt_data.juls)-2 do begin
	for j=0,rt_info.ngates-2 do begin
		julinds = where((*rad_fit_data[data_index]).juls ge rt_data.juls[i] and $
						(*rad_fit_data[data_index]).juls lt rt_data.juls[i+1], cc)
		if cc gt 0 and rt_data.ionosnr[i,j] gt 0 then begin
			(*rad_fit_data[data_index]).velocity[julinds + j*njuls] = (*rad_fit_data[data_index]).velocity[julinds + j*njuls] * 1./rt_data.ionosnr[i,j]
			(*rad_fit_data[data_index]).power[julinds + j*njuls] = 1./rt_data.ionosnr[i,j]
		endif
	endfor
endfor
(*rad_fit_data[data_index]).velocity[novelinds] = 10000.
(*rad_fit_data[data_index]).power[novelinds] = 10000.

set_colorsteps, 250
rad_fit_plot_rti_panel,xmaps, ymaps, 0, 2, $
	date=[date,date+1],time=[2100,1300],beam=beam,scale=[1., 1.3], $
	param='power', xtitle='', /bar
plot_colorbar, xmaps, ymaps, 0, 2, scale=[1.,1.3], param='power', /bar, legend='Correction', /continuous, level_format='(f4.2)'
set_colorsteps, 8
(*rad_fit_data[data_index]).power = tpower

rad_fit_plot_rti_panel,xmaps, ymaps, 0, 1, $
	date=[date,date+1],time=[2100,1300],beam=beam,scale=scale, $
	param='velocity', xtitle='', /bar
plot_colorbar, xmaps, ymaps, 0, 1, scale=scale, param='velocity', /bar

clear_page

parse_date, date, year, month, day
sjul = julday(month, day, year, 22, 00)
fjul = julday(month, day+1, year, 2, 0)
binds = where((*rad_fit_data[data_index]).beam eq beam and $
				(*rad_fit_data[data_index]).juls ge sjul and $
				(*rad_fit_data[data_index]).juls le fjul and $
				(*rad_fit_data[data_index]).channel eq 0, ccb)
; time resolution in minutes
dmn = 2.

position = define_panel(1,3,0,1,/bar)
xdata = findgen(31)
velmax = 100.
plot, [0.,0.], /nodata, xrange=[0.,240.], yrange=[0.,30.], xstyle=1, ystyle=1, position=position, charsize=get_charsize(xmaps,ymaps)
for nv=0,ccb-1,5 do begin
	velo = (*rad_fit_data[data_index]).velocity[binds[nv],0:30]
	velinds = where(velo lt velmax and velo gt -velmax, ccvel)
	offset = - median(velo[velinds]) + nv*dmn
	for ng=0,n_elements(velo)-2 do begin
		if velo[ng] lt velmax and velo[ng+1] lt velmax and velo[ng] gt -velmax and velo[ng+1] gt -velmax then $
			oplot, velo[ng:ng+1] + offset, xdata[ng:ng+1]
	endfor
	oplot, [nv*dmn, nv*dmn], [0., 30.], linestyle=2, thick=1.
endfor
(*rad_fit_data[data_index]).velocity = tvelocity

position = define_panel(1,3,0,0,/bar)
plot, [0.,0.], /nodata, xrange=[0.,240.], yrange=[0.,30.], xstyle=1, ystyle=1, position=position, charsize=get_charsize(xmaps,ymaps)
for nv=0,ccb-1,5 do begin
	velo = (*rad_fit_data[data_index]).velocity[binds[nv],0:30]
	velinds = where(velo lt velmax and velo gt -velmax, ccvel)
	offset = - median(velo[velinds]) + nv*dmn
	for ng=0,n_elements(velo)-2 do begin
		if velo[ng] lt velmax and velo[ng+1] lt velmax and velo[ng] gt -velmax and velo[ng+1] gt -velmax then $
			oplot, velo[ng:ng+1] + offset, xdata[ng:ng+1]
	endfor
	oplot, [nv*dmn, nv*dmn], [0., 30.], linestyle=2, thick=1.
endfor

position = define_panel(1,3,0,2,/bar)
plot, [0.,0.], /nodata, xrange=[0.,240.], yrange=[0.,30.], xstyle=1, ystyle=1, position=position, charsize=get_charsize(xmaps,ymaps)
julinds = where(rt_data.juls ge sjul and rt_data.juls le fjul, ccj)
for i=0,ccj-2 do begin
	for ng=0,30 do begin
		if rt_data.ionosnr[julinds[i],ng] gt 0. then begin
			col = bytscl(1./rt_data.ionosnr[julinds[i],ng], max=1.3, min=1., top=250) + 2

			polyfill, [i*30., (i+1)*30., (i+1)*30., i*30.], $
					  [ng, ng, ng+1., ng+1.], COL=col
		endif
	endfor
endfor
set_colorsteps, 250
plot_colorbar, xmaps, ymaps, 0, 2, scale=[1.,1.3], param='power', /bar, legend='Correction', /continuous, level_format='(f4.2)'
set_colorsteps, 8

; rad_fit_plot_tsr_panel,xmaps, ymaps, 0, 1, $
; 	date=[date,date+1],time=[2100,1300],beam=beam,yrange=scale,gate=[15,20],/avg_gates, $
; 	param='velocity', /bar, exclude=scale, /last, symsize=0.01, psym=0

clear_page

P = 180. + findgen((*rad_fit_info[data_index]).ngates)*45.
Re = 6370.
altv = (*rad_fit_data[data_index]).elevation*0.
for n=0,(*rad_fit_info[data_index]).ngates-1 do begin
	altv[*,n] = sqrt(P[n]^2. + Re^2. + 2.*Re*P[n]*sin((*rad_fit_data[data_index]).elevation[*,n]*!dtor)) - Re
	gsinds = where((*rad_fit_data[data_index]).gscatter[*,n] eq 1B, gscc)
; 	if gscc gt 0 then $
; 		altv[gsinds,n] = sqrt(P[n]^2./4. + Re^2. + 2.*Re*P[n]/2.*sin((*rad_fit_data[data_index]).elevation[gsinds,n]*!dtor)) - Re
endfor
lopowinds = where((*rad_fit_data[data_index]).power lt 4. or (*rad_fit_data[data_index]).power ge 10000. ,cc)
if cc gt 0 then begin
	(*rad_fit_data[data_index]).power[lopowinds] = 10000.
	(*rad_fit_data[data_index]).elevation[lopowinds] = 10000.
	altv[lopowinds] = -10000.
endif

rad_fit_plot_rti_panel,xmaps, ymaps, 0, 0, $
	date=[date,date+1],time=[2100,1300],beam=beam, $
	param='power', xtitle='', /bar
plot_colorbar, xmaps, ymaps, 0, 0, param='power', /bar

rad_fit_plot_rti_panel,xmaps, ymaps, 0, 1, $
	date=[date,date+1],time=[2100,1300],beam=beam, $
	param='elevation', xtitle='', /bar
plot_colorbar, xmaps, ymaps, 0, 1, param='elevation', /bar

; Plot virtual height on rti panel
parse_date, date, yy, mm, dd
sjul = julday(mm,dd,yy,21,00)
fjul = julday(mm,dd+1,yy,13,00)
position = define_panel(xmaps, ymaps, 0, 2, /bar)
xticks = get_xticks(sjul, fjul, xminor=_xminor)
xrange = [sjul, fjul]
yrange = [0,70]
plot, [0,0], /nodata, xstyle=5, ystyle=5, $
	yrange=yrange, xrange=xrange, position=position

; get color preferences
scale = [100., 500.]
foreground  = get_foreground()
color_steps = get_colorsteps()
ncolors     = get_ncolors()
bottom      = get_bottom()

; Set color bar and levels
cin = FIX(FINDGEN(color_steps)/(color_steps-1.)*(ncolors-1))+bottom
lvl = scale[0]+FINDGEN(color_steps)*(scale[1]-scale[0])/color_steps

; Select beam indexes
beaminds = where((*rad_fit_data[data_index]).beam eq beam)

for t=0,n_elements(beaminds)-2 do begin
	start_time = (*rad_fit_data[data_index]).juls[beaminds[t]]
	end_time = (*rad_fit_data[data_index]).juls[beaminds[t+1]]
	if start_time ge sjul and end_time le fjul then begin
		for r=0,(*rad_fit_info[data_index]).ngates-2 do begin
			if altv[beaminds[t],r] gt 100. and altv[beaminds[t],r] lt 500. then begin
				; get color
				color_ind = (MAX(where(lvl le ((altv[beaminds[t],r] > scale[0]) < scale[1]))) > 0)
				col = cin[color_ind]
				
				; finally plot the point
				POLYFILL,[start_time,start_time,end_time,end_time], $
						[r, r+1, r+1, r], $
						COL=col,NOCLIP=0
			endif
		endfor
	endif
endfor

; "over"plot axis
plot, [0,0], /nodata, position=position, $
	charthick=charthick, charsize=get_charsize(xmaps,ymaps), $ 
	yrange=yrange, xrange=xrange, $
	xstyle=1, ystyle=1, xtitle='Time [UT]', ytitle='Gates', $
	xticks=xticks, xminor=_xminor, yticks=yticks, yminor=yminor, $
	xtickformat='label_date', ytickformat=_ytickformat, $
	xtickname=_xtickname, ytickname=_ytickname, $
	color=get_foreground()

plot_colorbar, xmaps, ymaps, xmaps-1, 2, scale=scale, param='power', /with_info, ground=ground, legend='Virtual height [km]'

clear_page

scale = [0., 15.]
rt_plot_rti_panel,xmaps, ymaps, 0, 0, $
	date=[date,date+1],time=[2100,1300], $
	param='power', xtitle='', /bar, scale=scale, /ionos;, /range
plot_colorbar, xmaps, ymaps, 0, 0, param='power', /bar, scale=scale

scale = [10., 30.]
rt_plot_rti_panel,xmaps, ymaps, 0, 1, $
	date=[date,date+1],time=[2100,1300], $
	param='elev', xtitle='', /bar, scale=scale, /ionos;, /range
plot_colorbar, xmaps, ymaps, 0, 1, param='power', /bar, legend=textoidl('Elevation angle [\circ]'), scale=scale

scale = [100., 500.]
rt_plot_rti_panel,xmaps, ymaps, 0, 2, $
	date=[date,date+1],time=[2100,1300], $
	param='valt', xtitle='', /bar, scale=scale, /ionos;, /range
plot_colorbar, xmaps, ymaps, 0, 2, param='power', /bar, legend='Virtual height [km]', scale=scale

ps_close

END