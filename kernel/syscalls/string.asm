; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2009 Return Infinity -- see LICENSE.TXT
;
; String Functions
; =============================================================================

align 16
db 'DEBUG: STRING   '
align 16


; -----------------------------------------------------------------------------
; os_int_to_string -- Convert a binary interger into an string string
;  IN:	RAX = binary integer
;		RDI = location to store string
; OUT:	RDI = pointer to end of string
;		All other registers preserved
; Min return value is 0 and max return value is 18446744073709551615 so your
; string needs to be able to store at least 21 characters (20 for the number
; and 1 for the string terminator).
; Adapted from http://www.cs.usfca.edu/~cruse/cs210s09/rax2uint.s
os_int_to_string:
	push rdx
	push rcx
	push rbx
	push rax

	mov rbx, 10								; base of the decimal system
	xor rcx, rcx							; number of digits generated
os_int_to_string_next_divide:
	xor rdx, rdx							; RAX extended to (RDX,RAX)
	div rbx									; divide by the number-base
	push rdx								; save remainder on the stack
	inc rcx									; and count this remainder
	cmp rax, 0x0							; was the quotient zero?
	jne os_int_to_string_next_divide		; no, do another division
os_int_to_string_next_digit:
	pop rdx									; else pop recent remainder
	add dl, '0'								; and convert to a numeral
	mov [rdi], dl							; store to memory-buffer
	inc rdi
	loop os_int_to_string_next_digit		; again for other remainders
	mov al, 0x00
	stosb									; Store the null terminator at the end of the string

	pop rax
	pop rbx
	pop rcx
	pop rdx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_to_int -- Convert a string into a binary interger
;  IN:	RSI = location of string
; OUT:	RAX = integer value
;		All other registers preserved
; Adapted from http://www.cs.usfca.edu/~cruse/cs210s09/uint2rax.s
os_string_to_int:
	push rsi
	push rdx
	push rcx
	push rbx

	xor rax, rax	; initialize accumulator
	mov rbx, 10		; decimal-system's radix
nxdgt:
	mov cl, [rsi]	; fetch next character

	cmp cl, '0'		; char preceeds '0'?
	jb inval		; yes, not a numeral
	cmp	cl, '9'		; char follows '9'?
	ja inval		; yes, not a numeral
	
	mul rbx			; ten times prior sum
	and rcx, 0xF	; convert char to int
	add rax, rcx	; add to prior total

	inc rsi			; advance source index
	jmp nxdgt		; and check another char	
inval:

	pop rbx
	pop rcx
	pop rdx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_int_to_hex_string -- Convert an integer to a hex string
;  IN:	RAX = Integer value
;		RDI = location to store string
; OUT:	Nothing. All registers preserved
;		All other registers preserved
os_int_to_hex_string:
	push rdi
	push rdx
	push rcx
	push rbx
	push rax

	mov rcx, 16								; number of nibbles. 64 bit = 16 nibbles = 8 bytes
os_int_to_hex_string_next_nibble:	
	rol rax, 4								; next nibble into AL
	mov bl, al								; copy nibble into BL
	and rbx, 0x0F							; and convert to word
	mov dl, [hextable + rbx]				; lookup ascii numeral
	push rax
	mov al, dl
	stosb
	pop rax
	loop os_int_to_hex_string_next_nibble	; again for next nibble
	xor rax, rax							; clear RAX to 0
	stosb									; Store AL to terminate string

	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_hex_string_to_int -- convert up to 8 hexascii to bin
;  IN:	RSI = Location of hex asciiz string
; OUT:	RAX = binary value of hex string
;		All other registers preserved
os_hex_string_to_int:
	push rsi
	push rcx
	push rbx

	cld
	xor rbx, rbx
os_hex_string_to_int_loop:
	lodsb
	mov cl, 4
	cmp al, 'a'
	jb os_hex_string_to_int_ok1
	sub al, 0x20						;convert to upper case if alpha
os_hex_string_to_int_ok1:
	sub al, '0'							;check if legal
	jc os_hex_string_to_int_exit		;jmp if out of range
	cmp al, 9
	jle os_hex_string_to_int_got		;jmp if number is 0-9
	sub al, 7							;convert to number from A-F or 10-15
	cmp al, 15							;check if legal
	ja os_hex_string_to_int_exit		;jmp if illegal hex char
os_hex_string_to_int_got:
	shl rbx, cl
	or bl, al
	jmp os_hex_string_to_int_loop
os_hex_string_to_int_exit:
	mov rax, rbx						; int value stored in RBX, move to RAX

	pop rbx
	pop rcx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_length -- Return length of a string
;  IN:	RSI = string location
; OUT:	RAX = length
;		All other registers preserved
os_string_length:
	push rdi
	push rcx

	xor rcx, rcx
	xor rax, rax
	mov rdi, rsi
	not rcx
	cld
	repne scasb	; compare byte at RDI to value in AL
	not rcx
	dec rcx
	mov rax, rcx
	
	pop rcx
	pop rdi
	ret
; -----------------------------------------------------------------------------

	
; -----------------------------------------------------------------------------
; os_find_char_in_string -- Find first location of character in a string
;  IN:	RSI = string location
;		AL = character to find
; OUT:	RAX = location in string, or 0 if char not present
;		All other registers preserved
os_find_char_in_string:
	push rsi
	push rcx

	mov rcx, 1		; Counter -- start at first char

os_find_char_in_string_more:
	cmp byte [rsi], al
	je os_find_char_in_string_done
	cmp byte [rsi], 0
	je os_find_char_in_string_notfound
	inc rsi
	inc rcx
	jmp os_find_char_in_string_more

os_find_char_in_string_done:
	mov rax, rcx

	pop rcx
	pop rsi
	ret

os_find_char_in_string_notfound:
	pop rcx
	pop rsi
	xor rax, rax	; not found, set RAX to 0
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_charchange -- Change all instances of a character in a string
;  IN:	RSI = string location
;		AL = character to replace
;		BL = replacement character
; OUT:	All registers preserved
os_string_charchange:
	push rsi
	push rcx
	push rbx
	push rax

	mov cl, al

loopit:
	mov byte al, [rsi]
	cmp al, 0
	je finishit
	cmp al, cl
	jne nochange

	mov byte [rsi], bl

nochange:
	inc rsi
	jmp loopit

finishit:
	pop rax
	pop rbx
	pop rcx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_copy -- Copy the contents of one string into another
;  IN:	RSI = source
;		RDI = destination
; OUT:	Nothing. All registers preserved
; Note:	It is up to the programmer to ensure that there is sufficient space in the destination
os_string_copy:
	push rsi
	push rdi
	push rax

os_string_copy_more:
	lodsb				; Load a character from the source string
	stosb
	cmp al, 0			; If source string is empty, quit out
	jne os_string_copy_more

	pop rax
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_truncate -- Chop string down to specified number of characters
;  IN:	RSI = string location
;		RAX = number of characters
; OUT:	Nothing. All registers preserved
os_string_truncate:
	push rsi

	add rsi, rax
	mov byte [rsi], 0x00

	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_join -- Join two strings into a third string
;  IN:	RAX = string one
;		RBX = string two
;		RDI = destination string
; OUT:	Nothing. All registers preserved
; What should it do with the null chars????
os_string_join:
	push rsi
	push rdi
	push rbx
	push rax

	mov rsi, rax		; Copy first string to location in RDI
	call os_string_copy

	call os_string_length	; Get length of first string

	add rdi, rax		; Position at end of first string

	mov rsi, rbx		; Add second string onto it
	call os_string_copy

	pop rax
	pop rbx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_chomp -- Strip leading and trailing spaces from a string
;  IN:	RSI = string location
; OUT:	Nothing. All registers preserved
os_string_chomp:
	push rsi
	push rdi
	push rax

	mov rdi, rsi	; RDI will point to the start of the string
	push rdi		; while RSI will point to the "actual" start (without the spaces)
	call os_string_length
	add rdi, rax

os_string_chomp_findend:	; we start at the end of the string and move backwards until we don't find a space
	dec rdi
	cmp byte [rdi], ' '
	je os_string_chomp_findend

	inc rdi					; we found the real end of the string so null terminate it
	mov byte [rdi], 0x00
	pop rdi

os_string_chomp_start_count:	; read through string until we find a non-space character
	cmp byte [rsi], ' '
	jne copyit
	inc rsi
	jmp os_string_chomp_start_count

; At this point RSI points to the actual start of the string (minus the leading spaces, if any)
; And RDI point to the start of the string

copyit:		; Copy a byte from RSI to RDI one byte at a time until we find a NULL
	lodsb
	stosb
	cmp al, 0x00
	jne copyit

os_string_chomp_done:
	pop rax
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_strip -- Removes specified character from a string
;  IN:	RSI = string location
;		AL = character to remove
; OUT:	Nothing. All registers preserved
os_string_strip:
	push rsi
	push rdi
	push rbx
	push rax
	
	mov rdi, rsi

	mov bl, al		; copy the char into BL since LODSB and STOSB use AL
nextchar:
	lodsb
	stosb
	cmp al, 0x00	; check if we reached the end of the string
	je finish		; if so bail out
	cmp al, bl		; check to see if the character we read is the interesting char
	jne nextchar	; if not skip to the next character

skip:				; if so the fall through to here
	dec rdi			; decrement RDI so we overwrite on the next pass
	jmp nextchar

finish:
	pop rax
	pop rbx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_compare -- See if two strings match
;  IN:	RSI = string one
;		RDI = string two
; OUT:	Carry flag set if same
os_string_compare:
	push rsi
	push rdi
	push rbx
	push rax

os_string_compare_more:
	mov al, [rsi]			; Store string contents
	mov bl, [rdi]

	cmp al, 0		; End of first string?
	je os_string_compare_terminated

	cmp al, bl
	jne os_string_compare_not_same

	inc rsi
	inc rdi
	jmp os_string_compare_more

os_string_compare_not_same:
	pop rax
	pop rbx
	pop rdi
	pop rsi
	clc
	ret

os_string_compare_terminated:
	cmp bl, 0		; End of second string?
	jne os_string_compare_not_same

	pop rax
	pop rbx
	pop rdi
	pop rsi
	stc
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_uppercase -- Convert zero-terminated string to uppercase
;  IN:	RSI = string location
; OUT:	Nothing. All registers preserved
os_string_uppercase:
	push rsi

os_string_uppercase_more:
	cmp byte [rsi], 0x00				; Zero-termination of string?
	je os_string_uppercase_done			; If so, quit

	cmp byte [rsi], 97					; In the uppercase A to Z range?
	jl os_string_uppercase_noatoz
	cmp byte [rsi], 122
	jg os_string_uppercase_noatoz

	sub byte [rsi], 0x20				; If so, convert input char to lowercase

	inc rsi
	jmp os_string_uppercase_more

os_string_uppercase_noatoz:
	inc rsi
	jmp os_string_uppercase_more

os_string_uppercase_done:
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_lowercase -- Convert zero-terminated string to lowercase
;  IN:	RSI = string location
; OUT:	Nothing. All registers preserved
os_string_lowercase:
	push rsi

os_string_lowercase_more:
	cmp byte [rsi], 0x00		; Zero-termination of string?
	je os_string_lowercase_done			; If so, quit

	cmp byte [rsi], 65		; In the lowercase A to Z range?
	jl os_string_lowercase_noatoz
	cmp byte [rsi], 90
	jg os_string_lowercase_noatoz

	add byte [rsi], 0x20		; If so, convert input char to uppercase

	inc rsi
	jmp os_string_lowercase_more

os_string_lowercase_noatoz:
	inc rsi
	jmp os_string_lowercase_more

os_string_lowercase_done:
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_get_time_string -- Store the current time in a string in format "HH:MM:SS"
;  IN:	RDI = location to store string (must be able to fit 9 bytes, 8 data plus null terminator)
; OUT:	Nothing. All registers preserved
os_get_time_string:
	push rdi
	push rbx
	push rax

	mov rbx, hextable

	mov al, 0x04		; hour
	out 0x70, al
	in al, 0x71
	call os_get_time_string_processor

	mov al, ':'
	stosb

	mov al, 0x02		; minute
	out 0x70, al
	in al, 0x71
	call os_get_time_string_processor

	mov al, ':'
	stosb

	mov al, 0x00		; second
	out 0x70, al
	in al, 0x71
	call os_get_time_string_processor

	mov al, 0x00		; Terminate the string
	stosb

	pop rax
	pop rbx
	pop rdi
	ret

os_get_time_string_processor:	
	push rax	; save rax for the next part
	shr al, 4	; we want to work on the high part so shift right by 4 bits
	xlatb
	stosb

	pop rax
	and al, 0x0f	; we want to work on the low part so clear the high part
	xlatb
	stosb
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_get_date_string -- Store the current time in a string in format "YYYY/MM/DD"
;  IN:	RDI = location to store string (must be able to fit 11 bytes, 10 data plus null terminator)
; OUT:	Nothing. All registers preserved
; Note:	Uses the os_get_time_string_processor function
os_get_date_string:
	push rdi
	push rbx
	push rax

	mov rbx, hextable

	mov al, 0x32		; century
	out 0x70, al
	in al, 0x71
	call os_get_time_string_processor
	mov al, 0x09		; year
	out 0x70, al
	in al, 0x71
	call os_get_time_string_processor

	mov al, '/'
	stosb

	mov al, 0x08		; month
	out 0x70, al
	in al, 0x71
	call os_get_time_string_processor

	mov al, '/'
	stosb

	mov al, 0x07		; day
	out 0x70, al
	in al, 0x71
	call os_get_time_string_processor

	mov al, 0x00		; Terminate the string
	stosb

	pop rax
	pop rbx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_is_digit -- 
;  IN:	AL = ASCII char
; OUT:	EQ flag set if numeric
; Note:	JE (Jump if Equal) can be used after this function is called
os_is_digit:
	cmp al, '0'
	jb not_digit
	cmp al, '9'
	ja not_digit
	cmp al, al			; To set the equal flag
not_digit:
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_is_alpha -- 
;  IN:	AL = ASCII char
; OUT:	EQ flag set if alpha
; Note:	JE (Jump if Equal) can be used after this function is called
os_is_alpha:
	cmp al, ' '
	jb not_alpha
	cmp al, 0x7E
	ja not_alpha
	cmp al, al			; To set the equal flag
not_alpha:
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
