#!/bin/dash

#Dependencies:
#lspci

#Optional Dependencies:
#lsusb Required for: USB Device list.
#lscpu Required for: Maximum CPU Clock speed.
#uname Required for: Basic system information (OS/Kernel/Arch/Hostname)
#mesa-demos (glxinfo) Required for: Detecting currently active GPU.
#lm_sensors (sensors) Required for: Detecting CPU Temps, and GPU temps on nouveau drivers.
#vulkan-tools (vulkaninfo) Required for: Detecting which graphics cards support vulkan and which versions of vulkan are available.

#TESTED ON:
#Manjaro
#Intel Desktop/Laptop
#Intel + Nvidia Dedicated/Optimus GPU(nvidia)

#UNTESTED:
#Ubuntu
#Debian
#CentOS
#AMD Desktop/Laptop
#AMD Dedicated GPU (Radeon, AMDGPU and Catalyst)
#AMD Integrated GPU (Radeon, AMDGPU and Catalyst)
#AMD + Nvidia Dedicated/Optimus GPU (nouveau and nvidia)
#AMD Hybrid Graphics (Radeon, AMDGPU and Catalyst)
#ATI Dedicated GPU (Radeon and FGLRX)
#Nvidia dedicated and optimus GPU (nouveau only)

#UNSUPPORTED:
#SLI/Crossfire
#AMD APU (Integrated Graphics).

if [ "$1" = "--less" ] || [ "$1" = "-l" ]; then #Add 'less' argument to display less information.
	less=1
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then #Help
	echo "Usage: sysinfo [option]
Options: 
	--less		Display less information.	
	-h --help	Display this dialog."

	exit
else
	less=0
fi
#lspci depcheck
if [ -f /usr/bin/lscpu ]; then
	CPUMax=$(lscpu | grep "max MHz" | cut -d: -f2 | sed 's: ::g' | cut -d ',' -f1)
	else
		echo "Error: lspci was not found, please install it for this script to work."
		exit
fi

#lscpu depcheck
if [ -f /usr/bin/lscpu ]; then
	:
	else
		echo "Please install lscpu to read CPU maximum frequency."
		echo ""
fi

#Sensor depcheck
if [ -f /usr/bin/sensors ]; then
	:
	else
		echo "Please install lm_sensors(sensors) to read CPU temperature values."
		echo ""
fi

#GLXinfo depcheck
if [ -f /usr/bin/glxinfo ]; then
	GPUActive=$(glxinfo 2>/dev/null | grep "renderer string" | cut -d ':' -f2) 
	GPUGLV=$(glxinfo 2>/dev/null | grep "OpenGL version" | cut -d ':' -f2)
	GPUMem=$(glxinfo 2>/dev/null | grep "Video memory" | cut -d ' ' -f7)
	else
		echo "Please install mesa-demos(glxinfo) to read some of the graphics related values."
		echo ""
fi

#Vulkaninfo depcheck
if [ -f /usr/bin/vulkaninfo ]; then
	VKGPU=$(vulkaninfo 2>/dev/null | grep "GPU id =" | sed 's/^[[:blank:]]*GPU id = /        /g' | sort -u)
	VKVer=$(vulkaninfo 2>/dev/null | grep apiVersion | cut -d '(' -f2 | sed 's:)::g')
	VKDrv=$(vulkaninfo 2>/dev/null | grep driverInfo | cut -d "=" -f2 | uniq)
	else
		echo "Please install vulkan-tools(vulkaninfo) to read information about vulkan."
		echo ""
fi

PDV=$(cat /sys/devices/virtual/dmi/id/sys_vendor)
PDN=$(cat /sys/devices/virtual/dmi/id/product_name)
MBM=$(cat /sys/devices/virtual/dmi/id/board_vendor)
MBN=$(cat /sys/devices/virtual/dmi/id/board_name)
MBV=$(cat /sys/devices/virtual/dmi/id/board_version)
BIOS=$(echo "$(cat /sys/devices/virtual/dmi/id/bios_vendor) Version:$(cat /sys/devices/virtual/dmi/id/bios_version) ($(cat /sys/devices/virtual/dmi/id/bios_date))")

CPUname=$(cat /proc/cpuinfo | grep -m 1 "model name" | cut -d':' -f2)
CPUVendor=$(cat /proc/cpuinfo | grep -m 1 "vendor_id" | cut -d':' -f2 | sed 's: ::g')
CPUTotal=$(cat /proc/cpuinfo | grep -m 1 siblings | cut -d' ' -f2)
CPUPhysical=$(cat /proc/cpuinfo | grep -m 1 "cpu cores" | cut -d' ' -f3)
CPULogical=$(( $CPUTotal - $CPUPhysical ))
CPUPerf=$(</proc/cpuinfo awk -F : '/MHz/{printf "    Core %d:%s MHz\n", n++, $2}')
if [ $CPUVendor=="GenuineIntel" ] && [ -f /usr/bin/sensors ]; then
    CPUTemp=$(sensors | grep 'id 0:' -m1 | cut -d ':' -f2 | sed 's:  +::g' | cut -d '(' -f1)
elif [ $CPUVendor=="AuthenticAMD" ] && [ -f /usr/bin/sensors ]; then
    CPUTemp=$(sensors | grep -A3 k10temp | grep 'Tctl\|temp1' | cut -d '+' -f2 | cut -d '(' -f1)
fi


MemoryT=$(cat /proc/meminfo | grep -Po "MemTotal:\K.*?(?=\ kB)" | sed 's: ::g')
Memory=$(cat /proc/meminfo | grep -Po "MemAvailable:\K.*?(?=\ kB)" | sed 's: ::g')
SwapT=$(cat /proc/meminfo | grep -Po "SwapTotal:\K.*?(?=\ kB)" | sed 's: ::g')
Swap=$(cat /proc/meminfo | grep -Po "SwapFree:\K.*?(?=\ kB)" | sed 's: ::g')
HugeS=$(cat /proc/meminfo | grep -Po "Hugepagesize:\K.*?(?=\ kB)" | sed 's: ::g')
HugeT=$(($HugeS * $(cat /proc/meminfo | grep "HugePages_Total:" | cut -d ' ' -f8)))

if lspci | grep -m1 "VGA compatible controller: Intel" > /dev/null; then
    GPUIntegrated=1
    GPUIntmodel=$(lspci -v | grep "VGA compatible controller: Intel" | cut -b 36-150 | cut -d '(' -f1)
    GPUIID=$(lspci | grep -m1 "VGA compatible controller: Intel" | cut -d 'V' -f1 | sed 's: ::g')
    GPUIDriver=$(lspci -vs $GPUIID | grep use | cut -d ':' -f2)
    GPUIPMem=$(lspci -vs $GPUIID | grep -m1 " prefetchable" | cut -d '=' -f2 | sed 's:]:B:g')
    #GPUIMem=$(DRI_PRIME=0 __NV_PRIME_RENDER_OFFLOAD=0 glxinfo | grep "Video memory" | cut -d ' ' -f7)
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
    if [ "$GPUDriver" = "nvidia" ]; then
		GPUMem=$(nvidia-smi | grep MiB -m1 | cut -d '|' -f3 | sed 's: ::g' |  sed 's:/: / :g')
		GPUPow=$(nvidia-smi | grep W | cut -d '/' -f2 | cut -c 14- | sed 's: ::g')
    fi
    if [ "$GPUDriver" = "nvidia" ]; then
		GPUTemp=$(nvidia-smi -q | grep "GPU Current Temp" | cut -d ':' -f2 | sed 's/ C/°C/g' | sed 's: ::g')
    elif [ -f /usr/bin/sensors ]; then
		GPUTemp="$(sensors | grep -A10 'nouveau' | grep -m1 temp1 | cut -d '+' -f2 | cut -d '(' -f1)"
    fi
elif lspci | grep -m1 "VGA compatible controller: Advanced" > /dev/null; then
    GPUDedicated=1
    GPUModel="AMD $(lspci | grep -m1 "VGA compatible controller: Advanced" | cut -d '[' -f3 | cut -d ']' -f1)"
    GPUDID=$(lspci | grep -m1 "VGA compatible controller: Advanced" | cut -d 'V' -f1)
    GPUDriver=$(lspci -vs $GPUDID | grep use | cut -d ':' -f2 | sed 's: ::g')
	GPUMem=$(DRI_PRIME=1 glxinfo 2>/dev/null | grep "Video memory" | cut -d ' ' -f7)
	if [ -f /usr/bin/sensors ]; then
		GPUTemp=sensors | grep amdgpu -m1 -A5 | grep "°C" | cut -d '+' -f2
	fi
elif lspci | grep -m1 "VGA compatible controller: ATI" > /dev/null; then
    GPUDedicated=1
    GPUModel="ATI $(lspci | grep -m1 "VGA compatible controller: ATI" | cut -d '[' -f3 | cut -d ']' -f1)"
    GPUDID=$(lspci | grep -m1 "VGA compatible controller: ATI" | cut -d 'V' -f1)
    GPUDriver=$(lspci -vs $GPUDID | grep use | cut -d ':' -f2 | sed 's: ::g')
	GPUTemp="Not Supported for radeon/fglrx/catalyst"
else
    GPUDedicated=0
fi
if [ $GPUDedicated -eq 0 ]; then
   if lspci | grep -m1 "3D controller: NVIDIA" > /dev/null; then
      GPUModel="NVIDIA $(lspci | grep -m1 "3D controller: NVIDIA" | cut -d '[' -f2 | cut -d ']' -f1)"
   elif lspci | grep -m1 "Display controller: Advanced" > /dev/null; then
      GPUModel="AMD $(lspci | grep -m1 "Display controller: Advanced" | cut -d '[' -f3 | cut -d ']' -f1)"
   elif lspci | grep -m1 "Display controller: ATI" > /dev/null; then
      GPUModel="ATI $(lspci | grep -m1 "Display controller: ATI" | cut -d '[' -f3 | cut -d ']' -f1)"
   else
      GPUModel="Not Available"
   fi
fi
 
case $(cat /sys/devices/virtual/dmi/id/chassis_type) in
	1) CHT="Other";;
	2) CHT="Unknown";;
	3) CHT="Desktop";;
	4) CHT="Low Profile Desktop";;
	5) CHT="Pizza Box";;
	6) CHT="Mini Tower";;
	7) CHT="Tower";;
	8) CHT="Portable";;
	9) CHT="Laptop";;
	10) CHT="Notebook";;
	11) CHT="Hand Held";;
	12) CHT="Docking Station";;
	13) CHT="All in One";;
	14) CHT="Sub Notebook";;
	15) CHT="Space-Saving";;
	16) CHT="Lunch Box";;
	17) CHT="Main System Chassis";;
	18) CHT="Expansion Chassis";;
	19) CHT="SubChassis";;
	20) CHT="Bus Expansion Chassis";;
	21) CHT="Peripheral Chassis";;
	22) CHT="Storage Chassis";;
	23) CHT="Rack Mount Chassis";;
	24) CHT="Sealed-Case PC";;
esac

if [ -f /usr/bin/uname ]; then
echo "System Information:"
echo "  Operating System: $(uname -o) $(uname -m)"
echo "  Kernel: $(uname -r)"
echo "  Hostname: $(uname -n)"

echo "" #Separator
fi

echo "Product Info:"
echo "  Product Type: $CHT"
echo "  Manufacturer: $PDV"
echo "  Model Name: $PDN"

echo "" #Separator

echo "Motherboard:"
echo "  Manufacturer: $MBM"
echo "  Model: $MBN"
if [ $less -ne 1 ]; then
	echo "  Version: $MBV"
	echo "  BIOS: $BIOS"
fi

echo "" #Separator

echo "Processor:"
echo "  Model:$CPUname"
echo "  Threads: $CPUTotal"
echo "    Physical Cores: $CPUPhysical"
echo "    Logical Cores: $CPULogical"
if [ -f /usr/bin/sensors ]; then
	echo "  Temperature: $CPUTemp"
	if [ $less -ne 1 ] && [ $CPUVendor=="GenuineIntel" ]; then
		echo "$(sensors | grep Core | cut -d '(' -f1 | sed 's:        +::g' | sed 's:Co:    Co:g')"
	fi
fi
if [ -f /usr/bin/lscpu ]; then
	echo "  Maximum Clock Speed: $CPUMax MHz"
fi
if [ $less -ne 1 ]; then
	echo "  Current Speeds:"
	echo "$CPUPerf"
fi

echo "" #Separator

echo "Memory:"
echo "  RAM: $(( $MemoryT / 1000 / 1000 ))GB" #Round to a 1000 to display a correctly rounded gigabyte value.
if [ $less -ne 1 ]; then
	echo "  RAM Reserved for VMs: $(( $HugeT / 1024 ))MB (HugePages)"
	echo "  RAM In Use: $((( $MemoryT - $Memory ) / 1024 ))MB"
	echo "  RAM Available: $(( $Memory / 1024 ))MB" #Not rounding to gigabytes because available memory may often be less than 1GB.
fi
	echo "  Swap: $(( $SwapT / 1024 ))MB"
if [ $less -ne 1 ]; then
	echo "  Swap In Use $((( $SwapT - $Swap) / 1024))MB"
	echo "  Swap Available: $(( $Swap / 1024 ))MB"
fi

echo "" #Separator

echo "Storage Devices:"
for x in `ls /sys/block/ `; do
    if echo "$x" | grep -q "loop"; then
        continue
    fi
	HDD=$(cat /sys/block/$x/queue/rotational)
	echo "  $(cat /sys/block/$x/device/model | sed 's/ *$//g') (/dev/$x): $(($(cat /sys/block/$x/size)*512/1024/1024/1024))GB"
done

echo "" #Separator

echo "Graphics:"

if [ $GPUIntegrated -eq 1 ]; then
	echo "  Integrated: $GPUIntmodel"
	echo "    Kernel Driver: $GPUIDriver"
	echo "    Preallocated Memory: $GPUIPMem"
#	echo "    Maximum Memory: $GPUIMem"
	if [ $less -ne 1 ]; then
		echo "    PCI SLOT: $GPUISLOT"
		echo "    PCI ID: $GPUIID"
	fi
else
	echo "  Integrated: Not Available"
fi

echo "" #Separator

if [ $GPUDedicated -eq 1 ]; then
	echo "  Dedicated: $GPUModel"
	echo "    Kernel Driver: $GPUDriver"
	echo "    Memory: $GPUMem"
	echo "    Temperature: $GPUTemp"
	if [ $less -ne 1 ]; then
		if [ "$GPUDriver" = "nvidia" ]; then
			echo "    Power Usage: $GPUPow"
		fi
		echo "    PCI SLOT: $GPUSLOT"
		echo "    PCI ID: $GPUDID"
	fi
else
	echo "  Dedicated: $GPUModel"
fi


if [ -f /usr/bin/glxinfo ]; then
echo "" #Separator
echo "  Active 3D Graphics Controller:$GPUActive"
echo "    OpenGL Version: $GPUGLV"
fi
if [ $less -ne 1 ]; then
if [ -f /usr/bin/glxinfo ] && [ -f /usr/bin/vulkaninfo ]; then
	echo "    Vulkan Compatible Graphics Cards:
$VKGPU"
	echo "    Vulkan Libraries:"

	buf=1
	vulkaninfo 2>/dev/null | grep driverName | cut -d "=" -f2 | uniq | while read -r line; do
		printf "        $((buf-1)): $line -"
		printf "$VKDrv\n" | sed "$buf!d" 
		printf "            Vulkan Version:"
		printf "$VKVer" | sed "$buf!d" 
		buf=$(($buf+1))
	done
	echo ""
fi
if lspci | grep "Display controller" >/dev/null; then
    GPUSwitch=$(lspci | grep -m1 "Display controller" | cut -d ':' -f3-6 | cut -d '(' -f1)
    echo "  Inactive: $GPUSwitch"
elif lspci | grep "3D controller" >/dev/null; then
    GPUSwitch=$(lspci | grep -m1 "3D controller" | cut -d ':' -f3-6 | cut -d '(' -f1)
    echo "  Inactive: $GPUSwitch"
fi

	echo "" #Separator

	echo "PCI Network Controllers:"
	echo "$(lspci | grep "Network" | sed 's=:=:  =g'| cut -d ':' -f3)"
	echo "$(lspci | grep "Ethernet" | sed 's=:=:  =g'| cut -d ':' -f3)"

	echo "" #Separator

	echo "PCI Audio Devices:"
	echo "$(lspci | grep "Audio" | sed 's=:=:  =g'| cut -d ':' -f3)"

	echo "" #Separator
	if [ -f /usr/bin/lsusb ]; then
		echo "USB Devices:"
		echo "$(lsusb | cut -d ':' -f3 | cut -c 5- | grep -v "root hub" | sed 's/^/  /')"
	else
		echo "Please install lsusb to read USB Device List."
		echo ""
	fi
fi
