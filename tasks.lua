last_button = 0
last_button_state = 0
red_button = 0
green_button = 0

--last_button_state = 0 白色
--last_button_state = 1 蓝色
--last_button_state = 2 绿色
--last_button_state = 3 红色

function  on_control_notify(screen,control,value)
	if screen == 3 then
        if control >= 1 and control <= 64 and control ~= last_button then
		    if green_button == 0 or red_button == 0 then  --判断是否选中过正极或负极
			    if last_button_state == 0  then   --判断按钮状态是否为白色，如果为白色，将其置为蓝色
				    Icon_value = 1
				    set_value(3,control,Icon_value)
				    last_button_state = 1
				    last_button = control
                else if last_button ~= control and last_button_state ~= 0 then  --判断是否为其他按钮，如果是其他按钮，将上一个按钮置为白色，当前按钮置为蓝色，绿色和红色按钮不变
                        Icon_value = 0
                        if last_button_state ~= 2 and last_button_state ~= 3 then
                            set_value(3,last_button,Icon_value)
                        end
                        Icon_value = 1
                        set_value(3,control,Icon_value)
                        last_button_state = 1
                        last_button = control
			        end
                end
			end
		end
        if green_button == 0 then    --正极按钮按下后，将按钮置为绿色
            if control == 65 then
                Icon_value = 2
                set_value(3,last_button,Icon_value)
                green_button = last_button
                last_button_state = 2
            end
        end
         if red_button == 0 then    --负极按钮按下后，将按钮置为红色
            if control == 66 then
                Icon_value = 3
                set_value(3,last_button,Icon_value)
                red_button = last_button
                last_button_state = 3
            end
        end	
 	end
end