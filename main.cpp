#include<iostream>
#include<stdlib.h>
#include"GPIO.h"

int main()
{
    GPIO led(88);
    led.setDirection("out");
    while(1)
    {
        led.setValue(true);  // 输出高电平，点亮LED
            sleep(1);
            led.setValue(false); // 输出低电平，熄灭LED
            sleep(1);
    }
    return 0;
} 