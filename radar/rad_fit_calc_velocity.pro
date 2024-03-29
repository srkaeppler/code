pro	rad_fit_calc_velocity, force=force, method=method

common rad_data_blk
common rt_data_blk
common radarinfo

Rav = 6370.

if ~keyword_set(method) then $
	method = 'iri'

; Find data index
data_index = rad_fit_get_data_index()
nrecs = (*rad_fit_info[data_index]).nrecs
ngates = (*rad_fit_info[data_index]).ngates
radar = (*rad_fit_info[data_index]).code

; Find run date and time
caldat, (*rad_fit_info[data_index]).sjul, mm1, dd1, yy1, hh1, mn1
caldat, (*rad_fit_info[data_index]).fjul, mm2, dd2, yy2, hh2, mn2
date = yy1*10000L + mm1*100L + dd1
time = [hh1*100L, (hh2+1)*100L]

; radar structure
radID = where(network.ID eq (*rad_fit_info[data_index]).id)
tval = TimeYMDHMSToEpoch(yy1, mm1, dd1, 0, 0, 0)
for s=0,31 do begin
	if (network[radID].site[s].tval eq -1) then break
	if (network[radID].site[s].tval ge tval) then break
endfor
radarsite = network[radID].site[s]

; Range array
ajul = ((*rad_fit_info[data_index]).sjul+(*rad_fit_info[data_index]).fjul)/2.d
yrsec = (ajul-julday(1,1,yy1,0,0,0))*86400.d
rad_define_beams, (*rad_fit_info[data_index]).id, (*rad_fit_info[data_index]).nbeams, ngates, yy1, yrsec, coords='rang', $
		/normal, fov_loc_center=range_loc
rad_define_beams, (*rad_fit_info[data_index]).id, (*rad_fit_info[data_index]).nbeams, ngates, yy1, yrsec, coords='geog', $
		/normal, fov_loc_center=fov_loc_center

; Azimuths
offset = radarsite.maxbeam/2. - .5
b0 = radarsite.boresite
azimuth = b0 + ((*rad_fit_data[data_index]).beam - offset)*radarsite.bmsep
azimuth = (1.+fltarr(ngates)) ## azimuth
; print, azimuth[uniq((*rad_fit_data[data_index]).beam, sort((*rad_fit_data[data_index]).beam))]


if method eq 'iri' then begin

	; run ray tracing
	rt_run, date, (*rad_fit_info[data_index]).code, time=time, force=force, freq=round((*rad_fit_data[data_index]).tfreq[nrecs/4]*1e-3)

	; Apply correction to velocity (mask)
	njuls = n_elements((*rad_fit_data[data_index]).juls)
	novelinds = where((*rad_fit_data[data_index]).velocity eq 10000.)
	for it=0,n_elements(rt_data.juls[*,0])-2 do begin
		for ib=0,n_elements(rt_data.beam[0,*])-1 do begin
			for j=0,rt_info.ngates-2 do begin
				julinds = where((*rad_fit_data[data_index]).juls ge rt_data.juls[it,0] and $
								(*rad_fit_data[data_index]).juls lt rt_data.juls[it+1,0] and $
								(*rad_fit_data[data_index]).beam eq rt_data.beam[it,ib], cc)
				; If there is a correction to apply, do it
				if cc gt 0 and rt_data.nr[it,ib,j] gt 0 then begin
					(*rad_fit_data[data_index]).velocity[julinds + j*njuls] = (*rad_fit_data[data_index]).velocity[julinds + j*njuls] * 1./rt_data.nr[it,ib,j]
				endif
			endfor
		endfor
	endfor
	; Enforce no velocity value (the correction overwrote this, which is why it needs to be enforced here)
	(*rad_fit_data[data_index]).velocity[novelinds] = 10000.

endif else if method eq 'elevation' then begin
	
	; re-calculate elevation
	if radar eq 'bks' and date le 20110701 then scan_boresite_offset = 8. else scan_boresite_offset = 0.
	rad_fit_calculate_elevation, date=date, time=time, /overwrite, phidiff=1., tdiff=-.324, interfer_pos=[0.,-58.9,-2.7], scan_boresite_offset=scan_boresite_offset
	
	; calculate approximate altitude, assuming los propagation
	altitude = fltarr(nrecs,ngates)
	for ib=0,(*rad_fit_info[data_index]).nbeams-1 do begin
		binds = where((*rad_fit_data[data_index]).beam eq ib,ccb)
		ranges = transpose(reform(range_loc[0,ib,*])) ## (1.+fltarr(ccb))
		altitude[binds,*] = sqrt(ranges^2 + Rav^2 + 2.*ranges*Rav*sin((*rad_fit_data[data_index]).elevation[binds,*]*!dtor)) - Rav
	endfor

	; Dip and declinations
	magdip = fltarr(nrecs,ngates)
	magdec = fltarr(nrecs,ngates)
	for ib=0,(*rad_fit_info[data_index]).nbeams-1 do begin
		binds = where((*rad_fit_data[data_index]).beam eq ib,ccb)
		for ig=0,ngates-1 do begin
			igrf_run, date, lati=fov_loc_center[0,(*rad_fit_data[data_index]).beam[binds[0]],ig], $
							longi=fov_loc_center[1,(*rad_fit_data[data_index]).beam[binds[0]],ig], $
							alti=[280.,260.,0.], diparr=tdip, decarr=tdec
			magdip[binds,ig] = tdip*(1.+fltarr(ccb))
			magdec[binds,ig] = tdec*(1.+fltarr(ccb))
		endfor
	endfor

	; calculate velocity correction
	nr = fltarr(nrecs,ngates)
	nr = Rav/(Rav + altitude) * cos((*rad_fit_data[data_index]).elevation*!dtor) * sqrt( 1. + cos((magdec - azimuth)*!dtor)^2/tan(magdip*!dtor)^2 )

	; correct velocities
	novelinds = where((*rad_fit_data[data_index]).velocity eq 10000., nnovelinds, complement=velinds, ncomplement = nvelinds)
	if nvelinds gt 0 then $
		(*rad_fit_data[data_index]).velocity[velinds] = (*rad_fit_data[data_index]).velocity[velinds] * 1./nr[velinds]
	; Enforce no velocity value (the correction overwrote this, which is why it needs to be enforced here)
	if nnovelinds gt 0 then (*rad_fit_data[data_index]).velocity[novelinds] = 10000.

	; Pass correction to the width parameter
	(*rad_fit_data[data_index]).width[velinds] = (1./nr[velinds] - 1.)*100.
	if nnovelinds gt 0 then (*rad_fit_data[data_index]).width[novelinds] = 10000.
; 	print, (*rad_fit_data[data_index]).width[where((*rad_fit_data[data_index]).beam eq 12), 15]
	
endif else if method eq 'stat' then begin
	
	print, 'Work in progress'
	
endif



end