#!/bin/bash

#Dependencies (Recommended Extra Packages):
#mesa-demos (glxinfo)
#lm_sensors

#UNTESTED:
#AMD CPU (Should work same as intel)
#AMD Dedicated GPU (Radeon, AMDGPU and Catalyst)
#AMD Integrated GPU (Radeon, AMDGPU and Catalyst) Completely unsupported
#AMD Hybrid Graphics (Radeon, AMDGPU and Catalyst)
#ATI Dedicated GPU (Radeon and FGLRX)
#Nvidia Optimus GPU (nouveau & nvidia)
#Intel Integrated GPU
#SLI/Crossfire

#Sensor warning
if type sensors &> /dev/null; then
>/dev/null
else
echo "Please install lm-sensors to read temperature values."
echo ""
fi

#GLXinfo warning
if type glxinfo &> /dev/null; then
>/dev/null
else
echo "Please install mesa-demos(glxinfo) to read some of the graphics related values."
echo ""
fi

MBM=$(cat /sys/devices/virtual/dmi/id/board_vendor)
MBN=$(cat /sys/devices/virtual/dmi/id/board_name)
MBV=$(cat /sys/devices/virtual/dmi/id/board_version)

CPUname=$(cat /proc/cpuinfo | grep -m 1 "model name" | cut -d':' -f2)
CPUVendor=$(cat /proc/cpuinfo | grep -m 1 "vendor_id" | cut -d':' -f2 | sed 's: ::g')
CPUTotal=$(cat /proc/cpuinfo | grep -m 1 siblings | cut -d' ' -f2)
CPUPhysical=$(cat /proc/cpuinfo | grep -m 1 "cpu cores" | cut -d' ' -f3)
CPULogical=$(( $CPUTotal - $CPUPhysical ))
CPUMax=$(lscpu | grep "max MHz" | cut -d: -f2 | sed 's: ::g')
CPUPerf=$(</proc/cpuinfo awk -F : '/MHz/{printf "    Core %d:%s,MHz\n", n++, $2}')
if [ $CPUVendor=="GenuineIntel" ]; then
    CPUTemp=$(sensors | grep 'Physical id 0:' | cut -d ':' -f2 | sed 's:  +::g' | sed 's: +::g' | sed 's: =:=:g')
elif [ $CPUVendor=="AuthenticAMD" ]; then
    CPUTemp=$(sensors | grep -A3 k10temp | grep 'temp1' | cut -d ':' -f2 | sed 's:  +::g' | sed 's: +::g' | sed 's: =:=:g')
fi


MemoryT=$(cat /proc/meminfo | grep -Po "MemTotal:\K.*?(?=\ kB)" | sed 's: ::g')
Memory=$(cat /proc/meminfo | grep -Po "MemAvailable:\K.*?(?=\ kB)" | sed 's: ::g')
SwapT=$(cat /proc/meminfo | grep -Po "SwapTotal:\K.*?(?=\ kB)" | sed 's: ::g')
Swap=$(cat /proc/meminfo | grep -Po "SwapFree:\K.*?(?=\ kB)" | sed 's: ::g')

GPUActive=$(lspci -v | grep "VGA controller" | cut -b 36-150 | cut -d '(' -f1)
GPUGLV=$(glxinfo | grep "OpenGL version" | cut -d ':' -f2 | cut -d ' ' -f2)
GPULibs=$(glxinfo | grep "OpenGL version" | cut -d ':' -f2 | cut -d ' ' -f3-4)

if lspci | grep -m1 "VGA compatible controller: Intel" > /dev/null; then
    GPUIntegrated=1
    GPUIntmodel=$(lspci | grep -m1 "VGA compatible controller: Intel")
    GPUIID=$(lspci | grep -m1 "VGA compatible controller: Intel" | cut -d 'V' -f1 | sed 's: ::g')
    GPUIDriver=$(lspci -vs $GPUIID | grep use | cut -d ':' -f2)
    GPUIMem=$(lspci -vs $GPUIID | grep -m1 " prefetchable" | cut -d '=' -f2 | sed 's:]:B:g')
    GPUISLOT=$(lspci -n | grep $GPUIID | cut -d ' ' -f3)
else
    GPUIntegrated=0
fi
if lspci | grep -m1 "VGA compatible controller: NVIDIA" > /dev/null; then
    GPUDedicated=1
    GPUModel="NVIDIA $(lspci | grep -m1 "VGA compatible controller: NVIDIA" | cut -d '[' -f2 | cut -d ']' -f1)"
    GPUDID=$(lspci | grep -m1 "VGA compatible controller: NVIDIA" | cut -d 'V' -f1)
    GPUDriver=$(lspci -vs $GPUDID | grep use | cut -d ':' -f2 | sed 's: ::g')
    GPUSLOT=$(lspci -n | grep $GPUDID | cut -d ' ' -f3)
    if [[ $GPUDriver == "nvidia" ]]; then
	GPUMem=$(nvidia-smi | grep MiB | cut -d '/' -f5 | cut -d '|' -f1 | sed 's: ::g')
    else
	GPUMem=$(glxinfo | grep "Video memory" | cut -d ' ' -f7)
    fi
    if [[ $GPUDriver == "nvidia" ]]; then
	GPUTemp=$(nvidia-settings -q gpucoretemp | grep "):" | sed 's/://g' | cut -d ')' -f2 | cut -d '.' -f1 | sed 's: ::g')°C
    else
	GPUTemp="$(sensors | grep -A10 'nouveau' | grep -m1 temp1 | cut -d '+' -f2 | cut -d '(' -f1)"
    fi
elif lspci | grep -m1 "VGA compatible controller: Advanced" > /dev/null; then
    GPUDedicated=1
    GPUModel="AMD $(lspci | grep -m1 "VGA compatible controller: Advanced" | cut -d '[' -f3 | cut -d ']' -f1)"
    GPUDID=$(lspci | grep -m1 "VGA compatible controller: Advanced" | cut -d 'V' -f1)
    GPUDriver=$(lspci -vs $GPUDID | grep use | cut -d ':' -f2 | sed 's: ::g')
    GPUMem=$(glxinfo | grep "Video memory" | cut -d ' ' -f7)
elif lspci | grep -m1 "VGA compatible controller: ATI" > /dev/null; then
    GPUDedicated=1
    GPUModel="ATI $(lspci | grep -m1 "VGA compatible controller: ATI" | cut -d '[' -f3 | cut -d ']' -f1)"
    GPUDID=$(lspci | grep -m1 "VGA compatible controller: ATI" | cut -d 'V' -f1)
    GPUDriver=$(lspci -vs $GPUDID | grep use | cut -d ':' -f2 | sed 's: ::g')
    GPUMem=$(glxinfo | grep "Video memory" | cut -d ' ' -f7)
else
   GPUDedicated=0
fi

echo "Motherboard:"
echo "  Manufacturer: $MBM"
echo "  Model: $MBN"
echo "  Version: $MBV"

echo "" #Separator

echo "Processor:"
echo "  Model:$CPUname"
echo "  Cores: $CPUTotal"
echo "    Physical: $CPUPhysical"
echo "    Threads: $CPUTotal"
if type sensors &> /dev/null ; then
    echo "  Temperature: $CPUTemp"
if [ $CPUVendor=="GenuineIntel" ]; then
    echo "$(sensors | grep Core | cut -d '(' -f1 | sed 's:        +::g' | sed 's:Co:    Co:g')"
fi
fi
echo "  Maximum Clock Speed: $CPUMax,MHz"
echo "  Current Speeds:"
echo "$CPUPerf"

echo "" #Separator

echo "Memory:"
echo "  RAM: $(( $MemoryT / 1000 / 1000 ))GB" #Round to a 1000 to display a correctly rounded gigabyte value.
echo "  RAM In Use: $((( $MemoryT - $Memory ) / 1024 ))MB"
echo "  RAM Available: $(( $Memory / 1024 ))MB" #Not rounding to gigabytes because available memory may often be less than 1GB.
echo "  Swap: $(( $SwapT / 1024 ))MB"
echo "  Swap In Use $((( $SwapT - $Swap) / 1024))MB"
echo "  Swap Available: $(( $Swap / 1024 ))MB"

echo "" #Separator

echo "Graphics:"

if [ $GPUIntegrated -eq 1 ]; then
echo "  Integrated: $GPUIntmodel"
echo "    Driver: $GPUIDriver"
echo "    Memory: $GPUIMem"
echo "    PCI SLOT: $GPUISLOT"
echo "    PCI ID: $GPUIID"
else
echo "  Integrated: Not Available"
fi

echo "" #Separator

if [ $GPUDedicated -eq 1 ]; then
echo "  Dedicated: $GPUModel"
echo "    Driver: $GPUDriver"
echo "    Memory: $GPUMem"
echo "    Temperature: $GPUTemp"
echo "    PCI SLOT: $GPUSLOT"
echo "    PCI ID: $GPUDID"
else
echo "  Dedicated: Not Available"
fi

echo "" #Separator

echo "  Active: $GPUActive"
echo "    OpenGL Version: $GPUGLV"
echo "    Library: $GPULibs"
if lspci | grep "Display controller" >/dev/null; then
    GPUSwitch=$(lspci | grep -m1 "Display controller" | cut -d ':' -f3-6 | cut -d '(' -f1)
    echo "  Inactive: $GPUSwitch"
elif lspci | grep "3D controller" >/dev/null; then
    GPUSwitch=$(lspci | grep -m1 "3D controller" | cut -d ':' -f3-6 | cut -d '(' -f1)
    echo "  Inactive: $GPUSwitch"
fi
