last_button = 0
last_button_state = 0
red_button = 0
green_button = 0


function  on_control_notify(screen,control,value)
	if screen == 3 then
        if control >= 1 and control <= 64 and control ~= last_button then
		    if green_button == 0 or red_button == 0 then
			    if last_button_state == 0  then
				    Icon_value = 1
				    set_value(3,control,Icon_value)
				    last_button_state = 1
				    last_button = control
                else if last_button ~= control and last_button_state ~= 0 then
				        Icon_value = 0
				        set_value(3,last_button,Icon_value)
				        Icon_value = 1
				        set_value(3,control,Icon_value)
				        last_button_state = 1
				        last_button = control
			        end
                end
			end
		end
        if green_button == 0 then
            if control == 65 then
                Icon_value = 2
                set_value(3,last_button,Icon_value)
                green_button = last_button
                last_button_state = 2
            end
        end
         if red_button == 0 then
            if control == 66 then
                Icon_value = 3
                set_value(3,last_button,Icon_value)
                red_button = last_button
                last_button_state = 3
            end
        end	
 	end
end