format binary as 'img'

file 'system/boot/mbr/Mbr.aex'
file 'Ampere.aex'

times 512*64-($-$$) db 0
















































