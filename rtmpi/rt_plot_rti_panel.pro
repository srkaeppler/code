pro rt_plot_rti_panel, xmaps, ymaps, xmap, ymap, $
	date=date, time=time, grid=grid, beam=beam, $
	param=param, ionos=ionos, $
	coords=coords, yrange=yrange, scale=scale, $
	freq_band=freq_band, silent=silent, bar=bar, $
	charthick=charthick, charsize=charsize, $
	xstyle=xstyle, ystyle=ystyle, xtitle=xtitle, ytitle=ytitle, $
	xticks=xticks, xminor=xminor, yticks=yticks, yminor=yminor, $
	xtickformat=xtickformat, ytickformat=ytickformat, $
	xtickname=xtickname, ytickname=ytickname, $
	position=position, ground=ground, trend=trend, sun=sun, $
	last=last, first=first, with_info=with_info, no_title=no_title, $
	data=data, contour=contour

common	rt_data_blk
common	radarinfo

help, rt_info, /st, output=infout
if n_elements(infout) le 2 then begin
	print, 'No data present'
	return
endif

if ~keyword_set(param) then $
	param = 'power'

if ~keyword_set(coords) then $
	coords = 'rang'

if ~keyword_set(beam) then $
	beam = rt_data.beam[0,0]

if n_params() lt 4 then begin
	if ~keyword_set(silent) then $
		prinfo, 'XMAPS, YMAPS, XMAP and YMAP not set, using default.'
	xmaps = 1
	ymaps = 1
	xmap = 0
	ymap = 0
endif

if ~keyword_set(position) then $
	position = define_panel(xmaps, ymaps, xmap, ymap, bar=bar, with_info=with_info, no_title=no_title)

if ~keyword_set(date) then begin
	if ~keyword_set(silent) then $
		prinfo, 'No DATE given, trying for scan date.'
	caldat, rt_data.juls[0], month, day, year
	date = year*10000L + month*100L + day
endif
parse_date, date, year, month, day

if ~keyword_set(time) then $
	time = [0000,2400]

sfjul, date, time, sjul, fjul
xrange = [sjul, fjul]

if ~keyword_set(xtitle) then $
	_xtitle = 'Time '+rt_info.timez $
else $
	_xtitle = xtitle

if ~keyword_set(xtickformat) then $
	_xtickformat = 'label_date' $
else $
	_xtickformat = xtickformat

if ~keyword_set(xtickname) then $
	_xtickname = '' $
else $
	_xtickname = xtickname

if ~keyword_set(ytitle) then $
	_ytitle = get_default_title(coords) $
else $
	_ytitle = ytitle

if ~keyword_set(ytickformat) then $
	_ytickformat = '' $
else $
	_ytickformat = ytickformat

if ~keyword_set(ytickname) then $
	_ytickname = '' $
else $
	_ytickname = ytickname

if ~keyword_set(xstyle) then $
	xstyle = 1

if ~keyword_set(ystyle) then $
	ystyle = 1

if ~keyword_set(charsize) then $
	charsize = get_charsize(xmaps, ymaps)

if ~keyword_set(scale) then begin
	if strcmp(get_parameter(), param) then $
		scale = get_scale() $
	else $
		scale = get_default_range(param)
endif

if ~keyword_set(yrange) then $
	yrange = get_default_range(coords)

if ~keyword_set(xticks) then $
	xticks = get_xticks(sjul, fjul, xminor=_xminor)

if keyword_set(xminor) then $
	_xminor = xminor

; Select beam index
beaminds = where(rt_data.beam[0,*] eq beam)
nb = beaminds[0]

; Find range-gate locations
ajul = (sjul+fjul)/2.d
caldat, ajul, mm, dd, year
yrsec = (ajul-julday(1,1,year,0,0,0))*86400.d
radID = where(network.ID eq rt_info.id)
tval = TimeYMDHMSToEpoch(year, mm, dd, 0, 0, 0)
for s=0,31 do begin
	if (network[radID].site[s].tval eq -1) then break
	if (network[radID].site[s].tval ge tval) then break
endfor
radarsite = network[radID].site[s]
nbeams = network[radID].site[s].maxbeam
rad_define_beams, rt_info.id, nbeams, rt_info.ngates, year, yrsec, coords=coords, $
		/normal, fov_loc_center=fov_loc_center
fov_loc_center = reform(fov_loc_center[0,beam,*])
; print, coords, fov_loc_center

; Determine maximum width to plot scan - to decide how big a 'data gap' has to
; be before it really is a data gap.  Default to 5 minutes
if ~keyword_set(max_gap) then $
	max_gap = 120.

; set up coordinate system for plot
plot, [0,0], /nodata, xstyle=5, ystyle=5, $
	yrange=yrange, xrange=xrange, position=position

; get data
xtag = 'juls'
ytag = param
s = execute('xdata = rt_data.'+xtag)
s = execute('ydata = rt_data.'+ytag)

; select data to plot
; must fit beam and time (roughly)
txdata = xdata
juls_inds = where(txdata ge sjul-10.d/1440.d and $
									txdata le fjul+10.d/1440.d, cc)
if cc eq 0 then begin
	if ~keyword_set(silent) then $
		prinfo, 'No data found for time '+format_time(time)
	return
endif
txdata = 0

; get color preferences
foreground  = get_foreground()
color_steps = get_colorsteps()
ncolors     = get_ncolors()
bottom      = get_bottom()

; Set color bar and levels
cin = FIX(FINDGEN(color_steps)/(color_steps-1.)*(ncolors-1))+bottom
lvl = scale[0]+FINDGEN(color_steps)*(scale[1]-scale[0])/color_steps

; Add final elements for full plots
tsteps = n_elements(xdata)
xdata = [xdata, fjul]

if keyword_set(trend) AND param eq 'power' then begin
	trendARR = dindgen(tsteps,2)
endif


if keyword_set(sun) then begin
	sunlinecol = 190
	; plot sunrise/sunset/solar noon
	loadct, 0
	rad_calc_sunset, date, rt_info.name, beam, rt_info.ngates, $
		risetime=risetime, settime=settime

	toverflow = where(risetime lt sjul, cc, complement=tunderflow, ncomplement=cccomp)
	if cc gt 0 then $
		risetime[toverflow] = risetime[toverflow]+1.d
	toverflow = where(settime gt fjul, cc, complement=tunderflow, ncomplement=cccomp)
	if cc gt 0 then $
		settime[toverflow] = settime[toverflow]-1.d
	toutbound = where(risetime gt fjul, cc)
	if cc gt 0 then $
		risetime[toutbound] = 0.
	toutbound = where(settime lt sjul, cc)
	if cc gt 0 then $
		settime[toutbound] = 0.


	for ig=0,n_elements(risetime)-2 do begin
		if fov_loc_center[ig+1] le yrange[1] and fov_loc_center[ig] ge yrange[0] then begin
			ylims_night = fov_loc_center[ig]*[1,0,0,1] + fov_loc_center[ig+1]*[0,1,1,0]

			if settime[ig+1] lt risetime[ig+1] then begin
				if settime[ig] ge risetime[ig] then continue
				xlims_night = [settime[ig:ig+1], reverse(risetime[ig:ig+1])]
				if settime[ig+1] eq 0. or settime[ig] eq 0. then $
					xlims_night = [xrange[0]*[1,1], reverse(risetime[ig:ig+1])]
				if risetime[ig+1] ne 0. and risetime[ig] ne 0. then $
					polyfill, xlims_night, ylims_night , col=sunlinecol*1.2
			endif
			if settime[ig+1] gt risetime[ig+1] then begin
				if settime[ig] le risetime[ig] then continue
				xlims_night = [xrange[0]*[1,1], reverse(risetime[ig:ig+1])]
				if risetime[ig] ne 0. and risetime[ig+1] ne 0. then $
					polyfill, xlims_night, ylims_night , col=sunlinecol*1.2
				xlims_night = [settime[ig:ig+1], xrange[1]*[1,1]]
				polyfill, xlims_night, ylims_night , col=sunlinecol*1.2
			endif
		endif
	endfor

	nleg = 0
	loadct, 0, file='/tmp/colors2.tbl'
endif

; overplot data
FOR nt=0, tsteps-1 DO BEGIN
	start_time = xdata[nt]
	end_time = xdata[nt+1]
; 	CALDAT, start_time, Month , Day , Year, Hour, min
; 	print, 'sart' , Year , Month , Day, Hour, min
; 	CALDAT, end_time, Month , Day , Year, Hour, min
; 	print, 'end' , Year , Month , Day, Hour, min
	; cycle through ranges
	FOR r=0, rt_info.ngates-1 DO BEGIN

		; only plot points with real data in it
		IF ydata[nt,nb,r] ne 10000. THEN BEGIN
			; Do not plot if user specified ground or ionos scatter only
			if keyword_set(ground) and rt_data.gscatter[nt,nb,r] eq 2b then $
				continue
			if keyword_set(ionos) and rt_data.gscatter[nt,nb,r] eq 1b then $
				continue
			if rt_data.gscatter[nt,nb,r] eq 0b then $
				continue

			if ~keyword_set(data) and ~keyword_set(contour) then begin
				; get color
				color_ind = (MAX(where(lvl le ((ydata[nt,nb,r] > scale[0]) < scale[1]))) > 0)
				col = cin[color_ind]

				; finally plot the point
				POLYFILL,[start_time,start_time,end_time,end_time], $
						[fov_loc_center[r],fov_loc_center[r+1], $
							fov_loc_center[r+1], fov_loc_center[r]], $
						COL=col,NOCLIP=0
			endif else begin
				if keyword_set(ground) and rt_data.gscatter[nt,nb,r] eq 1b then begin
					plots, [start_time,start_time,end_time,end_time, start_time], $
							[fov_loc_center[r],fov_loc_center[r+1], $
								fov_loc_center[r+1], fov_loc_center[r], fov_loc_center[r]]
				endif
			endelse

		ENDIF
	ENDFOR

	if keyword_set(data) or keyword_set(contour) and xdata[nt] lt xrange[1] then begin
		scatind = where(rt_data.gscatter[nt,nb,3:*] eq 2b, cscat)
		if nt lt tsteps-1 then $
			scatindu = where(rt_data.gscatter[nt+1,nb,3:*] eq 2b, cscatu) $
		else $
			scatindu = where(rt_data.gscatter[nt,nb,3:*] eq 2b, cscatu)
		if cscat gt 0 and cscatu gt 0 then begin
			plots, xdata[nt:nt+1], [fov_loc_center[3+scatind[0]],fov_loc_center[3+scatindu[0]]], thick=2
			plots, xdata[nt:nt+1], [fov_loc_center[3+scatind[cscat-1]],fov_loc_center[3+scatindu[cscatu-1]]], thick=2
		endif
	endif

	; create trend over one beam index
	; average power trend over all range gate
	; use power as weighing function
	if keyword_set(trend) AND param eq 'power' then begin
		tr = findgen(rt_info.ngates)
		trinds = where(ydata[nt,*] gt 0. AND tr[*] gt 25.)
		IF trinds[0] GE 0. THEN $
			trdata = ROUND(TOTAL(10^ydata[nt,nb,trinds]*tr[trinds])/TOTAL(10^ydata[nt,nb,trinds])) $
		ELSE $
			trdata = 0L

		; update trend array
		trendARR[nt,0] = start_time
		trendARR[nt,1] = fov_loc_center[trdata]
	endif

ENDFOR
; Plot first range gate
; loadct, 0
oplot, xrange, fov_loc_center[0]*[1,1], linestyle=0, col=0, thick=2
loadct, 0, file='/tmp/colors2.tbl'

if keyword_set(data) or keyword_set(contour) then begin
	z = abs(90. - median(reform(rt_data.aspect[*,nb,*]),2))
	contour, z, rt_data.juls, fov_loc_center, /overplot, /closed, $
		min_val=0., max_val=1., levels=[0.,.2,.4,.6,.8,1.], $
		c_annotation=['0', '0.2', '0.4', '0.6', '0.8', '1'], $
		c_thick=1, c_charsize=charsize*.8
endif

if keyword_set(sun) then begin
	; plot sunrise/sunset/solar noon
	loadct, 0

	tinbound = where(risetime ne 0., cc)
	if cc gt 0. then begin
		for ig=0,n_elements(tinbound)-2 do begin
			if abs(risetime[tinbound[ig]] - risetime[tinbound[ig+1]]) lt 2.d/24.d then $
				oplot, risetime[tinbound[ig:ig+1]], fov_loc_center[tinbound[ig:ig+1]], linestyle=2, thick=3, col=sunlinecol
		endfor
	endif
	tinbound = where(settime ne 0., cc)
	if cc gt 0. then begin
		for ig=0,n_elements(tinbound)-2 do begin
			if abs(settime[tinbound[ig]] - settime[tinbound[ig+1]]) lt 2.d/24.d then $
				oplot, settime[tinbound[ig:ig+1]], fov_loc_center[tinbound[ig:ig+1]], linestyle=2, thick=3, col=sunlinecol
		endfor
	endif

; 	xyouts, risetime[nleg], fov_loc_center[nleg]-(fov_loc_center[nleg+1]-fov_loc_center[nleg])*2., 'Sunrise', align=.5, col=sunlinecol, charsize=charsize
; 	xyouts, settime[nleg], fov_loc_center[nleg]-(fov_loc_center[nleg+1]-fov_loc_center[nleg])*2., 'Sunset', align=.5, col=sunlinecol, charsize=charsize

	loadct, 0, file='/tmp/colors2.tbl'
endif

if keyword_set(trend) AND param eq 'power' then begin
	oplot, trendARR[*,0], trendARR[*,1], thick=2, min_value=10, max_value=65
endif

; check if format is sardines.
; if yes, loose the x axis information
; unless it is given
fmt = get_format(sardines=sd, tokyo=ty)
if sd and ~keyword_set(last) then begin
	if ~keyword_set(xtitle) then $
		_xtitle = ' '
	if ~keyword_set(xtickformat) then $
		_xtickformat = ''
	if ~keyword_set(xtickname) then $
		_xtickname = replicate(' ', 60)
endif
if ty and ~keyword_set(first) then begin
	if ~keyword_set(ytitle) then $
		_ytitle = ' '
	if ~keyword_set(ytickformat) then $
		_ytickformat = ''
	if ~keyword_set(ytickname) then $
		_ytickname = replicate(' ', 60)
endif

; Overlay grid if required
if keyword_set(grid) then begin
	_gridstyle = 1
	_xticklen = 1.
	_yticklen = 1.
endif else begin
	_xticklen = -.02
	_yticklen = -.02
endelse

; "over"plot axis
plot, [0,0], /nodata, position=position, $
	charthick=charthick, charsize=charsize, $
	yrange=yrange, xrange=xrange, $
	xstyle=xstyle, ystyle=ystyle, xtitle=_xtitle, ytitle=_ytitle, $
	xticks=xticks, xminor=_xminor, yticks=yticks, yminor=yminor, $
	xtickformat=_xtickformat, ytickformat=_ytickformat, $
	xtickname=_xtickname, ytickname=_ytickname, $
	color=get_foreground(), $
	xticklen=_xticklen, yticklen=_yticklen, $
	xgridstyle=_gridstyle, ygridstyle=_gridstyle

end
