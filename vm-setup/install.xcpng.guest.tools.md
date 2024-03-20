# Install XCP-NG Guest Tools on Debian VM

- Select the VM > Disks
- Click Select disks
- Click Guest Tools ISO
- Click on VM Console
- RUn the following:

```
sudo mount /dev/sr0 /media;
sudo /media/Linux/install.sh -n;
sudo reboot;
```

## Eject the Guest Tools from the VM
- Select the VM > Disks
- Eject the Guest Tools ISO

## Verify Guest tools active
- Select VM > General
- Should now see "Management Agent vX.Y detected".

## Verify guest reboots correctly
- Select Console, Click reboot.
- Confirm the reboot occurs (immediately) following the click of reboot button.

