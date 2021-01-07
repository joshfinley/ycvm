// YC VM
// --------------------------
// Architecture:
//  - Load-store ISA
//  - Minimal instruction set
//  - Arbitary 0x
//  - 16 bit
// 
// Instruction Format:
//	- Fixed length (16 bits):
//	- Encoding scheme:
//			
//	   src____,  ,__.imm flag
//		     / /  /
//    0b0001001001100001
//		\__\   \   \___\
//		  \  dest    \
//		   opcode     immediate value
// --------------------------


/* YC VM Structs */
struct Opcode {
	op_br 	byte
	op_add 	byte = 1
	op_ld 	byte = 2
	op_st 	byte = 3
	op_and 	byte = 4
	op_not  byte = 5
	op_ldi  byte = 6
	op_sti  byte = 7
	op_jmp  byte = 8
	op_lea  byte = 9
	op_trap byte = 10
}

struct Flaglist {
	fl_pos byte = 1 << 0
	fl_zro byte = 1 << 1
	fl_neg byte = 1 << 2
}

struct Reglist {
	r_r0 byte 
	r_r1 byte = 1
	r_r2 byte = 2
	r_r3 byte = 3
	r_pc byte = 4
	r_cond byte = 5
	r_count int = 6
}

struct Machine {
	mut:
		reglist 	Reglist
		flaglist  	Flaglist
		register 	[6]u16
		memory 		[0xffff]u16
		running 	bool
}

/* Operation Functions */

// Sign extend a 16 bit number
fn sign_extend(x u16, nbits int) u16 {
	mut y := x
	if (x >> (nbits - 1)) & 1 != 0 {
		y |= (0xffff << nbits)
	}
	return y
}

fn update_flags(
	mut machine &Machine, 
	r int) 
{
	if machine.register[r] == 0 {
		machine.register[machine.reglist.r_cond] = machine.flaglist.fl_zro
	}
	else if machine.register[r] >> 15 != 0 {
		// a one in the left most bit indicates neg
		machine.register[machine.reglist.r_cond] = machine.flaglist.fl_neg
	}
	else {
		machine.register[machine.reglist.r_cond] = machine.flaglist.fl_pos
	}

}

fn vmop_add(mut machine &Machine, instr u16) {
	r0 := (instr >> 9) & 0x7
	r1 := (instr >> 6) & 0x7
	imm_flag := (instr >> 6) & 0x1 // Immediate mode?

	if imm_flag != 0 {
		imm5 := sign_extend(instr & 0x1f, 5)
		machine.register[r0] = machine.register[r1] + imm5
	}
	else {
		machine.register[r0] += machine.register[r1]
	}

	update_flags(mut machine, machine.register[r0])
}

/* Machine Functions */

// Read a Machine memory location
fn yc_readmem(machine &Machine, address int) u16 {
	return machine.memory[address]
}

// Create a Machine
fn yc_init() Machine {
	mut machine := Machine{}
	reglist := Reglist{}

	machine.register[reglist.r_pc] = 0xff
	return machine
}

// Execute Machine
fn yc_run() {
	reglist := Reglist{}
	opcode := Opcode{}

	mut machine := yc_init()
	machine.running = true
	
	for machine.running {
		// Fetch next instruction
		mut instr := yc_readmem(
			machine,
			machine.register[reglist.r_pc])
		op := instr >> 12

		if op == opcode.op_add {
			vmop_add(mut &machine, instr)
		}
		

	}

}

fn main() {
	yc_run()
}
