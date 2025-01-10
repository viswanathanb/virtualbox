VM_ID?=1
VM_NAME="n${VM_ID}"
VM_DIR="vms/$(VM_NAME)"
BOOT_DISK_SIZE="10000"  # Size in MB
DATA_DISK_SIZE="20000"  # Size in MB
ISO_PATH?="/home/vish/metal-amd64.iso"
MEM_SIZE="2048"    # Memory size in MB
NUM_CPUS="1"       # Number of CPUs
BRIDGE_ADAPTER="wlp58s0"  # Adjust this to the name of your network adapter

vm:
	mkdir -p $(VM_DIR)
	VBoxManage createvm --name $(VM_NAME) --ostype "Linux_64" --register

config:
	VBoxManage modifyvm $(VM_NAME) --memory $(MEM_SIZE) --cpus $(NUM_CPUS)
	VBoxManage modifyvm $(VM_NAME) --nic1 bridged --bridgeadapter1 $(BRIDGE_ADAPTER) --nictype1 82540EM
	VBoxManage modifyvm $(VM_NAME) --boot1 disk --boot2 dvd --boot3 none --boot4 none
	VBoxManage modifyvm $(VM_NAME) --graphicscontroller vmsvga
	VBoxManage modifyvm $(VM_NAME) --audio-driver none
	vboxmanage modifyvm $(VM_NAME) --macaddress1 0800271b220${VM_ID}

hdd:
	VBoxManage createhd --filename $(VM_DIR)/$(VM_NAME)_b.vdi --size $(BOOT_DISK_SIZE)
	VBoxManage createhd --filename $(VM_DIR)/$(VM_NAME)_d.vdi --size $(DATA_DISK_SIZE)

attach:
	VBoxManage storagectl $(VM_NAME) --name "SATA Controller" --add sata --controller IntelAhci

	VBoxManage storageattach $(VM_NAME) --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $(VM_DIR)/$(VM_NAME)_b.vdi
	VBoxManage storageattach $(VM_NAME) --storagectl "SATA Controller" --port 1 --device 0 --type hdd --medium $(VM_DIR)/$(VM_NAME)_d.vdi

	VBoxManage storagectl $(VM_NAME) --name "IDE Controller" --add ide
	VBoxManage storageattach $(VM_NAME) --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $(ISO_PATH)

node: vm config hdd attach

start:
	VBoxManage startvm $(VM_NAME) # --type=headless

stop:
	VBoxManage controlvm $(VM_NAME) poweroff
	sleep 5

delete:
	VBoxManage unregistervm $(VM_NAME) --delete
	sleep 5

clean:
	rm -rf $(VM_DIR)
	rm -rf ~/VirtualBox\ VMs/$(VM_NAME)