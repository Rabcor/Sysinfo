# Sysinfo
A quick and easy bash script that prints basic system information (Motherboard, CPU, RAM/Swap, GPU)

Version: **0.8**

Dependencies:

* mesa-demos (glxinfo)
* lm-sensors (for temperature readings)

Please share if you notice any bugs, I have not tested this on any AMD hardware (it should work though) so any feedback would be nice.

ToDo:
* Test more thoroughly on switchable graphics/laptops
* Support multiple GPUs
* Test AMD CPU/GPU combination results and AMDGPU (if you want to help and have such a setup, please share your **lspci -v**)
* More thoroughly test Nouveau and Radeon drivers
* Test older Intel and Nvidia hardware combinations (Core 2 series/GT 8000 series)
* Test older AMD and ATI combinations (AMD Phenom/Radeon 4000 series)
