### stores functions for encryption and decryption for Asg 6
## encrypts by adding corresponding key byte with buffer byte
## decrypts by subtracting corresponding key byte with buffer byte
## encrypts/decrypts 1024 bytes of data from input file at a time
	.include "SysCalls.asm"
	.globl encryptDecrypt
encryptDecrypt:
	# store $ra into stack
	addi $sp, $sp, -4
	sw	$ra, ($sp)
	move $s7, $v0	# $s7 = file descriptor for reading file 
	# open input and create output file, only close when encryption/decryption are done
	jal	createFile
	
## repeat loop until eof 
edlp:
	jal	readFile	# read input file
	# load addresses and set pointers
	la	$t0, key		# $t0 = key address 
	move $t2, $t0		# $t2 = initial address of key
	la	$t1, buffer		# $t1 = buffer address
	move $t5, $t1		# $t5 = initial address of buffer
	lb	$t3, ($t0)		# $t3 = key[i]
	lb	$t4, ($t1)		# $t4 = buffer[i]
	
	beq	$s4, $s1, encrypt1	# if $s4 == 1, encrypt
	beq	$s4, $s2, decrypt1	# else decrypt
	
# read each byte from buffer and add ASCII value of each key
encrypt1:
	lb	$t3, ($t0)		# $t3 = key[i]
	beq	$t3, 10, encrypt2	# moves key ptr back to first char
	sub	$t6, $t1, $t5		# $t6 = buffer current address - initial address
	beq	$t6, $s5, encrypt3	# if buffer is fully encoded, exit function
	lb	$t4, ($t1)		# $t4 = buffer[i]
	addu $t4, $t3, $t4	# encrypt! buffer[i] = key[i] + buffer[i]
	sb	$t4, ($t1)		# buffer[i] = encrypted buffer[i]
	addi $t0, $t0, 1	# key[i++]
	addi $t1, $t1, 1	# buffer[i++]
	j	encrypt1

# moves key ptr back to first char
encrypt2:
	move $t0, $t2
	lb	$t3, ($t0)
	j	encrypt1
	
# exit function
encrypt3:
	# write an encoded file containing buffer 
	jal	writeFile
	j	edlp	# repeat loop

# read each byte from buffer and add ASCII value of each key
decrypt1:
	lb	$t3, ($t0)		# $t3 = key[i]
	beq	$t3, 10, decrypt2	# moves key ptr back to first char
	sub	$t6, $t1, $t5		# $t6 = buffer current address - initial address
	beq	$t6, $s5, decrypt3	# if buffer is fully encoded, exit function
	lb	$t4, ($t1)		# $t4 = buffer[i]
	subu $t4, $t4, $t3	# decrypt! buffer[i] = buffer[i] - key[i]
	sb	$t4, ($t1)		# buffer[i] = encrypted buffer[i]
	addi $t0, $t0, 1	# key[i++]
	addi $t1, $t1, 1	# buffer[i++]
	j	decrypt1

# moves key ptr back to first char
decrypt2:
	move $t0, $t2
	lb	$t3, ($t0)
	j	decrypt1
	
# exit function
decrypt3:
	# write a decoded file containing buffer
	jal	writeFile
	j	edlp	# repeat loop
	
## writes encryption or decryption from buffer into output file
writeFile:	
	# write file with buffer data
	li	$v0, SysWriteFile
	move $a0, $s6			# $a0 = file descriptor
	la	$a1, buffer			# load buffer address 
	move $a2, $s5			# $a2 = # of bytes read in SysReadFile
	syscall
	
	# check if buffer has reached eof, exit function otherwise
	lb	$t0, buffer($s5)
	beq	$t0, '\0', encryptDecryptDone
	
	jr	$ra		# return to encrypt3 or decrypt3
	
## creates output file
createFile:
	# store $ra into stack, $ra = encryptDecrypt function
	addi $sp, $sp, -4
	sw	$ra, ($sp)
	li	$t0, 0		# $t0 = file ptr = index i
	beq	$s4, $s1, createFile1	# creates .enc file if encrypt
	beq	$s4, $s2, createFile2	# creates.txt file if decrypt
# converts file to .enc 
createFile1:
	jal	createFile3	# place ptr to the extension portion of address
	# store each ascii value to each register
	li	$t0, 'e'	
	li	$t1, 'n'	
	li	$t2, 'c'
	# store "enc" into file name
	sb	$t0, file($v0)
	addi $v0, $v0, 1
	sb	$t1, file($v0)
	addi $v0, $v0, 1
	sb	$t2, file($v0)
	
	# open output file 
	li	$v0, SysOpenFile
	la	$a0, file
	li	$a1, 1		# 0: read, 1: write
	li	$a2, 0		# mode ignored
	syscall
	
	move $s6, $v0	# $s6 = file descriptor for writing file	
	
	# exit function
	lw	$ra, ($sp)
	addi $sp, $sp, 4
	jr	$ra			# return to encryptDecrypt
# converts file to .txt 
createFile2:
	jal	createFile3	# place ptr to the extension portion of address
	li	$t0, 't'	
	li	$t1, 'x'	
	li	$t2, 't'
	# store "txt" into file name
	sb	$t0, file($v0)
	addi $v0, $v0, 1
	sb	$t1, file($v0)
	addi $v0, $v0, 1
	sb	$t2, file($v0)
	
	# open output file 
	li	$v0, SysOpenFile
	la	$a0, file
	li	$a1, 1		# 0: read, 1: write
	li	$a2, 0		# mode ignored
	syscall
	
	move $s6, $v0	# $s6 = file descriptor for writing file	
	
	# exit function
	lw	$ra, ($sp)
	addi $sp, $sp, 4
	jr	$ra			# return to encryptDecrypt
# place ptr to the extension portion
createFile3:
	lb	$t1, file($t0)	# $t1 = file[i]
	addi $t0, $t0, 1	# ptr++
	bne	$t1, '.', createFile3	# repeat loop while $t1 != '.'
	move $v0, $t0		# return ptr position
	jr	$ra				# return to caller (createFile1 or createFile2)
	
## reads input file
readFile:
	# read input file 
	li	$v0, SysReadFile
	move $a0, $s7	# $a0 = file descriptor
	la	$a1, buffer	# $a1 = buffer to store file contents
	li	$a2, 1024	# hard coded buffer length
	syscall
	
	beq	$v0, $0, encryptDecryptDone	# return to main if encryption/decryption is done
	move $s5, $v0	# $s5 = # of bytes read
	
	jr	$ra		# returns to encryptDecrypt
	
# closes input and output files and returns to main
encryptDecryptDone:
	# close input file
	li	$v0, SysCloseFile
	move $a0, $s7
	syscall
	
	li	$v0, SysCloseFile
	move $a0, $s6
	syscall
	
	# return to menu
	lw	$ra, ($sp)
	addi $sp, $sp, 4
	jr	$ra
