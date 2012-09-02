;+
; NAME:
; rad_fit_check_echoes
;
; PURPOSE:
; This procedure reads radar fitacf data for a whole day and plots the number
; of ionospheric (black) and groundscatter (gray) echoes as a function of time.
;
; CATEGORY:
; Diagnostics
;
; CALLING SEQUENCE:
; rad_fit_check_echoes, radar, date=date
;
; INPUTS:
; Radar: Set this to a 3-letter radar code to indicate the radar for which to read
; data.
;
; KEYWORD PARAMETERS:
; Date: The date of which to read data. Can be a scalar in YYYYMMDD format or
; a 2-element vector in YYYYMMDD format. Defaults to yesterday.
;
; PROCEDURE:
;
; COMMON BLOCKS:
; RAD_DATA_BLK: The common block holding the currently loaded radar data and
; information about that data.
;
; RADARINFO: The common block holding data about all radar sites (from RST).
;
; EXAMPLE:
;
; COPYRIGHT:
;
; MODIFICATION HISTORY:
; Written by Sebastien de Larquier, Jun, 30, 2012
; Modified by Evan Thomas, Jul, 05, 2012
;-
pro rad_fit_check_echoes, radar, date=date, $
	oldfit=oldfit, fitacf=fitacf, fitex=fitex, $
	ps=ps, scale=scale, beam=beam, $
	position=position, charsize=charsize, $
	noxlabels=noxlabels, notitle=notitle, schedule=schedule

common radarinfo
common rad_data_blk

; If no date is given, select previous day
if ~keyword_set(date) then begin
	juld = systime(/utc, /julian)
	caldat, juld-1.d, month, day, year
	date = year*10000L + month*100L + day
endif
; Calculate julian day
tdate = date
parse_date, tdate, year, month, day
juld = julday(month, day, year, 0, 0)
; Calculate plot x-limits
xrange = [juld, juld+1.d]

; If you need a standalone postscript...
if keyword_set(ps) then begin
	if size(ps,/type) eq 7 then $
		filename = ps $
	else $
		filename = '~/Desktop/check_echoes_'+strtrim(tdate,2)+'_'+radar
	ps_open, filename+'.ps'
endif

; Adjust position for right axis labels
if ~keyword_set(position) then $
	position = define_panel(1,1, /no_title)
pos = position
pos[2] = position[2] - .05
; Adjust position for frequency/cpid panel
; pos[3] = position[3] - (position[3]-position[1])/5.


; If no x-axis labels
if keyword_set(noxlabels) then begin
	xtickname = replicate(' ', 60)
	xtitle = ''
	xtickformat = ''
endif else begin
	xtickname = ''
	xtitle = 'Time [UT]'
	xtickformat = 'label_date'
endelse

; Set ticks length
yticklen = -.02
xticklen = -.02


; ****************************
;- Schedule
; ****************************
if keyword_set(schedule) then begin
    loadct, 0
    switchud = 0
    rad_fit_check_schedule, date, schedule=rad_schedule
    plot, xrange, [0,1], /nodata, $
        xstyle=1, ystyle=1, position=[pos[0],pos[1]-.07,pos[2], pos[1]-.04], charsize=charsize, $
        ytitle='', yticks=1, ytickname=replicate(' ',60), $
        xtitle='', xtickformat='', xticks=4, xtickv=xrange[0]+dindgen(5)*6./24.d, xminor=6, xtickname=replicate(' ',60), xticklen=.2
    for isc=0,rad_schedule.nsch-1 do begin
        oplot, juld + rad_schedule.time[isc]*1.d/24.d*[1.d,1.d], [0,1], col=120, linestyle=1
        xyouts, juld + rad_schedule.time[isc]*1.d/24.d, .05 + switchud*.6, rad_schedule.name[isc], /data, charsize=charsize
        switchud = 1 - switchud
    endfor
    xyouts, .5, pos[1]-.08, 'Schedule', align=.5, /normal, charsize=charsize
endif


; Read file in required format and populate structures
rad_fit_read, tdate, radar, oldfit=oldfit, fitacf=fitacf, fitex=fitex

; Get data index
data_index = rad_fit_get_data_index()
if data_index ne -1 then begin
    if (*rad_fit_info[data_index]).code ne radar then data_index = -1
endif
if data_index eq -1 then begin
	; If no data, draw empty plotplot, xrange, yrange, /nodata, $
	plot, xrange, [0,1], /nodata, $
		xstyle=1, ystyle=1, position=pos, charsize=charsize, $
		ytitle=strupcase(radar)+' - Echoes', yticklen=yticklen, xticklen=xticklen, $
		xtitle=xtitle, xtickformat=xtickformat, xticks=4, xtickv=xrange[0]+dindgen(5)*6.d/24.d, xminor=6, xtickname=xtickname
	; Add an unambiguous statement about data availability for this radar on that day...
	xyouts, xrange[0]+(xrange[1]-xrange[0])/2., .5, 'NO DATA', charsize=charsize, align=.5
	return
endif

; Set parameters
nscans = (*rad_fit_info[data_index]).nscans
ngates = (*rad_fit_info[data_index]).ngates
juls = (*rad_fit_data[data_index]).juls
velocity = (*rad_fit_data[data_index]).velocity
gflag = (*rad_fit_data[data_index]).gscatter
scan_mark = (*rad_fit_data[data_index]).scan_mark
intt = (*rad_fit_data[data_index]).intt

; Get number of records
nrecs = (*rad_fit_info[data_index]).nrecs

; Get number of beams
nbeams = (*rad_fit_info[data_index]).nbeams

; Create a time array, because I'm tired of typing the whole structure...
time = (*rad_fit_data[data_index]).juls

; Beam and time array (for compatibility with data array)
if keyword_set(beam) then begin
	databeams = (1 + intarr((*rad_fit_info[data_index]).ngates)) ## (*rad_fit_data[data_index]).beam
	datatime =  (1 + intarr((*rad_fit_info[data_index]).ngates)) ## time
endif else begin
	databeams = (*rad_fit_data[data_index]).beam
	datatime = time
endelse

; Set beam
if keyword_set(beam) then begin
	setbeam = 1
	beaminds = where(databeams eq beam, cc)
	if cc le 0 then begin
		prinfo, 'Ohoh! There is a problem with '+radar+', beam '+strtrim(beam,2)
		return
	endif
	strbeam = strtrim(beam,2)
endif else begin
	setbeam = 0
	beaminds = indgen(n_elements(databeams))
	strbeam = 'all'
endelse

; If no scale is provided, just do your best to guess what it should be...
if ~keyword_set(scale) then $
	scale = [0., 40.]

; Get character size
if ~keyword_set(charsize) then $
	charsize = get_charsize(1,1)

; Calculate plot y-limits
yrange = scale

; Set up plotting area
plot, xrange, yrange, /nodata, ylog=ylog, $
	xstyle=1, ystyle=1, position=pos, charsize=charsize, $
	ytitle=strupcase(radar)+' ('+strbeam+') - Echoes', yticklen=yticklen, xticklen=xticklen, $
	xtitle=xtitle, xtickformat=xtickformat, xticks=4, xtickv=xrange[0]+dindgen(5)*6.d/24.d, xminor=6, xtickname=xtickname


; ****************************
;- Parameter
; ****************************
sjuls = dblarr(nscans)
fjuls = dblarr(nscans)
gs = fltarr(nscans)
is = fltarr(nscans)

; Loop through each scan
for ii=0,nscans-1 do begin
	gs_scan_sum = 0
	is_scan_sum = 0

	; Find the scan ids pertaining to the particular scan number
	if setbeam eq 1 then $
		scan_inds = where((*rad_fit_data[data_index]).beam_scan eq ii and $
			(*rad_fit_data[data_index]).beam eq beam, nscan_inds) $
	else $
		scan_inds = where((*rad_fit_data[data_index]).beam_scan eq ii, nscan_inds)

	; Check for data within the scan number
	if nscan_inds eq 0 then begin
		sjuls[ii] = !VALUES.F_NAN
		fjuls[ii] = !VALUES.F_NAN
		is[ii] = !VALUES.F_NAN
		gs[ii] = !VALUES.F_NAN
		continue
	endif

	; Find start and stop time of scan
	sjuls[ii] = juls[scan_inds[0]]
	fjuls[ii] = juls[scan_inds[nscan_inds-1]] + intt[scan_inds[nscan_inds-1]]/86400.

	; Loop through the individual scan
	for nn=0,nscan_inds-1 do begin
		; Loop through each range gate
		for gg=0,ngates-1 do begin
			; Check whether scatter is real and if from ionosphere or ground
			if gflag[scan_inds[nn],gg] eq 1 and velocity[scan_inds[nn],gg] lt 10000. then $
				gs_scan_sum = gs_scan_sum+1 $
			else if gflag[scan_inds[nn],gg] eq 0 and velocity[scan_inds[nn],gg] lt 10000. then $
				is_scan_sum = is_scan_sum+1
		endfor
	endfor

	gs[ii] = gs[ii]+gs_scan_sum/nscan_inds
	is[ii] = is[ii]+is_scan_sum/nscan_inds
endfor

rad_load_colortable, /aj

; Loop through each scan
for ii=0,nscans-1 do begin
	; Draw horizontal lines for histogram levels
	oplot, [sjuls[ii],fjuls[ii]],[gs[ii],gs[ii]],color=get_gray()
	oplot, [sjuls[ii],fjuls[ii]],[is[ii],is[ii]]

	; Draw vertical lines connecting different histogram levels
	if ii gt 0 then begin
		if gs[ii] gt gs[ii-1] then $
			oplot, [sjuls[ii],sjuls[ii]],[gs[ii-1],gs[ii]],color=get_gray() $
		else $
			oplot, [sjuls[ii],sjuls[ii]],[gs[ii],gs[ii-1]],color=get_gray()

		if is[ii] gt is[ii-1] then $
			oplot, [sjuls[ii],sjuls[ii]],[is[ii-1],is[ii]] $
		else $
			oplot, [sjuls[ii],sjuls[ii]],[is[ii],is[ii-1]]
	endif
endfor


; ****************************
;- CPID
; ****************************
; Mark initial cpid
loadct, 0
xyouts, xrange[0]+(xrange[1]-xrange[0])/10./1440., yrange[1] - (yrange[1]-yrange[0])/15., $
	rad_cpid_translate((*rad_fit_data[data_index]).scan_id[0])+' ('+strtrim((*rad_fit_data[data_index]).scan_id[0], 2)+')', $
	align=0., /data, col=120, charsize=charsize*.7
; Mark cpid changes
iddiff = (*rad_fit_data[data_index]).scan_id[1:nrecs-1] - (*rad_fit_data[data_index]).scan_id[0:nrecs-2]
gapinds = where(iddiff ne 0, ccgap)
; If cpid changes, then mark and annotate it (in gray)
cpidpos = 0		; used to switch the position of the cpid name to avoid overlap
if ccgap gt 0 then begin
	step = 1
	if ccgap gt 24 then step = round(ccgap/10)
	igap = 0L
	while igap lt ccgap do begin
		; Plot cpid change marker
		oplot, time[gapinds[igap]]*[1,1], yrange, col=120, linestyle=2
		; Plot cpid name and number
		xyouts, time[gapinds[igap]]+(xrange[1]-xrange[0])/10./1440., yrange[1] - (yrange[1]-yrange[0])/15. - cpidpos * (yrange[1]-yrange[0])/15., $
			rad_cpid_translate((*rad_fit_data[data_index]).scan_id[gapinds[igap]+1])+' ('+strtrim((*rad_fit_data[data_index]).scan_id[gapinds[igap]+1], 2)+')', $
			align=0., /data, col=120, charsize=charsize*.7
			
		cpidpos = 1 - cpidpos
		igap += step
	endwhile
endif 
rad_load_colortable, /aj


; ****************************
;- Title
; ****************************
; Add radar name and date
if ~keyword_set(notitle) then begin
	if keyword_set(fitex) then $
		datafmt = 'fitex' $
	else if keyword_set(fitacf) then $
		datafmt = 'fitacf' $
	else if keyword_set(oldfit) then $
		datafmt = 'oldfit' $
	else $
		datafmt = 'no data'
	xyouts, position[0], position[3], $
		network[where(network.code[0] eq radar)].name+' ('+datafmt+') -- '+STRMID(format_juldate(juld),0,11), $
		charsize=charsize, /normal
endif


; If you needed a standalone postscript... then close it
if keyword_set(ps) then $
	ps_close, /no_f


end
