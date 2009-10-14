; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2009 Return Infinity -- see LICENSE.TXT
;
; SYSTEM CALL SECTION -- Accessible to user programs
; =============================================================================

align 16
db 'DEBUG: SYSCALLS '
align 16


%include "syscalls/string.asm"
%include "syscalls/screen.asm"
%include "syscalls/input.asm"
%include "syscalls/sound.asm"
%include "syscalls/debug.asm"
%include "syscalls/misc.asm"
%include "syscalls/smp.asm"
%include "syscalls/serial.asm"


; =============================================================================
; EOF
