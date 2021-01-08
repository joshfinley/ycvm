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


/* Architecture Consts */
const (
	op_br	= byte(0)
	op_add 	= byte(1)
	op_ld 	= byte(2)
	op_st 	= byte(3)
	op_and 	= byte(4)
	op_not  = byte(5)
	op_ldi  = byte(6)
	op_sti  = byte(7)
	op_jmp  = byte(8)
	op_lea  = byte(9)
	op_trap = byte(10)
)

const (
	fl_pos = byte(1 << 0)
	fl_zro = byte(1 << 1)
	fl_neg = byte(1 << 2)
)

const (
	r_r0 = byte(0)
	r_r1 = byte(1)
	r_r2 = byte(2)
	r_r3 = byte(3)
	r_pc = byte(4)
	r_cond = byte(5)
	r_count = 6
)

/* YC VM Structs */
struct Machine {
	mut:
		register 	[6]u16
		memory 		[0xffff]u16
		running 	bool
		instr 		u16
}

/* Machine Functions */

// Read a Machine memory location
fn yc_readmem(machine &Machine, address int) u16 {
	return machine.memory[address]
}

// Create a Machine
fn yc_init() Machine {
	mut machine := Machine{}
	machine.register[r_pc] = 0xff
	
	return machine
}

// Sign extend a 16 bit number
fn sign_extend(x u16, nbits int) u16 {
	mut y := x
	if (x >> (nbits - 1)) & 1 != 0 {
		y |= (0xffff << nbits)
	}
	return y
}

// Set status flag
fn update_flags(
	mut machine &Machine, 
	r int) 
{
	if machine.register[r] == 0 {
		machine.register[r_cond] = fl_zro
	}
	else if machine.register[r] >> 15 != 0 {
		// a one in the left most bit indicates neg
		machine.register[r_cond] = fl_neg
	}
	else {
		machine.register[r_cond] = fl_pos
	}
}



/* Operation Functions */

// Add registers or register and immediate
fn vmop_add(mut machine &Machine) {
	mut instr := machine.instr
	r0 := (instr >> 9) & 0x7
	r1 := (instr >> 6) & 0x7
	imm_flag := (instr >> 6) & 0x1 	// Immediate mode?

	if imm_flag != 0 {
		imm5 := sign_extend(instr & 0x1f, 5)
		machine.register[r0] = machine.register[r1] + imm5
	}
	else {
		machine.register[r0] += machine.register[r1]
	}

	update_flags(mut machine, machine.register[r0])
}

// Calculate bitwise AND of registers or register and imm
fn vmop_and(mut machine &Machine) {
	mut instr := machine.instr 
	r0 := (instr >> 9) & 0x7
	imm_flag := (instr >> 6) & 0x1 

	if imm_flag != 0 {
		imm5 := sign_extend(instr & 0x1f, 5)
		machine.register[r0] = machine.register[r0] & imm5 
	}
	else {
		r1 := (instr >> 6) & 0x7
		machine.register[r0] &= machine.register[r1]
	}

	update_flags(mut machine, machine.register[r0])
}

// Calculate bitwise NOT of registers or register and imm
fn vmop_not(mut machine &Machine) {
	mut instr := machine.instr
	r0 := (instr >> 9) & 0x7
	imm_flag := (instr >> 6) & 0x1
	
	if imm_flag != 0 {
		imm5 := sign_extend(instr & 0x1f, 5)
		machine.register[r0] = machine.register[r0] ~ imm5 
	}
	else {
		r1 := (instr >> 6) & 0x7
		machine.register[r0] = machine.register[r0] ~ machine.register[r1]
	}

	update_flags(mut machine, machine.register[r0])
}

// Branch program
fn vmop_br(mut machine &Machine) {
	pc_offset := sign_extend(machine.instr & 0x1ff, 9)
	cond_flag := (machine.instr >> 9) & 0x7
	if cond_flag & machine.register[r_cond] != 0 {
		machine.register[r_pc] += pc_offset
	}
}

// Jump to address
fn vmop_jmp(mut machine &Machine) {
	r1 := (machine.instr >> 6) & 7
	machine.register[r_pc] = machine.register[r1]
}

fn vmop_ret(mut machine &Machine) {
	vmop_jmp(mut machine)
}

// Load value from offset of program counter
fn vmop_ldi(mut machine &Machine) {
	mut instr := machine.instr 
	r0 := (instr >> 9) & 0x7
	pc_offset := sign_extend(instr & 0x1ff, 9)

	machine.register[r0] = yc_readmem(
		machine,
		yc_readmem(machine, 
			machine.register[r_pc] + pc_offset)
		)
	update_flags(mut machine, r0)
}

// Execute Machine
fn yc_run() {
	mut machine := yc_init()
	machine.running = true
	
	for machine.running {
		// Fetch next instruction
		machine.instr = yc_readmem(
			&machine,
			machine.register[r_pc])
		op := machine.instr >> 12

		if op == op_add {
			vmop_add(mut &machine)
		}
		

	}

}

fn main() {
	yc_run()
}
