local last_button = 0
local last_button_state = 0
--last_button_state = 0 白色
--last_button_state = 1 蓝色
--last_button_state = 2 绿色
--last_button_state = 3 红色
local zhan_id = 0     --从站地址
local addr_id = 0     --寄存器地址

local red_button_max = 64
local green_button_max = 64

local red_button_count = 0
local green_button_count = 0

Modify_button_enable = 0   --1为启用，0为禁用

local pulse_min = 15
local pulse_max = 180
local current_min = 20
local current_max = 80

Regs_all = {}
Regs_all[0] = 1    --开关
Regs_all[1] = 15   --脉宽
Regs_all[2] = 20   --电流

regs_single = {}
regs_single[0] = 0

Send_flag = 1    --发送标志

Current_20_flag = 1

Pause_5s_flag = 0

local zdy_close_button = 0

local new_button_flag = 0

Time_1800 = 1800     --30分钟倒计时，1800秒
Countdown_time = Time_1800     --30分钟倒计时，1800秒
Countdown_time_run = 0  --1是开，0是暂停

Left_hand = 0    --左右手标志位，0为松开，1为按下
Right_hand = 0

First_modify_button_press = 0   --第一次按下强度调节

Last_screen = 99  --上一个屏幕

Left_right_hand_press = 0    --0没按下,1按下

Borrow_timer = 0


function on_init ()
	uart_set_baudrate (38400)  --初始化波特率
    set_visiable(4,18,0)  --隐藏提示窗
    set_visiable(4,19,0)
    set_visiable(5,18,0)
    set_visiable(5,19,0)
    set_visiable(6,18,0)
    set_visiable(6,19,0)
    
end

function delay_ms (ms)
    local start_time = get_tick_count()
    while (get_tick_count() - start_time) < ms do
        refresh_screen()  -- 刷新UI，防止假死
    end
end

function button_enable (first_screen,finally_screen,first_button,finally_button,value)  --禁用，启用按钮函数
    for i = first_screen, finally_screen, 1 do
        for y = first_button, finally_button, 1 do
            set_enable(i,y,value)
        end
    end
end

function open_deivce ()
    Regs_all[0] = 1
    equipment_send_all(5,6,Regs_all)    --打开电刺激
end

function close_deivce ()
    Regs_all[0] = 0
    equipment_send_all(5,6,Regs_all)    --关闭电刺激
end

function reset_deivce()
    Regs_all[0] = 0
    Regs_all[1] = 15   --脉宽
    Regs_all[2] = 20   --电流
    equipment_send_all(5,6,Regs_all)    --关闭电刺激
end

function fallback_button (screen,control,value)   --回退按钮函数
    if screen == 1 or screen == 2 or screen == 3 or screen == 4 or screen == 5 or screen ==6 or screen == 7 or screen == 8 or screen == 9 or screen == 10 or screen ==11 or screen == 12 or screen == 13  then
        if (control == 1 and value == 1) or (control == 2 and value == 1) then
            Last_screen = screen
            --print(Last_screen)
        end
    end
    if screen == 3 then
        Last_screen = 3
    end
    if screen == 1 or screen == 2 or screen == 3 or screen == 4 or screen == 5 or screen ==6 or screen == 7 or screen == 8 or screen == 9 or screen == 10 or screen ==11 or screen == 12 or screen == 13 then
        if control == 3 and value == 1 then
            change_screen_effect(Last_screen,4)
        end
    end

end


function left_right_hand (screen,control,value)    --左右手按下函数
    if screen == 2 or screen == 4 or screen == 5 or screen == 6 then
        local screen_arr = {2,4,5,6}
        if (control == 4 and value == 1) or (control == 5 and value == 1) then

            Left_right_hand_press = 1

            if control == 4 and value == 1 then
                Left_hand = 1
                Right_hand = 0
                for i = 1, 4, 1 do
                    set_value(screen_arr[i],4,1)
                    set_value(screen_arr[i],5,0)
                 end
            end
            if control == 5 and value == 1 then
                Left_hand = 0
                Right_hand = 1
                for i = 1, 4, 1 do
                    set_value(screen_arr[i],4,0)
                    set_value(screen_arr[i],5,1)
                end
            end

            reset_deivce()

            button_enable(4,6,8,9,1)

        end
    end
end


function task_screen_switch (screen,control,value)    --切换任务时，将脉宽，电流，文本复位，并且将倒计时重置
    if screen == 4 or screen == 5 or screen == 6 then
        if (control == 6 and value == 1) or (control == 7 and value == 1) then
            Regs_all[0] = 0
            Regs_all[1] = 15
            Regs_all[2] = 20
            set_text(screen,15, "15")
            set_text(screen,14, "20")

            Countdown_time = Time_1800    --重置倒计时

            set_value(screen,16,360)  --刷新进度条
            set_text(screen,17,"30:00")
            set_value(screen,9,0)  --刷新暂停按键

            button_enable(4,6,10,13,0)   --禁用强度调节按钮

            Current_20_flag = 1

        end
    end
end


--[[function zidingyi_number_change(screen,control,value)    --自定义前景数字颜色的改变
    if screen == 3 then
        if control == 1 and value == 1 then
            set_fore_color(3,86,0xFFFF)
        end
    end
end--]]



function light_modify (screen,control,value)    --亮度调节，音量调节
    if screen == 7 then
        if control == 4 then
            set_backlight(get_value(7,4))
        end
        if control == 5 then
            set_volume(get_value(7,5))
        end
    end
end



function modify_change_mode (screen,control,value)    --按下调节按钮后，切换至持续输出，检测五秒内是否再次按下，如果没有按下，则转换为5s间歇
    if screen == 4 or screen == 5 or screen == 6 then
        if (control == 10 and value == 1) or (control == 11 and value == 1) or (control == 12 and value == 1) or (control == 13 and value == 1) then
            stop_timer(7)   --暂停5秒间歇输出
            Regs_all[0] = 1
            if First_modify_button_press == 0 then
                Borrow_timer = 0
                start_timer(1,300,0,1)   --开始持续输出      待测试，只发强度是否能持续输出！！！
                First_modify_button_press = 1
            end
            
            Wait_time = 0  --等待时间
            start_timer(9,1000,0,0)
        end
    end
end

--绘图测试
--function on_draw(screen)
--    if screen == 4 or screen == 5 or screen == 6 then
--        set_pen_color(0xd77e)
--        draw_line(400,180,400,250,3)
--    end
--end

function on_timer(timer_id)
    if timer_id == 1 then  -- 定时器ID为1 
        if Borrow_timer == 0 then
            equipment_send_all(5,6,Regs_all)     --调用电刺激通信函数,开始输出
        else
            mb_write_reg_06(1,23,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
        end
    end
    if timer_id == 2 then
        regs_single[0] = 20
        equipment_send_single(5,8,regs_single)   --再发初始20mA
    end
    
    if timer_id == 3 then    --站2全关
        mb_write_reg_06 (1,52,0)
    end
    if timer_id == 4 then    --站3全关
        mb_write_reg_06 (2,52,0)
    end
    if timer_id == 5 then    --站4全关
        mb_write_reg_06 (3,52,0)
    end
    if timer_id == 6 then    --站1全关
        mb_write_reg_06 (4,52,0)
    end


    if timer_id == 7 then    --五秒间歇
        if Pause_5s_flag == 1 then
            Regs_all[0] = 1
            Borrow_timer = 0
            start_timer(1,300,0,1)
            Pause_5s_flag = 0

        elseif Pause_5s_flag == 0 then
        
            Pause_5s_flag = 1
            Send_flag = 0
            stop_timer(1)
            close_deivce()

        end
    end
    if timer_id == 8 then    --30分钟倒计时
        if Countdown_time_run == 1 and Countdown_time > 0 then     --处于倒计时中
            local min = math.floor(Countdown_time  / 60)
            local sec = Countdown_time % 60
            -- 使用string.format 确保两位数显示
            set_text(get_current_screen(), 17, string.format("%02d:%02d",  min, sec))

            

            Countdown_time = Countdown_time - 1

            set_value(get_current_screen(),16,(Countdown_time-1800)*(-0.2))  --圆形进度条

        end
        if Countdown_time == 0 then      --倒计时结束

            close_deivce()
            set_text(get_current_screen(),17,"00:00")



            set_value(get_current_screen(),8,0)    --将开始按键复位


            set_visiable(get_current_screen(),18,1)  --显示提示窗



            button_enable(get_current_screen(),get_current_screen(),1,13,0)    --禁用除提示窗外的其他按钮

            start_timer(3,200,0,1)  --四个站全关
            start_timer(4,400,0,1)
            start_timer(5,600,0,1)
            start_timer(6,800,0,1)

            stop_timer(8)   --关闭定时器
            stop_timer(7)

        end
    end
    if timer_id == 9 then
        if Wait_time < 5 then
            Wait_time = Wait_time + 1
            --print(Wait_time)
        else if Wait_time == 5 then
            stop_timer(9)  --暂停模式切换计时



            close_deivce()

            Pause_5s_flag = 1  --暂停5s标志置为1


            start_timer(7,5000,0,0)   --打开间歇
            --print("回归5s")

            First_modify_button_press = 0    --重置为1

            end
        end
    end

    --食指左手打开
    if timer_id == 10 then
        mb_write_reg_06(1,0,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置
    end
    if timer_id == 11 then
        mb_write_reg_06(1,1,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置
    end
    if timer_id == 12 then
        mb_write_reg_06(1,2,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置
    end
    if timer_id == 13 then
        mb_write_reg_06(1,3,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置
    end

    --食指右手打开
    if timer_id == 14 then
        mb_write_reg_06(1,4,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置 
    end
    if timer_id == 15 then
        mb_write_reg_06(1,5,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end
    if timer_id == 16 then
        mb_write_reg_06(1,6,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置   
    end
    if timer_id == 17 then
        mb_write_reg_06(1,7,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end

    --小指左手打开
    if timer_id == 18 then
        mb_write_reg_06(1,8,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置 
    end
    if timer_id == 19 then
        mb_write_reg_06(1,9,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end
    if timer_id == 20 then
        mb_write_reg_06(1,10,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end
    if timer_id == 21 then
        mb_write_reg_06(1,11,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end

    --小指右手打开
    if timer_id == 22 then
        mb_write_reg_06(1,12,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置
    end
    if timer_id == 23 then
        mb_write_reg_06(1,13,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end
    if timer_id == 24 then
        mb_write_reg_06(1,14,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end
    if timer_id == 25 then
        mb_write_reg_06(1,15,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end

    --无名指左手打开
    if timer_id == 26 then
        mb_write_reg_06(1,16,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end
    if timer_id == 27 then
        mb_write_reg_06(1,17,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end
    if timer_id == 28 then
        mb_write_reg_06(1,18,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end
    if timer_id == 29 then
        mb_write_reg_06(1,19,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end


    --无名指右手打开
    if timer_id == 30 then
        mb_write_reg_06(1,20,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end
    if timer_id == 31 then
        mb_write_reg_06(1,21,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end
    if timer_id == 0 then
        mb_write_reg_06(1,22,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置  
    end
    --另外一个在定时器1里面
end 




function equipment_send_all (slave,addr,Regs_all)   --电刺激通信函数,发三个寄存器
    local zhen_tou = {}   --帧头
    local zhen_wei = {}   --帧尾
    zhen_tou[0] = 0x0b
    zhen_tou[1] = 0x4d
    zhen_wei[0] = 0x1c
    zhen_wei[1] = 0x0d
    uart_send_data(zhen_tou)
    mb_write_reg_16 (slave,addr,Regs_all)  --功能码0x10的modbus发送函数
    uart_send_data(zhen_wei)
end



function equipment_send_single (slave,addr,regs_single)   --电刺激通信函数,发单个寄存器
    local zhen_tou = {}   --帧头
    local zhen_wei = {}   --帧尾
    zhen_tou[0] = 0x0b
    zhen_tou[1] = 0x4d
    zhen_wei[0] = 0x1c
    zhen_wei[1] = 0x0d
    uart_send_data(zhen_tou)
    mb_write_reg_16 (slave,addr,regs_single)  --功能码0x10的modbus发送函数
    uart_send_data(zhen_wei)
end



function anode_id_convert_32 (last_button_id)  --正极转换地址0-32
    local ji_dian_qi_id = last_button_id- 1
    return ji_dian_qi_id
end

function anode_id_convert_64 (last_button_id)  --正极转换地址33-64
    local ji_dian_qi_id = last_button_id- 33
    return ji_dian_qi_id
end

function cathode_id_convert_32 (last_button_id)  --负极转换地址0-32
    local ji_dian_qi_id = 32 - last_button_id
    return ji_dian_qi_id
end

function cathode_id_convert_64 (last_button_id)  --负极转换地址33-64
    local ji_dian_qi_id = 64 - last_button_id
    return ji_dian_qi_id
end




function zi_ding_yi_jie_mian (screen,control,value)  --自定义界面选择状态以及发送继电器指令函数
    if screen ==1 then                       --在主界面，点击自定义模式
        if control == 7 and value == 1 then

            open_deivce()

            start_timer(2,300,0,1)   --打开定时器2，再发一遍20mA初始值
            Modify_button_enable = 1   --进入自定义界面，把调节强度解锁
        end
    end


    if screen == 3 then
        if control >= 1 and control <= 64 and control ~= last_button then
		    if green_button_count < green_button_max or red_button_count < red_button_max then  --判断是否选中过正极或负极
			    if last_button_state == 0 and last_button ~= control  then   --判断按钮状态是否为白色，如果为白色，将其置为蓝色
				    set_value (3,control,1)
				    last_button_state = 1
				    last_button = control
                else if last_button ~= control and last_button_state ~= 0 then  --判断是否为其他按钮，如果是其他按钮，将上一个按钮置为白色，当前按钮置为蓝色，绿色和红色按钮不变
                        if last_button_state ~= 2 and last_button_state ~= 3 then
                            set_value (3,last_button,0)
                        end
                        set_value (3,control,1)
                        last_button_state = 1
                        last_button = control
                        --print(last_button)
			        end
                end
                local new_button_flag = 1
			end
		end


        if green_button_count < green_button_max  then    --正极按钮按下后，将按钮置为绿色
            if (control == 70 and value == 1) and last_button_state ~=3 then
                if last_button >= 1 and last_button <= 32 then   ---如果按钮为1-32
                    zhan_id = 3                                  --站为3
                    addr_id = anode_id_convert_32 (last_button)   --调用id转换函数
                    mb_write_reg_06 (zhan_id,addr_id,1)           --向继电器发送控制指令
                end
                if last_button >= 33 and last_button <= 64 then
                    zhan_id = 1
                    addr_id = anode_id_convert_64 (last_button)
                    mb_write_reg_06 (zhan_id,addr_id,1)
                end
                set_value (3,last_button,2)
                last_button_state = 2
                if new_button_flag ==1 then
                    green_button_count = green_button_count + 1
                end
                set_enable(3,last_button,0)     --锁定按钮
                new_button_flag = 0
            end
        end


        if red_button_count < red_button_max  then    --负极按钮按下后，将按钮置为红色
            if (control == 71 and value == 1) and last_button_state ~=2 then
                if last_button >= 1 and last_button <= 32 then
                    zhan_id = 4
                    addr_id = cathode_id_convert_32 (last_button)
                    mb_write_reg_06 (zhan_id,addr_id,1)
                end
                if last_button >= 33 and last_button <= 64 then
                    zhan_id = 2
                    addr_id = cathode_id_convert_64 (last_button)
                    mb_write_reg_06 (zhan_id,addr_id,1)
                end
                set_value (3,last_button,3)
                last_button_state = 3
                if new_button_flag ==1 then
                    red_button_count = red_button_count + 1
                end
                set_enable(3,last_button,0)     --锁定按钮
                new_button_flag = 0

            end
        end


        if control == 72 and value == 1 then   --按下关闭按钮，将所有按钮状态复位
            for control = 1, 64, 1 do   --遍历64个按钮,ui状态刷新,解锁锁定
                set_value (3,control,0)
                set_enable(3,control,1)
            end

            close_deivce()

            --mb_write_reg_06 (1,52,0)   --将站1-4全部关闭
            start_timer(3,200,0,1)
            start_timer(4,400,0,1)
            start_timer(5,600,0,1)
            start_timer(6,800,0,1)

            open_deivce()
            
            last_button = 0  --将相应变量复位
            last_button_state = 0
            green_button_count = 0
            red_button_count = 0

            zdy_close_button = 1
            
        end


        if (control == 65 and value == 1) or (control == 66 and value == 1) then     --返回,或者home按键按下
            if zdy_close_button == 1 then
                set_text(3,78, "15")  --文本框复位
                set_text(3,77, "20")

                reset_deivce()
                Modify_button_enable = 0    --退出自定义，把调节强度禁用
            elseif zdy_close_button == 0 then
                for control = 1, 64, 1 do   --遍历64个按钮,ui状态刷新,解锁锁定
                    set_value (3,control,0)
                    set_enable(3,control,1)
                end
    

                set_text(3,78, "15")  --文本框复位
                set_text(3,77, "20")

                reset_deivce()

                Modify_button_enable = 0    --退出自定义，把调节强度禁用

                --将站1-4全部关闭
                start_timer(3,200,0,1)
                start_timer(4,400,0,1)
                start_timer(5,600,0,1)
                start_timer(6,800,0,1)

                
    
                last_button = 0  --将相应变量复位
                last_button_state = 0
                green_button_count = 0
                red_button_count = 0
    

            end

            zdy_close_button = 0

            
        end
 	end

    if Last_screen == 3 and screen == 1 and (control == 3 and value == 1) then   --主界面回退，重新进入自定义

        open_deivce()

        start_timer(2,300,0,1)   --打开定时器2，再发一遍20mA初始值
        Modify_button_enable = 1   --进入自定义界面，把调节强度解锁 
    end
end




function task (screen,control,value)   --任务
    if screen == 2 then   --任务列表
        if control == 6 and value == 1 then   --control = 6，食指
           

            if Left_right_hand_press == 0 then   --如果左右手没有按下过，则先禁用开始和暂停
                button_enable(4,6,9,9,0)
            end

            button_enable(4,4,10,13,0)  --禁用强度调节按钮

        end
        if control == 8 and value == 1 then   --control = 8，无名指
            
            if Left_right_hand_press == 0 then
                button_enable(4,6,9,9,0)
            end

            button_enable(6,6,10,13,0)  --禁用强度调节按钮

        end
        if control == 7 and value == 1 then   --control = 7，小指
            
            if Left_right_hand_press == 0 then
                button_enable(4,6,9,9,0)
            end

            button_enable(5,5,10,13,0)  --禁用强度调节按钮

        end
    end
    if screen == 4 or screen == 5 or screen == 6 then

        if control == 8 and value == 1 then     --按下开始按键
            if Left_right_hand_press == 0 then   --如果没有按下左右手
                set_visiable(screen,19,1)   --显示开始提示窗
                set_value(screen,8,0)   --开始按钮ui复位
                button_enable(screen,screen,1,7,0)  --禁用1-7
            else
 
                open_deivce()  --现在只需要发一遍就可以输出了，tmd太棒了，这个发现不亚于科伦布发现新大陆！！！！！

                if Current_20_flag == 1 and Countdown_time == 1800 then
                    start_timer(2,300,0,1)   --打开定时器2，再发一遍20mA初始值
                end

                Current_20_flag = 0
                Modify_button_enable = 1

                Pause_5s_flag = 0  --暂停5s标志置为0


                start_timer(7,5000,0,0)

                button_enable(screen,screen,1,7,0)  --禁用1-7


                set_value(screen,8,1)   --设置开始按键为按下
                set_enable(screen,8,0)  --禁用开始
                
                set_enable(screen,9,1)  --解锁暂停
                set_value(screen,9,0)   --设置暂停按键为松开

                if Countdown_time == 0 then
                    Countdown_time = Time_1800
                end


                Countdown_time_run = 1  --倒计时开始
                start_timer(8,1000,0,0)

                button_enable(screen,screen,10,13,1)   --将调节强度启用

                button_enable(screen,screen,4,5,0)  --禁用左右手

                if screen == 4 then    --食指继电器打开
                    if Left_hand == 1 then
                        --mb_write_reg_06(1,0,1)   --打开对应继电器，这里是为了测试，实际应用时，需要确定电极触点位置
                        start_timer(10,600,0,1)
                        start_timer(11,800,0,1)
                        start_timer(12,1200,0,1)
                        start_timer(13,1400,0,1)
                    end
                    if Right_hand == 1 then
                        start_timer(14,600,0,1)
                        start_timer(15,800,0,1)
                        start_timer(16,1200,0,1)
                        start_timer(17,1400,0,1)
                    end
                end


                if screen == 5 then    --小指继电器打开
                    if Left_hand == 1 then
                        start_timer(18,600,0,1)
                        start_timer(19,800,0,1)
                        start_timer(20,1200,0,1)
                        start_timer(21,1400,0,1)
                    end
                    if Right_hand == 1 then
                        start_timer(22,600,0,1)
                        start_timer(23,800,0,1)
                        start_timer(24,1200,0,1)
                        start_timer(25,1400,0,1)
                    end
                end


                if screen == 6 then    --无名指继电器打开
                    if Left_hand == 1 then
                        start_timer(26,600,0,1)
                        start_timer(27,800,0,1)
                        start_timer(28,1200,0,1)
                        start_timer(29,1400,0,1)
                    end
                    if Right_hand == 1 then
                        Borrow_timer = 1
                        start_timer(30,600,0,1)
                        start_timer(31,800,0,1)
                        start_timer(0,1200,0,1)
                        start_timer(1,1400,0,1)
                    end
                end
            end
        end



        if control == 9 and value == 1 then     --按下暂停按键，电刺激停止放电

            close_deivce()
            Modify_button_enable = 0
            Send_flag = 0
            stop_timer(1)  --关闭定时器
            stop_timer(2)
            stop_timer(7)


            stop_timer(9)  --暂停模式切换计时
      
            button_enable(screen,screen,10,13,0)   --暂停后将调节强度禁用
            button_enable(screen,screen,1,7,1)   --启用1-7

            set_enable(screen,9,0)  --禁用暂停
            set_enable(screen,8,1)

            Countdown_time_run = 0   --暂停倒计时

            set_value(screen,9,1)   --设置暂停按键为按下
            set_value(screen,8,0)   --设置开始按键为松开

            start_timer(3,200,0,1)  --四个站全关
            start_timer(4,400,0,1)
            start_timer(5,600,0,1)
            start_timer(6,800,0,1)

        end


        if (control == 1 and value == 1) or (control == 2 and value == 1) then   --按下返回键或者home键，将文本框8 和 9 复位，关闭继电器
            
            set_text(screen,15, "15")
            set_text(screen,14, "20")
            set_value(screen,8,0)   --将开始和暂停按键复位
            set_value(screen,9,0)

            --Regs_all[0] = 1    --开
            Regs_all[1] = 15   --脉宽
            Regs_all[2] = 20   --电流
            Regs_all[0] = 0

            --equipment_send_all(5,6,Regs_all)    --关闭电刺激

            Send_flag = 0
            Current_20_flag = 1

            Countdown_time = Time_1800

            set_text(screen,17,"30:00")   --刷新显示30分钟

            set_value(screen,16,360)   --刷新进度条


            
        end


        if control == 18 and value == 1 then    --任务完成提示窗
            set_visiable(screen,18,0)  --隐藏提示窗
            Modify_button_enable = 0
            Send_flag = 0
            stop_timer(1)  --关闭定时器
            stop_timer(2)
            stop_timer(7)
            stop_timer(9)  --暂停模式切换计时
            Countdown_time_run = 0   --暂停倒计时
            button_enable(get_current_screen(),get_current_screen(),1,9,1)
        end

        if control == 19 and value == 1 then   --点击开始提示窗
            set_visiable(screen,19,0)   --隐藏开始提示窗
            button_enable(screen,screen,1,7,1)   --解锁1-7
        end
    end
end



function modify_intensity (screen,control,value)
    if screen == 4 or screen == 5 or screen == 6 then

        --任务界面调节强度，只有在开始按键按下后才可以调节

        if control == 12 and value == 1 and Modify_button_enable == 1 then     --脉宽减
            if Regs_all[1] > pulse_min then
                Regs_all[1] = Regs_all[1] - 5
                regs_single[0] = Regs_all[1]
                equipment_send_single(5,7,regs_single)
                set_text(screen,15,regs_single[0])    --取消了通过tft设置的递减，改为代码直接写
            end
        end
        if control == 13 and value == 1 and Modify_button_enable == 1 then     --脉宽加
            if Regs_all[1] < pulse_max then
                Regs_all[1] = Regs_all[1] + 5
                regs_single[0] = Regs_all[1]
                equipment_send_single(5,7,regs_single)
                set_text(screen,15,regs_single[0])    --取消了通过tft设置的递增，改为代码直接写
            end
        end
        if control == 10 and value == 1 and Modify_button_enable == 1 then      --电流减
            if Regs_all[2] > current_min then
                Regs_all[2] = Regs_all[2] - 1
                regs_single[0] = Regs_all[2]
                equipment_send_single(5,8,regs_single)
                set_text(screen,14,regs_single[0])    --取消了通过tft设置的递减，改为代码直接写
            end
        end
        if control == 11 and value == 1 and Modify_button_enable == 1 then      --电流加
            if Regs_all[2] < current_max then
                Regs_all[2] = Regs_all[2] + 1
                regs_single[0] = Regs_all[2]
                equipment_send_single(5,8,regs_single)
                set_text(screen,14,regs_single[0])    --取消了通过tft设置的递增，改为代码直接写
            end
        end
    end
        --自定义界面的强度调节，只有在进入自定义界面才有效果
    if screen == 3 then
        
        if control == 75 and value == 1 and Modify_button_enable == 1 then     --脉宽减
            if Regs_all[1] > pulse_min then
                Regs_all[1] = Regs_all[1] - 5
                regs_single[0] = Regs_all[1]
                equipment_send_single(5,7,regs_single)
                set_text(screen,78,regs_single[0])    --取消了通过tft设置的递减，改为代码直接写
            end
        end
        if control == 76 and value == 1 and Modify_button_enable == 1 then     --脉宽加
            if Regs_all[1] < pulse_max then
                Regs_all[1] = Regs_all[1] + 5
                regs_single[0] = Regs_all[1]
                equipment_send_single(5,7,regs_single)
                set_text(screen,78,regs_single[0])    --取消了通过tft设置的递增，改为代码直接写
            end
        end
        if control == 73 and value == 1 and Modify_button_enable == 1 then      --电流减
            if Regs_all[2] > current_min then
                Regs_all[2] = Regs_all[2] - 1
                regs_single[0] = Regs_all[2]
                equipment_send_single(5,8,regs_single)
                set_text(screen,77,regs_single[0])    --取消了通过tft设置的递减，改为代码直接写
            end
        end
        if control == 74 and value == 1 and Modify_button_enable == 1 then      --电流加
            if Regs_all[2] < current_max then
                Regs_all[2] = Regs_all[2] + 1
                regs_single[0] = Regs_all[2]
                equipment_send_single(5,8,regs_single)
                set_text(screen,77,regs_single[0])    --取消了通过tft设置的递增，改为代码直接写
            end
        end
    end

end

function  on_control_notify (screen,control,value)
	zi_ding_yi_jie_mian (screen,control,value)
    task (screen,control,value)
    modify_intensity (screen,control,value)
    left_right_hand (screen,control,value)
    task_screen_switch (screen,control,value)
    --zidingyi_number_change(screen,control,value)
    light_modify (screen,control,value)
    modify_change_mode (screen,control,value)
    fallback_button (screen,control,value)
end
