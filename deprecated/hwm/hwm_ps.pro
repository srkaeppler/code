pro	hwm_ps

ps_open, '~/Desktop/HWM_IGRF.ps'

hwm_plot_map_multi, 20100621, alt=150.
hwm_plot_map_multi, 20100621, alt=200.


hwm_plot_map_multi, 20101221, alt=150.
hwm_plot_map_multi, 20101221, alt=200.

; hwm_plot_map_weff, 20101221, 1200, res=2, alt=100.
; hwm_plot_map_weff, 20101221, 2000, res=2, alt=100.
; 
; hwm_plot_map_weff, 20101221, 1200, res=2, alt=200.
; hwm_plot_map_weff, 20101221, 2000, res=2, alt=200.

ps_close


end