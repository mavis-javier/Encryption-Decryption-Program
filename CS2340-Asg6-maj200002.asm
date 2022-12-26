# This program will perform an encryption or decryption for user
# Written by Mavis Javier, Assignment 6, due on April 21, 2022
# netID: maj200002

	.include "SysCalls.asm"
	
	.data	
## global data
# stores user input for filename
	.extern	file	1024
# stores data to be encrypted or decrypted
	.extern	buffer	1024
# stores user input for key
	.extern	key		61
	
## gets user inputs
# display prompt for user input
prompt:	.asciiz	"1: Encrypt the file.  2: Decrypt the file.  3. Exit\n"
# request file name to encrypt or decrypt
requestFile: .asciiz	"Enter file name: "
# request for key 
requestKey:	.asciiz	"Enter key: "

## error handlers
# display error if file does not exist
errorFile:	.asciiz	"File does not exist.\n"
# display error if key is invalid
errorKey:	.asciiz	"Invalid key.\n"

## global functions
	.globl	menu	# set menu to global	

	.text
li	$s1, 1	# flag to enrypt
li	$s2, 2	# flag to decrypt
li	$s3, 3	# flag to exit

# prompt user input until user decides to exit
menu:
	li	$v0, SysPrintString
	la	$a0, prompt
	syscall
	
	li	$v0, SysReadInt
	syscall
	move $s4, $v0	# $s4 = user input
	# if user enters 3, exit
	beq	$v0, $s3, exit
	beq	$v0, $s2, is2or1	# if user entered 2
	beq	$v0, $s1, is2or1	# if user entered 1
	j	menu	# repeat menu prompt otherwise

# requests file name and determines whether to encrypt or decrypt
is2or1:
	jal	clearStrings	# clear input addresses
	
	# displays prompt for filename
	li	$v0, SysPrintString
	la	$a0, requestFile
	syscall
	
	# reads user input for filename
	li	$v0, SysReadString
	la	$a0, file
	li	$a1, 1024
	syscall
	move $s0, $a0	# save file name to $s0
	
	# request for key used in encryption or decryption and check if valid
	li	$v0, SysPrintString
	la	$a0, requestKey
	syscall
	
	li	$v0, SysReadString
	la	$a0, key
	li	$a1, 61
	syscall
	# check if key is empty string, return error otherwise
	la	$t1, key	
	addi $t1, $t1, 1
	lb	$t0, ($t1)
	beq	$t0, '\0', error1
	
	# remove newline in file name user inputted earlier
	jal	readFile
	la	$s0, file		# $s0 = filename of null-terminated file name		
	
	# opens file and returns error if unable to open
	li	$v0, SysOpenFile
	la	$a0, file
	li	$a1, 0		# 0: reads file, 1 to write
	li	$a2, 0		# mode is ignored
	syscall
	blt	$v0, $zero, error2
	
	# determine whether to decrypt or encrypt
	jal	encryptDecrypt	
	
	# return to main menu
	j	menu

# removes newline in filename
readFile:
	addi $sp, $sp, -4	# save $ra into stack
	sw	$ra, ($sp)
	li	$t0, 0	
# loop through file name and replace null terminator with null
readFile1:
	lbu	$t1, file($t0)  		# $t1 = file[i], i = file ptr
	addiu $t0, $t0, 1			# file ptr++, traverse through file name
	bnez $t1, readFile1			# Keep looping readFile until null is found
	subiu $t0, $t0, 2    		# Otherwise remove last character
	sb	$zero, file($t0)		# store NULL instead
	# returns to main
	lw	$ra, ($sp)
	addi $sp, $sp, 4
	jr	$ra

## error functions
# displays errorKey 
error1:
	li	$v0, SysPrintString
	la	$a0, errorKey
	syscall
	j	menu

# displays error for opening file
error2:	
	li	$v0, SysPrintString
	la	$a0, errorFile
	syscall
	j	menu

# clears buffer, file, and key addresses
# clear global variables to null terminators before repeating loop
clearStrings:
	# while i != 1024, store '\0' in byte
	li	$t0, 0	# i = 0
	la	$t1, buffer
	la	$t2, file
	la	$t3, key
clear1:
	beq	$t0, 1024, clear2	# exit clearStrings
	sb	$0, ($t1)
	sb	$0, ($t2)
	sb	$0, ($t3)
	addi $t0, $t0, 1		# i++
	addi $t1, $t1, 1		# move pointer of buffer
	addi $t2, $t2, 1		# move pointer of file
	addi $t3, $t3, 1		# move pointer of key
	j	clear1
clear2: 
	jr	$ra
		
# terminates program
exit:
	li	$v0, SysExit
	syscall
