pro	hwm_plot_map_multi, res=res, alt=alt

clear_page
xmaps = 2
ymaps = 2

xmap = 0
ymap = 0
time = 2000
date = 20100621
hwm_igrf, xmaps, ymaps, xmap, ymap, date, time, alt=alt

xmap = 0
ymap = 1
time = 2000
date = 20101221
hwm_igrf, xmaps, ymaps, xmap, ymap, date, time, alt=alt

xmap = 1
ymap = 0
time = 2000
date = 20100621
hwm_plot_map_weff, xmaps, ymaps, xmap, ymap, date, time, alt=alt

xmap = 1
ymap = 1
time = 2000
date = 20101221
hwm_plot_map_weff, xmaps, ymaps, xmap, ymap, date, time, alt=alt
; 
; xmap = 1
; date = 20100621
; ; time=2000
; ; hwm_plot_map, ymaps, ymap, date, time, alt=alt, res=res
; hwm_plot_map_weff, xmaps, xmap, date, time, alt=alt

end