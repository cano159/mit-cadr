/*
 * ucode.c
 *
 * very brute-force CADR simulator
 * from AIM-528, "CADR"
 *
 * please remember this is not ment to be fast or pretty.
 * it's ment to be accurate, however.
 * 
 * Brad Parker <brad@heeltoe.com>
 * $Id$
 */

#include <stdio.h>
#include "ucode.h"

extern ucw_t prom_ucode[512];
ucw_t ucode[16*1024];

unsigned int a_memory[1024];
unsigned int m_memory[32];
unsigned int dispatch_memory[2048];

unsigned int pdl_memory[1024];
int pdl_ptr;
int pdl_index;

int lc;
int lc_mode_flag;

int spc_stack[32];
int spc_stack_ptr;

struct page_s {
	unsigned int w[256];
};

struct page_s *phy_pages[16*1024];

int l1_map[2048];
int l2_map[1024];

unsigned long cycles;
unsigned long trace_cycles;
unsigned long max_cycles;
unsigned long max_trace_cycles;

int u_pc;
int page_fault_flag;
int interrupt_pending_flag;
int interrupt_status_reg;

int sequence_break_flag;
int interrupt_enable_flag;
int lc_byte_mode_flag;
int bus_reset_flag;

int prom_enabled_flag;
int run_ucode_flag;
int stop_after_prom_flag;

unsigned int md;
unsigned int vma;
unsigned int q;
unsigned int opc;

unsigned int new_md;
int new_md_delay;

int write_fault_bit;
int access_fault_bit;

int alu_carry;
unsigned int alu_out;

unsigned int oa_reg_lo;
unsigned int oa_reg_hi;
int oa_reg_lo_set;
int oa_reg_hi_set;

int interrupt_control;
unsigned int dispatch_constant;

int trace;
int trace_mcr_labels_flag;
int trace_lod_labels_flag;
int trace_prom_flag;
int trace_mcr_flag;
int trace_io_flag;
int trace_vm_flag;
int trace_disk_flag;
int trace_int_flag;

int macro_pc_incrs;

int phys_ram_pages;

unsigned int alu_stat0[16], alu_stat1[16];

void show_label_closest(unsigned int upc);
void show_label_closest_padded(unsigned int upc);
char *find_function_name(int the_lc);

void
set_interrupt_status_reg(int new)
{
	interrupt_status_reg = new;
	interrupt_pending_flag = (interrupt_status_reg & 0140000) ? 1 : 0;
}

void
assert_unibus_interrupt(int vector)
{
	/* unibus interrupts enabeld? */
	if (interrupt_status_reg & 02000) {
		traceint("assert: unibus interrupt (enabled)\n");
		set_interrupt_status_reg(
			(interrupt_status_reg & ~01774) |
			0100000 | (vector & 01774));
	} else {
		traceint("assert: unibus interrupt (disabled)\n");
	}
}

void
deassert_unibus_interrupt(int vector)
{
	if (interrupt_status_reg & 0100000) {
		traceint("deassert: unibus interrupt\n");
		set_interrupt_status_reg(
			interrupt_status_reg & ~(01774 | 0100000));
	}
}

void
assert_xbus_interrupt(void)
{
	traceint("assert: xbus interrupt (%o)\n", interrupt_status_reg);
	set_interrupt_status_reg(interrupt_status_reg | 040000);
}

void
deassert_xbus_interrupt(void)
{
	if (interrupt_status_reg & 040000) {
		traceint("deassert: xbus interrupt\n");
		set_interrupt_status_reg(interrupt_status_reg & ~040000);
	}
}

unsigned int last_virt = 0xffffff00, last_l1, last_l2;

inline void
invalidate_vtop_cache(void)
{
	last_virt = 0xffffff00;
}

/*
 * map virtual address to physical address,
 * possibly returning l1 mapping
 * possibly returning offset into page
 */
inline unsigned int
map_vtop(unsigned int virt, int *pl1_map, int *poffset)
{
	int l1_index, l2_index, l1;
	unsigned int l2;

	/* 24 bit address */
	virt &= 077777777;

#if 0
	/* cache */
	if ((virt & 0xffffff00) == last_virt) {
		if (pl1_map)
			*pl1_map = last_l1;
		if (poffset)
			*poffset = virt & 0377;
		return last_l2;
	}
#endif

	/* frame buffer */
	if ((virt & 077700000) == 077000000) {
		/*  077000000, size = 210560(8) */

		if (virt >= 077051757 && virt <= 077051763) {
			traceio("disk run light\n");
		} else {
			if (0) traceio("tv: frame buffer %o\n", virt);
		}

		if (poffset)
			*poffset = virt & 0377;

		return (1 << 22) | (1 << 23) | 036000;
	}

	/* color */
	if ((virt & 077700000) == 077200000) {
		if (poffset)
			*poffset = virt & 0377;
		return (1 << 22) | (1 << 23) | 036000;
	}

/* this should be move below - I'm not sure it has to happen anymore */
	if ((virt & 077777400) == 077377400) {
		if (0) traceio("forcing xbus mapping for disk\n");
		if (poffset)
			*poffset = virt & 0377;
		return (1 << 22) | (1 << 23) | 036777;
	}

/*
764000-7641777 i/o board
764140 chaos (77772060)
*/

	/* 11 bit l1 index */
	l1_index = (virt >> 13) & 03777;
	l1 = l1_map[l1_index] & 037;

	if (pl1_map)
		*pl1_map = l1;

	/* 10 bit l2 index */
	l2_index = (l1 << 5) | ((virt >> 8) & 037);
	l2 = l2_map[l2_index];

	if (poffset)
		*poffset = virt & 0377;

	last_virt = virt & 0xffffff00;
	last_l1 = l1;
	last_l2 = l2;

#if 0
	if ((virt & 0077777000) == 0076776000) {
		printf("vtop: pdl? %011o l1 %d %011o l2 %d %011o\n",
		       virt, l1_index, l1, l2_index, l2);
	}
#endif

	return l2;
}

/*
 * add a new physical memory page,
 * generally in response to l2 mapping
 * (but can also be due to phys access to ram)
 */
int
add_new_page_no(int pn)
{
	struct page_s *page;

	if (0) printf("new_page %o\n", pn);

	if ((page = phy_pages[pn]) == 0) {

		page = (struct page_s *)malloc(sizeof(struct page_s));
		if (page) {
#define ZERO_NEW_PAGES
#ifdef ZERO_NEW_PAGES
			memset(page, 0, sizeof(struct page_s));
#endif
			phy_pages[pn] = page;

			tracef("add_new_page_no(pn=%o)\n", pn);
		}
	}
}

/*
 * read phys memory, with no virt-to-phys mapping
 * (used by disk controller)
 */
int
read_phy_mem(int paddr, unsigned int *pv)
{
	int pn = paddr >> 8;
	int offset = paddr & 0377;
	struct page_s *page;

	if ((page = phy_pages[pn]) == 0) {
		/* page does not exist */
		if (pn < phys_ram_pages) {
			tracef("[read_phy_mem] "
			       "adding phy ram page %o (address %o)\n",
			       pn, paddr);
			add_new_page_no(pn);
			page = phy_pages[pn];
		} else {
			printf("[read_phy_mem] address %o does not exist\n",
			       paddr);
			return -1;
		}
	}

	*pv = page->w[offset];

	return 0;
}

int
write_phy_mem(int paddr, unsigned int v)
{
	int pn = paddr >> 8;
	int offset = paddr & 0377;
	struct page_s *page;

	if ((page = phy_pages[pn]) == 0) {
		/* page does not exist - add it (probably result of disk write) */
		if (pn < phys_ram_pages) {
			tracef("[write_phy_mem] "
			       "adding phy ram page %o (address %o)\n",
			       pn, paddr);
			add_new_page_no(pn);
			page = phy_pages[pn];
		} else {
			printf("[write_phy_mem] address %o does not exist\n",
			       paddr);
			return -1;
		}
	}

	page->w[offset] = v;

	return 0;
}

/*
 * read virtual memory
 * returns -1 on fault
 * returns 0 if ok
 */
int
read_mem(int vaddr, unsigned int *pv)
{
	unsigned int map;
	int pn, offset;
	struct page_s *page;

	access_fault_bit = 0;
	write_fault_bit = 0;
	page_fault_flag = 0;


#if 1
	tracef("read_mem(vaddr=%o)\n", vaddr);
	map = map_vtop(vaddr, (int *)0, &offset);
#else
	{
		/* additional debugging, but slower */
		int l1;
		map = map_vtop(vaddr, (int *)&l1, &offset);
		tracef("read_mem(vaddr=%o) l1_index %o, l1 %o, l2_index %o, l2 %o\n",
		       vaddr,
		       (vaddr >> 13) & 03777,
		       (l1 << 5) | ((vaddr >> 8) & 037),
		       map);
	}
#endif

	/* 14 bit page # */
	pn = map & 037777;

	tracef("read_mem(vaddr=%o) -> pn %o, offset %o, map %o (%o)\n",
	       vaddr, pn, offset, map, 1 << 23);

	if ((map & (1 << 23)) == 0) {
		/* no access perm */
		access_fault_bit = 1;
		page_fault_flag = 1;
		opc = pn;
		*pv = 0;
		tracef("read_mem(vaddr=%o) access fault\n", vaddr);
		return -1;
	}

	/* simulate fixed number of ram pages (< 2mw?) */
	if (pn >= phys_ram_pages && pn <= 035777)
	{
		*pv = 0xffffffff;
		return 0;
	}

	if (pn == 036000) {
/* thwart the color probe */
if ((vaddr & 077700000) == 077200000) {
	if (0) printf("read from %o\n", vaddr);
	*pv = 0x0;
	return 0;
}
		offset = vaddr & 077777;
		video_read(offset, pv);
		return 0;
	}

	if (pn == 037764) {
		offset <<= 1;
		iob_unibus_read(offset, pv);
		return 0;
	}

	if (pn == 037766) {
		/* unibus */
		//int paddr = pn << 10;
		//tracef("paddr %o\n", paddr);

		switch (offset) {
		case 040:
			traceio("unibus: read interrupt status\n");
			*pv = 0;
			return 0;

		case 044:
			traceio("unibus: read error status\n");
			*pv = 0;
			return 0;
		}
	}

	/* disk & tv controller on xbus */
	if (pn == 036777) {
		int paddr = pn << 10;

		/*
		 * 77377774 disk
		 * 77377760 tv
		 */
		if (offset >= 0370)
			return disk_xbus_read(offset, pv);

		if (offset == 0360)
			return tv_xbus_read(offset, pv);
	}

	if ((page = phy_pages[pn]) == 0) {
		/* page fault */
		page_fault_flag = 1;
		opc = pn;
		tracef("read_mem(vaddr=%o) page fault\n", vaddr);
		return -1;
	}

	tracef("read_mem(vaddr=%o) -> %o\n", vaddr, page->w[offset]);

	*pv = page->w[offset];
	return 0;
}

/*
 * write virtual memory
 */
int
write_mem(int vaddr, unsigned int v)
{
	unsigned int map;
	int pn, offset;
	struct page_s *page;

	write_fault_bit = 0;
	access_fault_bit = 0;
	page_fault_flag = 0;

	map = map_vtop(vaddr, (int *)0, &offset);

	tracef("write_mem(vaddr=%o,v=%o)\n", vaddr, v);

	/* 14 bit page # */
	pn = map & 037777;

	tracef("write_mem(vaddr=%o) -> pn %o, offset %o, map %o (%o)\n",
	       vaddr, pn, offset, map, 1 << 22);

	if ((map & (1 << 23)) == 0) {
		/* no access perm */
		access_fault_bit = 1;
		page_fault_flag = 1;
		opc = pn;
		tracef("write_mem(vaddr=%o) access fault\n", vaddr);
		return -1;
	}

	if ((map & (1 << 22)) == 0) {
		/* no write perm */
		write_fault_bit = 1;
		page_fault_flag = 1;
		opc = pn;
		tracef("write_mem(vaddr=%o) write fault\n", vaddr);
		return -1;
	}

	if (pn == 036000) {
/* thwart the color probe */
if ((vaddr & 077700000) == 077200000) {
	if (0) printf("write to %o\n", vaddr);
	return 0;
}
		offset = vaddr & 077777;
		if (0) traceio("video_write %o %o (%011o)\n", offset, v, vaddr);
		video_write(offset, v);
		return 0;
	}

	if (pn == 037760) {
		printf("tv: reg write %o, offset %o, v %o\n",
		       vaddr, offset, v);
		return 0;
	}

	if (pn == 037764) {
		offset <<= 1;
		traceio("unibus: iob v %o, offset %o\n",
		       vaddr, offset);
		iob_unibus_write(offset, v);
		return 0;
	}

	if (pn == 037766) {
		/* unibus */
		int paddr = pn << 12;

		offset <<= 1;

		if (offset <= 036) {
			traceio("unibus: spy v %o, offset %o\n",
			       vaddr, offset);

			switch (offset) {
			case 012:
				if ((v & 044) == 044) {
					traceio("unibus: "
					       "disabling prom enable flag\n");
					prom_enabled_flag = 0;
				}
				if (v & 2) {
					traceio("unibus: normal speed\n");
				}

				break;
			}

			return 0;
		}

		switch (offset) {
		case 040:
			traceio("unibus: write interrupt status %o\n", v);
			set_interrupt_status_reg(
				(interrupt_status_reg & ~0036001) |
				(v & 0036001));
			return 0;

		case 042:
			traceio("unibus: write interrupt stim %o\n", v);
			set_interrupt_status_reg(
				(interrupt_status_reg & ~0101774) |
				(v & 0101774));
			return 0;

		case 044:
			traceio("unibus: clear bus error %o\n", v);
			return 0;

		default:
			if (offset >= 0140 && offset <= 0176) {
				traceio("unibus: mapping reg %o\n", offset);
				return 0;
			}

			traceio("unibus: write? v %o, offset %o\n",
			       vaddr, offset);
		}

	}

	/* disk controller on xbus */
	if (pn == 036777) {
		if (offset >= 0370)
			return disk_xbus_write(offset, v);

		if (offset == 0360)
			return tv_xbus_write(offset, v);
	}

#if 1
	/* catch questionable accesses */
	if (pn >= 036000) {
		printf("??: reg write vaddr %o, pn %o, offset %o, v %o; u_pc %o\n",
		       vaddr, pn, offset, v, u_pc);
	}
#endif

	if ((page = phy_pages[pn]) == 0) {
		/* page fault */
		page_fault_flag = 1;
		opc = pn;
		tracef("write_mem(vaddr=%o) page fault\n", vaddr);
		return -1;
	}

	page->w[offset] = v;
	return 0;
}

inline void
write_ucode(int addr, ucw_t w)
{
	tracef("u-code write; %Lo @ %o\n", w, addr);
	ucode[addr] = w;
}

void
note_location(char *s, unsigned int v)
{
	printf("%s; u_pc %o, v %o\n", s, u_pc, v);
	show_label_closest(u_pc);
	printf("\n");
}

inline void
write_a_mem(int loc, unsigned int v)
{
	tracef("a_memory[%o] <- %o\n", loc, v);
	a_memory[loc] = v;
}

inline unsigned int
read_a_mem(int loc)
{
	return a_memory[loc];
}

inline unsigned int
read_m_mem(int loc)
{
	if (loc > 32) {
		printf("read m-memory address > 32! (%o)\n", loc);
	}

	return m_memory[loc];
}

inline void
write_m_mem(int loc, unsigned int v)
{
	m_memory[loc] = v;
	a_memory[loc] = v;
	tracef("a,m_memory[%o] <- %o\n", loc, v);
}

#define USE_PDL_PTR 1
#define USE_PDL_INDEX 2

void
write_pdl_mem(int which, unsigned int v)
{
	switch (which) {
	case USE_PDL_PTR:
		if (pdl_ptr > 1024) {
			printf("pdl ptr %o!\n", pdl_ptr);
			return;
		}
		pdl_memory[pdl_ptr] = v;
		break;
	case USE_PDL_INDEX:
		if (pdl_index > 1024) {
			printf("pdl ptr %o!\n", pdl_index);
			return;
		}
		pdl_memory[pdl_index] = v;
		break;
	}
}

#if 0
unsigned int
rotate_left(unsigned int v, int rot)
{
	int i, c;

	/* silly, but simple */
	for (i = 0; i < rot; i++) {
		c = v & 0x80000000;
		v <<= 1;
		if (c) v |= 1;
	}

	return v;
}
#else
inline unsigned int
rotate_left(unsigned int value, int bitstorotate)
{
	unsigned int tmp;
	int mask;

	/* determine which bits will be impacted by the rotate */
	if (bitstorotate == 0)
		mask = 0;
	else
		mask = (int)0x80000000 >> bitstorotate;
		
	/* save off the affected bits */
	tmp = (value & mask) >> (32 - bitstorotate);
		
	/* perform the actual rotate */
	/* add the rotated bits back in (in the proper location) */
	return (value << bitstorotate) | tmp;
}
#endif

inline void
push_spc(int pc)
{
	spc_stack_ptr = (spc_stack_ptr + 1) & 037;

	tracef("writing spc[%o] <- %o\n", spc_stack_ptr, pc);
	spc_stack[spc_stack_ptr] = pc;
}

inline int
pop_spc(void)
{
	unsigned int v;

	tracef("reading spc[%o] -> %o\n",
	       spc_stack_ptr, spc_stack[spc_stack_ptr]);

	v = spc_stack[spc_stack_ptr];
	spc_stack_ptr = (spc_stack_ptr - 1) & 037;

	return v;
}

/*
 * advance the LC register,
 * following the rules; will read next vma if needed
 */
inline void
advance_lc(int *ppc)
{
	int old_lc = lc & 077777777;
	unsigned int v;

	tracef("advance_lc() byte-mode %d, lc %o, need-fetch %d\n",
	       lc_byte_mode_flag, lc,
	       ((lc >> 30) & 1) ? 1 : 0);

	if (lc_byte_mode_flag) {
		/* byte mode */
		lc++;
	} else {
		/* 16 bit mode */
		lc += 2;
	}

	macro_pc_incrs++;

	/* need-fetch? */
	if (lc & (1 << 31)) {
		lc &= ~(1 << 31);
		vma = old_lc >> 2;
#if 0
		if (read_mem(old_lc >> 2, &md)) {
		}
		tracef("advance_lc() read vma %011o -> %011o\n",
		       old_lc >> 2, md);
#else
		if (read_mem(old_lc >> 2, &new_md)) {
		}
		new_md_delay = 2;
		tracef("advance_lc() read vma %011o -> %011o\n",
		       old_lc >> 2, new_md);
#endif
	} else {
		/* force skipping 2 instruction (pf + set-md) */
		if (ppc)
			*ppc |= 2;

		tracef("advance_lc() no read; md = %011o\n", md);
	}

	{
		char lc0b, lc1, last_byte_in_word;

		/*
		 * this is ugly, but follows the hardware logic
		 * (I need to distill it to intent but it seems correct)
		 */
		lc0b =
			/* byte-mode */
			(lc_byte_mode_flag ? 1 : 0) &
			/* lc0 */
			((lc & 1) ? 1 : 0);

		lc1 = (lc & 2) ? 1 : 0;

//		last_byte_in_word = ((~lc0b & ~lc1) & 1) ? 1 : 0;
		last_byte_in_word = (~lc0b & ~lc1) & 1;

		tracef("lc0b %d, lc1 %d, last_byte_in_word %d\n",
		       lc0b, lc1, last_byte_in_word);

		if (last_byte_in_word)
			/* set need-fetch */
			lc |= (1 << 31);
	}

#if 0
	if ((lc & 077777777) == 057335774) trace = 1;
#endif
#if 0
	if ((lc & 07777777) == 02075277) trace = 1;
#endif
}

void
show_pdl_local(void)
{
	int i, min, max;

	printf("pdl-ptr %o, pdl-index %o\n", pdl_ptr, pdl_index);

	min = pdl_ptr > 4 ? pdl_ptr - 4 : 0;
	max = pdl_ptr < 1024-4 ? pdl_ptr + 4 : 1024;

	if (pdl_index > 0 && pdl_index < pdl_ptr) min = pdl_index;

	/* PDL */
	for (i = min; i < max; i += 4) {
		printf("PDL[%04o] %011o %011o %011o %011o\n",
		       i, pdl_memory[i], pdl_memory[i+1],
		       pdl_memory[i+2], pdl_memory[i+3]);
	}
}


/*
 * write value to decoded destination
 */
void
write_dest(ucw_t u, int dest, unsigned int out_bus)
{
	if (dest & 04000) {
		write_a_mem(dest & 03777, out_bus);
		return;
	}

	switch (dest >> 5) {
		/* case 0: none */
	case 1: /* LC (location counter) */
		tracef("writing LC <- %o\n", out_bus);
		lc = (lc & ~077777777) | (out_bus & 077777777);

		if (lc_byte_mode_flag) {
			/* not sure about byte mode... */
		} else {
			/* in half word mode low order bit is ignored */
			lc &= ~1;
		}

		/* set need fetch */
		lc |= (1 << 31);

/* isn't this pretty? :-) XXX add main option to trace on macro function name */
#if 0
{ char *s;

 s = find_function_name(lc);
//if (s && strcmp(s, "SHEET-PREPARE-FOR-EXPOSE") == 0) 
//	trace_lod_labels_flag = 1;

 if (trace_lod_labels_flag) {
	 show_label_closest(u_pc);
	 printf(": lc <- %o (%o)", lc, lc>>2);
	 if (s) printf(" '%s'", s);
	 printf("\n");
 }

// if (pdl_ptr > 01770) trace = 1;
// if (lc == 011030114652) trace=1;

 if (s) {
//if (strcmp(s, "RECEIVE-ANY-FUNCTION") == 0) 
//trace = 1;

//if (strcmp(s, "DISK-RUN") == 0) 
//trace = 1;
//	 trace_disk_flag = 1;

//if (strcmp(s, "FIND-DISK-PARTITION") == 0) 
//trace = 1;
//	 trace = 1;

//if (strcmp(s, "LISP-ERROR-HANDLER") == 0) 
//trace = 1;
//	 trace = 0;
 }
}
#endif

#if 0
show_label_closest(u_pc);
printf(": lc <- %o (%o)", lc, lc>>2);
 { char *s;
s = find_function_name(lc);
if (s) printf("%s", s);
// if (strcmp(s, "INITIALIZATIONS") == 0)
if (strcmp(s, "CLEAR-UNIBUS-MAP") == 0) trace = 1;
if (strcmp(s, "INITIALIZATIONS") == 0) {
dump_pdl_memory();
 show_list(0);
}
 }
printf("\n");

//trace_mcr_labels_flag = 1;
trace_disk_flag = 1;

 if (lc == 011007402704) {
	 trace = 1;
//	 trace_mcr_labels_flag = 1;
 }
#endif

		break;
	case 2: /* interrrupt control <29-26> */
		tracef("writing IC <- %o\n", out_bus);
		interrupt_control = out_bus;

		lc_byte_mode_flag = interrupt_control & (1 << 29);
		bus_reset_flag = interrupt_control & (1 << 28);
		interrupt_enable_flag = interrupt_control & (1 << 27);
		sequence_break_flag = interrupt_control & (1 << 26);

		if (sequence_break_flag) {
			traceint("ic: sequence break request\n");
		}
		if (interrupt_enable_flag) {
			traceint("ic: interrupt enable\n");
		}
		if (bus_reset_flag) {
			traceint("ic: bus reset\n");
		}
		if (lc_byte_mode_flag) {
			traceint("ic: lc byte mode\n");
		}

		/* preserve flags */
		lc = (lc & ~(017 << 26)) |
			(interrupt_control & (017 << 26));

		break;
	case 010: /* PDL (addressed by Pointer) */
		tracef("writing pdl[%o] <- %o\n",
		       pdl_ptr, out_bus);
		write_pdl_mem(USE_PDL_PTR, out_bus);
if (0) show_pdl_local();
		break;
	case 011: /* PDL (addressed by pointer, push */
		pdl_ptr = (pdl_ptr + 1) & 01777;
		tracef("writing pdl[%o] <- %o, push\n",
		       pdl_ptr, out_bus);
		write_pdl_mem(USE_PDL_PTR, out_bus);
if (0) show_pdl_local();
		break;
	case 012: /* PDL (addressed by index) */
		tracef("writing pdl[%o] <- %o\n",
		       pdl_index, out_bus);
		write_pdl_mem(USE_PDL_INDEX, out_bus);
if (0) show_pdl_local();
		break;
	case 013: /* PDL index */
		tracef("pdl-index <- %o\n", out_bus);
		pdl_index = out_bus & 01777;
		break;
	case 014: /* PDL pointer */
		tracef("pdl-ptr <- %o\n", out_bus);
		pdl_ptr = out_bus & 01777;
		break;

	case 015: /* SPC data, push */
		push_spc(out_bus);
		break;

	case 016: /* Next instruction modifier (lo) */
		oa_reg_lo = out_bus & 0377777777;
		oa_reg_lo_set = 1;
		tracef("setting oa_reg lo %o\n", oa_reg_lo);
		break;
	case 017: /* Next instruction modifier (hi) */
		oa_reg_hi = out_bus;
		oa_reg_hi_set = 1;
		tracef("setting oa_reg hi %o\n", oa_reg_hi);
		break;

	case 020: /* VMA register (memory address) */
		vma = out_bus;
		break;

	case 021: /* VMA register, start main memory read */
		vma = out_bus;
#if 0
		if (read_mem(vma, &md)) {
		}
#else
		if (read_mem(vma, &new_md)) {
		}
		new_md_delay = 2;
#endif
		break;

	case 022: /* VMA register, start main memory write */
		vma = out_bus;
		if (write_mem(vma, md)) {
		}
		break;

	case 023: /* VMA register, write map */
		/* vma-write-map */
		vma = out_bus;

		tracevm("vma-write-map md=%o, vma=%o (addr %o)\n",
		       md, vma, md >> 13);

	write_map:
		if ((vma >> 26) & 1) {
			int l1_index, l1_data;
			l1_index = (md >> 13) & 03777;
			l1_data = (vma >> 27) & 037;
			l1_map[l1_index] = l1_data;
			invalidate_vtop_cache();

			tracevm("l1_map[%o] <- %o\n", l1_index, l1_data);
		}

		if ((vma >> 25) & 1) {
			int l1_index, l2_index, l1_data;
			unsigned int l2_data;
			l1_index = (md >> 13) & 03777;
			l1_data = l1_map[l1_index];

			l2_index = (l1_data << 5) | ((md >> 8) & 037);
			l2_data = vma;
			l2_map[l2_index] = l2_data;
			invalidate_vtop_cache();

#if 0
			if (l2_index == 0) 
				printf("l2_map[%o] <- %o\n",
				       l2_index, l2_data);
#endif
			tracevm("l2_map[%o] <- %o\n", l2_index, l2_data);

			add_new_page_no(l2_data & 037777);
		}
		break;

	case 030: /* MD register (memory data) */
		md = out_bus;
		tracef("md<-%o\n", md);
		break;

	case 031:
		md = out_bus;
#if 0
		if (read_mem(vma, &md)) {
		}
#else
		if (read_mem(vma, &new_md)) {
		}
		new_md_delay = 2;
#endif
		break;

	case 032:
		md = out_bus;
		if (write_mem(vma, md)) {
		}
		break;

	case 033: /* MD register,write map like 23 */
		/* memory-data-write-map */
		md = out_bus;
		tracef("memory-data-write-map md=%o, vma=%o (addr %o)\n",
		       md, vma, md >> 13);
		goto write_map;
		break;
	}

	write_m_mem(dest & 037, out_bus);
}

#define MAX_PC_HISTORY 256/*16*/
struct {
	unsigned int rpc;
	unsigned int rvma;
	unsigned int rmd;
	int rpf;
	int rpdl_ptr;
	unsigned int rpdl;
} pc_history[MAX_PC_HISTORY];
int pc_history_ptr, pc_history_max, pc_history_stores;

void
record_pc_history(unsigned int pc, unsigned int vma, unsigned int md)
{
	int index;

	pc_history_stores++;

	if (pc_history_max < MAX_PC_HISTORY) {
		index = pc_history_max;
		pc_history_max++;
	} else {
		index = pc_history_ptr;
		pc_history_ptr++;
		if (pc_history_ptr == MAX_PC_HISTORY)
			pc_history_ptr = 0;
	}

	pc_history[index].rpc = pc;
	pc_history[index].rvma = vma;
	pc_history[index].rmd = md;
	pc_history[index].rpf = page_fault_flag;
	pc_history[index].rpdl_ptr = pdl_ptr;
	pc_history[index].rpdl = pdl_memory[pdl_ptr];
}

void
show_pc_history(void)
{
	int i;
	unsigned int pc;

	printf("pc history:\n");
	if (0) printf("pc_history_ptr %d, pc_history_max %d, pc_history_stores %d\n",
		      pc_history_ptr, pc_history_max, pc_history_stores);

	for (i = 0; i < MAX_PC_HISTORY; i++) {
		pc = pc_history[pc_history_ptr].rpc;
		if (pc == 0)
			break;
		printf("%2d %011o ", i, pc);
		show_label_closest_padded(pc);

		printf("\tvma %011o md %011o pf%d pdl %o %011o",
		       pc_history[pc_history_ptr].rvma,
		       pc_history[pc_history_ptr].rmd,
		       pc_history[pc_history_ptr].rpf,
		       pc_history[pc_history_ptr].rpdl_ptr,
		       pc_history[pc_history_ptr].rpdl);
		       
		printf("\n");

		pc_history_ptr++;
		if (pc_history_ptr == MAX_PC_HISTORY)
			pc_history_ptr = 0;
		
	}

	printf("\n");
}

void
dump_l1_map()
{
	int i;

#if 0
	for (i = 0; i < 32; i += 4) {
		printf("l1[%02o] %011o %011o %011o %011o\n",
		       i, l1_map[i], l1_map[i+1], l1_map[i+2], l1_map[i+3]);
	}
	printf("...\n");
	for (i = 2048-32; i < 2048; i += 4) {
		printf("l1[%02o] %011o %011o %011o %011o\n",
		       i, l1_map[i], l1_map[i+1], l1_map[i+2], l1_map[i+3]);
	}
	printf("\n");
#else
	for (i = 0; i < 2048; i += 4) {
		int skipped;
		printf("l1[%02o] %011o %011o %011o %011o\n",
		       i, l1_map[i], l1_map[i+1], l1_map[i+2], l1_map[i+3]);

		skipped = 0;
		while (l1_map[i+0] == l1_map[i+0+4] &&
		       l1_map[i+1] == l1_map[i+1+4] &&
		       l1_map[i+2] == l1_map[i+2+4] &&
		       l1_map[i+3] == l1_map[i+3+4] &&
			i < 2048)
		{
			if (skipped++ == 0)
				printf("...\n");
			i += 4;
		}
	}
	printf("\n");
#endif
}

void
dump_l2_map()
{
	int i;
#if 0
	for (i = 0; i < 32; i += 4) {
		printf("l2[%02o] %011o %011o %011o %011o\n",
		       i, l2_map[i], l2_map[i+1], l2_map[i+2], l2_map[i+3]);
	}
	printf("...\n");
	for (i = 1024-32; i < 1024; i += 4) {
		printf("l2[%02o] %011o %011o %011o %011o\n",
		       i, l2_map[i], l2_map[i+1], l2_map[i+2], l2_map[i+3]);
	}
	printf("\n");
#else
	for (i = 0; i < 1024; i += 4) {
		int skipped;
		printf("l2[%02o] %011o %011o %011o %011o\n",
		       i, l2_map[i], l2_map[i+1], l2_map[i+2], l2_map[i+3]);

		skipped = 0;
		while (l2_map[i+0] == l2_map[i+0+4] &&
		       l2_map[i+1] == l2_map[i+1+4] &&
		       l2_map[i+2] == l2_map[i+2+4] &&
		       l2_map[i+3] == l2_map[i+3+4] &&
			i < 1024)
		{
			if (skipped++ == 0)
				printf("...\n");
			i += 4;
		}
	}
	printf("\n");
#endif
}

void
dump_pdl_memory(void)
{
	int i;

	printf("pdl-ptr %o, pdl-index %o\n", pdl_ptr, pdl_index);

	/* PDL */
	for (i = 0; i < 1024; i += 4) {
		int skipped;
		printf("PDL[%04o] %011o %011o %011o %011o\n",
		       i, pdl_memory[i], pdl_memory[i+1],
		       pdl_memory[i+2], pdl_memory[i+3]);

		skipped = 0;
		while (pdl_memory[i+0] == pdl_memory[i+0+4] &&
		       pdl_memory[i+1] == pdl_memory[i+1+4] &&
		       pdl_memory[i+2] == pdl_memory[i+2+4] &&
		       pdl_memory[i+3] == pdl_memory[i+3+4] &&
			i < 1024)
		{
			if (skipped++ == 0)
				printf("...\n");
			i += 4;
		}
	}
	printf("\n");
}

void
dump_state(void)
{
	int i;

	printf("\n-------------------------------------------------\n");
	printf("CADR machine state:\n\n");

	printf("u-code pc %o, lc %o (%o)\n", u_pc, lc, lc>>2);
	printf("vma %o, md %o, q %o, opc %o, disp-const %o\n",
	       vma, md, q, opc, dispatch_constant);
	printf("oa-lo %011o, oa-hi %011o, ", oa_reg_lo, oa_reg_hi);
	printf("pdl-ptr %o, pdl-index %o, spc-ptr %o\n", pdl_ptr, pdl_index, spc_stack_ptr);
	printf("\n");
	printf("lc increments %d (macro instructions executed)\n",
	       macro_pc_incrs);
	printf("\n");

#if 1
	show_pc_history();
#endif

	for (i = 0; i < 32; i += 4) {
		printf(" spc[%02o] %c%011o %c%011o %c%011o %c%011o\n",
		       i,
		       (i+0 == spc_stack_ptr) ? '*' : ' ',
		       spc_stack[i+0],
		       (i+1 == spc_stack_ptr) ? '*' : ' ',
		       spc_stack[i+1],
		       (i+2 == spc_stack_ptr) ? '*' : ' ',
		       spc_stack[i+2],
		       (i+3 == spc_stack_ptr) ? '*' : ' ',
		       spc_stack[i+3]);
	}
	printf("\n");

	if (spc_stack_ptr > 0) {
		printf("stack backtrace:\n");
		for (i = spc_stack_ptr; i >= 0; i--) {
			char *sym;
			int offset, pc;
			pc = spc_stack[i] & 037777;
			sym = sym_find_last(!prom_enabled_flag, pc, &offset);
			printf("%2o %011o %s+%d\n",
			       i, spc_stack[i], sym, offset);

		}
		printf("\n");
	}

	for (i = 0; i < 32; i += 4) {
		printf("m[%02o] %011o %011o %011o %011o\n",
		       i, m_memory[i], m_memory[i+1], m_memory[i+2], m_memory[i+3]);
	}
	printf("\n");

	if (0) {
		dump_l1_map();
		dump_l2_map();
	}

	dump_pdl_memory();

	/* A-memory */
	for (i = 0; i < /*1024*/01000; i += 4) {
		printf("A[%04o] %011o %011o %011o %011o\n",
		       i, a_memory[i], a_memory[i+1],
		       a_memory[i+2], a_memory[i+3]);
	}
	printf("\n");

#if 0
	for (i = 0; i < 16*1024; i++) {
		if (phy_pages[i] == 0) printf("z %o\n", i);
	}
#endif

	{
		int s, e;
		s = -1;
		for (i = 0; i < 16*1024; i++) {
			if (phy_pages[i] != 0 && s == -1)
				s = i;

			if ((phy_pages[i] == 0 || i == 16*1024-1) && s != -1) {
				e = i-1;
				printf("%o-%o\n", s, e);
				s = -1;
			}
		}
	}


	printf("\n");
	printf("A-memory by symbol:\n");
	{
		int i;
		for (i = 0; i < 1024; i++) {
			char *sym;

			sym = sym_find_by_type_val(1, 4/*A-MEM*/, i);
			if (sym) {
				printf("%o %-40s %o\n",
				       i, sym, a_memory[i]);
			}
		}
	}

	printf("\n");

#if 1
	printf("ALU op-code usage:\n");
	for (i = 0; i < 16; i++) {
		printf("%2i %2o %08u %08u\n",
		       i, i, alu_stat0[i], alu_stat1[i]);
	}
#endif

	printf("trace: %s\n", trace ? "on" : "off");
}

void
patch_prom_code(void)
{
//#define PATCH_PROM_LOOPS_1
//#define PATCH_PROM_LOOPS_2

#ifdef PATCH_PROM_LOOPS_1
	/* short out some really long loops */
	prom_ucode[0244] = 0;
	prom_ucode[0251] = 0;
	prom_ucode[0256] = 0;
#endif

#if 0
	/* test unibus prom enable flag */
	prom_ucode[0504] = 0;
	prom_ucode[0510] = 0;
#endif

#ifdef PATCH_PROM_LOOPS_2
	prom_ucode[0452] = 04000001000310030; /* m-c <- m-zero */
#endif
}

char *breakpoint_name_prom;
char *breakpoint_name_mcr;
int breakpoint_count;
char *tracelabel_name_mcr;

int
breakpoint_set_prom(char *arg)
{
	breakpoint_name_prom = arg;
	return 0;
}

int
breakpoint_set_mcr(char *arg)
{
	breakpoint_name_mcr = arg;
	return 0;
}

int
breakpoint_set_count(int count)
{
	printf("breakpoint: max count %d\n", count);
	breakpoint_count = count;
	return 0; 
}

int
tracelabel_set_mcr(char *arg)
{
	tracelabel_name_mcr = arg;
	return 0;
}

int
set_breakpoints(int *ptrace_pt, int *ptrace_pt_count, int *ptrace_label_pt)
{
	max_cycles = 0;

#if 0
	trace_disk_flag = 1;
	trace_io_flag = 1;
	trace_int_flag = 1;
#endif

	if (breakpoint_name_prom) {
		if (sym_find(0, breakpoint_name_prom, ptrace_pt)) {
			if (isdigit(breakpoint_name_prom[0])) {
				sscanf(breakpoint_name_prom, "%o", ptrace_pt);
			} else {
				fprintf(stderr,
					"can't find prom breakpoint '%s'\n",
					breakpoint_name_prom);
				return -1;
			}
		}
		printf("breakpoint [prom]: %s %o\n",
		       breakpoint_name_prom, *ptrace_pt);

		*ptrace_pt_count = 1;
	}

	if (breakpoint_name_mcr) {
		if (sym_find(1, breakpoint_name_mcr, ptrace_pt)) {
			if (isdigit(breakpoint_name_mcr[0])) {
				sscanf(breakpoint_name_mcr, "%o", ptrace_pt);
			} else {
				fprintf(stderr,
					"can't find mcr breakpoint '%s'\n",
					breakpoint_name_mcr);
				return -1;
			}
		}
		printf("breakpoint [mcr]: %s %o\n",
		       breakpoint_name_mcr, *ptrace_pt);

		*ptrace_pt_count = 1;
	}

	if (breakpoint_count) {
		*ptrace_pt_count = breakpoint_count;
	}

	if (tracelabel_name_mcr) {
		if (sym_find(1, tracelabel_name_mcr, ptrace_label_pt)) {
			fprintf(stderr, "can't find mcr trace label '%s'\n",
				tracelabel_name_mcr);
			return -1;
		}
		printf("trace label point [mcr]: %s %o\n",
		       tracelabel_name_mcr, *ptrace_label_pt);
	}

	return 0;
}

void
show_label_closest(unsigned int upc)
{
	int offset;
	char *sym;

	if (sym = sym_find_last(!prom_enabled_flag, upc, &offset)) {
		if (offset == 0)
			printf("%s", sym);
		else
			printf("%s+%o", sym, offset);
	}
}

void
show_label_closest_padded(unsigned int upc)
{
	int offset;
	char *sym;

	if (sym = sym_find_last(!prom_enabled_flag, upc, &offset)) {
		if (offset == 0)
			printf("%-16s  ", sym);
		else
			printf("%-16s+%o", sym, offset);
	}
}

/*
 * 'The time has come,' the Walrus said,
 *   'To talk of many things:
 * Of shoes -- and ships -- and sealing wax --
 *   Of cabbages -- and kings --
 * And why the sea is boiling hot --
 *   And whether pigs have wings.'
 *       -- Lewis Carroll, The Walrus and Carpenter
 *
 * (and then, they ate all the clams :-)
 *
 */

int
run(void)
{
	int trace_pt, trace_pt_count, trace_label_pt;
	char *sym, *last_sym = 0;

	/* 2Mwords */
	phys_ram_pages = 8192;

	u_pc = 0;
	prom_enabled_flag = 1;
	run_ucode_flag = 1;

	trace_pt = 0;
	trace_pt_count = 0;
	trace_label_pt = 0;

	set_breakpoints(&trace_pt, &trace_pt_count, &trace_label_pt);

	printf("run:\n");

	patch_prom_code();

	write_phy_mem(0, 0);

	timing_start();

	while (run_ucode_flag) {
		char op_code, no_exec_next;
		char invert_sense, take_jump;
		int a_src, m_src, new_pc, dest, alu_op;
		int r_bit, p_bit, n_bit, ir8, ir7;
		int m_src_value, a_src_value;

		int widthm1, pos;
		int mr_sr_bits;
		unsigned int left_mask, right_mask, mask;
		int left_mask_index, right_mask_index;

		int disp_const, disp_addr;
		int map, len, rot;
		int out_bus;
		int carry_in, do_add, do_sub;

		long long lv;

		ucw_t u, w;
		ucw_t p1;
		int p0_pc, p1_pc;
#define p0 u

		char n_plus1, enable_ish;
		char i_long, popj;

		if (cycles == 0) {
			p0 = p1 = 0;
			p0_pc = p1_pc = 0;
			no_exec_next = 0;
		}

	next:
		iob_poll(cycles);

		disk_poll();

		if ((cycles & 0xffff) == 0) {
			display_poll();
		}

#define FETCH()	(prom_enabled_flag ? prom_ucode[u_pc] : ucode[u_pc])

		/* pipeline */
		p0 = p1;
		p0_pc = p1_pc;

		/* fetch next instruction from prom or ram */
		p1 = FETCH();
		p1_pc = u_pc;
		u_pc++;

		if (new_md_delay) {
			new_md_delay--;
			if (new_md_delay == 0)
				md = new_md;
		}

		/* effectively stall pipe for one cycle */
		if (no_exec_next) {
			tracef("no_exec_next; u_pc %o\n", u_pc);
			no_exec_next = 0;

			p0 = p1;
			p0_pc = p1_pc;

			p1 = FETCH();
			p1_pc = u_pc;
			u_pc++;
		}

		/* next-instruction modify */
		if (oa_reg_lo_set) {
			tracef("merging oa lo %o\n", oa_reg_lo);
			oa_reg_lo_set = 0;
			u |= oa_reg_lo;
		}

		if (oa_reg_hi_set) {
			tracef("merging oa hi %o\n", oa_reg_hi);
			oa_reg_hi_set = 0;
			u |= (ucw_t)oa_reg_hi << 26;
		}

		/* ----------- trace ------------- */

#if 1
		record_pc_history(p0_pc, vma, md);
#endif

#if 0
 if (p0_pc == 02220 && pdl_ptr > 01700) {
	 trace = 1;
	 trace_lod_labels_flag = 1;
 }
#endif

		/* see if we hit a label trace point */
		if (trace_label_pt && p0_pc == trace_label_pt) {
			trace_mcr_labels_flag = 1;
		}

		/* see if we hit a trace point */
		if (trace_pt && p0_pc == trace_pt && trace == 0) {

			if (prom_enabled_flag == 0) {
				
				if (trace_pt_count) {
					if (--trace_pt_count == 0)
						trace = 1;
				} else {
					trace = 1;
				}
			}

			if (trace)
				printf("trace on\n");
		}

		if (stop_after_prom_flag) {
			if (prom_enabled_flag == 0) run_ucode_flag = 0;
		}

		if (trace_prom_flag) {
			if (prom_enabled_flag == 1) trace = 1;
		}

		if (trace_mcr_flag) {
			if (prom_enabled_flag == 0) trace = 1;
		}

		/* ----------- end trace ------------- */

		/* enforce max trace count */
		if (trace) {
			if (max_trace_cycles && trace_cycles++ > max_trace_cycles) {
				printf("trace cycle count exceeded, pc %o\n", u_pc);
				break;
			}
		}

		/* enforce max cycles */
		cycles++;
		if (max_cycles && cycles > max_cycles) {
			int offset;
			printf("cycle count exceeded, pc %o\n", u_pc);

			if (sym = sym_find_last(!prom_enabled_flag, u_pc, &offset)) {
				if (offset == 0)
					printf("%s:\n", sym);
				else
					printf("%s+%o:\n", sym, offset);
			}

			break;
		}

		i_long = (u >> 45) & 1;
		popj = (u >> 42) & 1;

		if (trace) {
			int offset;

			printf("------\n");

#if 1
			if (sym = sym_find_by_val(!prom_enabled_flag, p0_pc)) {
				printf("%s:\n", sym);
			}
#else
			printf("\n");
			show_label_closest(p0_pc);
			printf(":\n");
#endif

			printf("%03o %016Lo%s",
			       p0_pc, u, i_long ? " (i-long)" : "");

			if (lc != 0) {
				printf(" (lc=%011o %011o)", lc, lc>>2);
			}

			printf("\n");
			disassemble_ucode_loc(p0_pc, u);
		}

		/* trace label names in mcr */
		if (trace_mcr_labels_flag && !trace) {
			if (!prom_enabled_flag) {
				int offset;
				if (sym = sym_find_last(1, p0_pc, &offset)) {
					if (offset == 0 && sym != last_sym) {
						printf("%s: (lc=%011o %011o)\n",
						       sym, lc, lc>>2);
						last_sym = sym;
					}
				}
			}
		}

		a_src = (u >> 32) & 01777;
		m_src = (u >> 26) & 077;

		/* get A source value */
		a_src_value = read_a_mem(a_src);

		/* calculate M source value */
		if (m_src & 040) {
			unsigned int l2_data, l1_data;

			switch (m_src & 037) {
			case 0: /* dispatch constant */
				m_src_value = dispatch_constant;
				break;
			case 1: /* SPC pointer <28-24>, SPC data <18-0> */
				m_src_value = (spc_stack_ptr << 24) |
					(spc_stack[spc_stack_ptr] & 01777777);
				break;
			case 2: /* PDL pointer <9-0> */
				m_src_value = pdl_ptr & 01777;
				break;
			case 3: /* PDL index <9-0> */
				m_src_value = pdl_index & 01777;
				break;
			case 5: /* PDL buffer (addressed by index) */
				tracef("reading pdl[%o] -> %o\n",
				       pdl_index, pdl_memory[pdl_index]);
				if (0) show_pdl_local();

				m_src_value = pdl_memory[pdl_index];
				break;
			case 6: /* OPC registers <13-0> */
				m_src_value = opc;
				break;
			case 7: /* Q register */
				m_src_value = q;
				break;
			case 010: /* VMA register (memory address) */
				m_src_value = vma;
				break;
			case 011: /* MAP[MD] */
				/* memory-map-data, or "map[MD]" */
				l2_data = map_vtop(md, &l1_data, (int *)0);
				
				m_src_value = 
					(write_fault_bit << 31) |
					(access_fault_bit << 30) |
					((l1_data & 037) << 24) |
					(l2_data & 077777777);

				if (trace) {
					printf("l1_data %o, l2_data %o\n",
					       l1_data, l2_data);

					printf("read map[md=%o] -> %o\n",
					       md, m_src_value);
				}
				break;
			case 012:
				m_src_value = md;
				break;
			case 013:
				if (lc_byte_mode_flag)
					m_src_value = lc;
				else
					m_src_value = lc & ~1;
				break;
			case 014:
				m_src_value = (spc_stack_ptr << 24) |
					(spc_stack[spc_stack_ptr] & 01777777);

				tracef("reading spc[%o] + ptr -> %o\n",
				       spc_stack_ptr, m_src_value);

				spc_stack_ptr = (spc_stack_ptr - 1) & 037;
				break;

			case 024:
				tracef("reading pdl[%o] -> %o, pop\n",
				       pdl_ptr, pdl_memory[pdl_ptr]);
				if (0) show_pdl_local();

				m_src_value = pdl_memory[pdl_ptr];
				pdl_ptr = (pdl_ptr - 1) & 01777;
				break;
			case 025:
				tracef("reading pdl[%o] -> %o\n",
				       pdl_ptr, pdl_memory[pdl_ptr]);
				if (0) show_pdl_local();

				m_src_value = pdl_memory[pdl_ptr];
				break;
			}
		} else {
			m_src_value = read_m_mem(m_src);
		}

		/*
		 * decode instruction
		 */

		switch (op_code = (u >> 43) & 03) {
		case 0: /* alu */

#if 1
			/* nop short cut */
			if ((u & 03777777777767777) == 0) {
				goto next;
			}
#endif

			dest = (u >> 14) & 07777;
			out_bus = (u >> 12) & 3;
			ir8 = (u >> 8) & 1;
			ir7 = (u >> 7) & 1;
			carry_in = (u >> 2) & 1;

			alu_op = (u >> 3) & 017;

			if (trace) {
				printf("a=%o (%o), m=%o (%o)\n",
				       a_src, a_src_value,
				       m_src, m_src_value);

				printf("alu_op %o, ir8 %o, ir7 %o, c %o, "
				       "dest %o, out_bus %d\n",
				       alu_op, ir8, ir7, carry_in,
				       dest, out_bus);
			}

			/* (spec) ir7 is backward in memo? */
		        if (ir8 == 0 && ir7 == 0) {
#if 1
				alu_stat0[alu_op]++;
#endif
				/* logic */
				alu_carry = 0;
				switch (alu_op) {
				case 0: /* [SETZ] */
					alu_out = 0;
					break;
				case 1: /* [AND] */
					alu_out = m_src_value & a_src_value;
					break;
				case 2: /* [ANDCA] */
					alu_out = m_src_value & ~a_src_value;
					break;
				case 3: /* [SETM] */
					alu_out = m_src_value;
					break;
				case 4: /* [ANDCM] */
					alu_out = ~m_src_value & a_src_value;
					break;
				case 5: /* [SETA] */
					alu_out = a_src_value;
					break;
				case 6: /* [XOR] */
					alu_out = m_src_value ^ a_src_value;
					break;
				case 7: /* [IOR] */
					alu_out = m_src_value | a_src_value;
					break;
				case 010: /* [ANDCB] */
//					alu_out = ~a_src_value & ~m_src_value;
					alu_out = ~(a_src_value | m_src_value);
					break;
				case 011: /* [EQV] */
					alu_out = a_src_value == m_src_value;
					break;
				case 012: /* [SETCA] */
					alu_out = ~a_src_value;
					break;
				case 013: /* [ORCA] */
					alu_out = m_src_value | ~a_src_value;
					break;
				case 014: /* [SETCM] */
					alu_out = ~m_src_value;
					break;
				case 015: /* [ORCM] */
					alu_out = ~m_src_value | a_src_value;
					break;
				case 016: /* [ORCB] */
					alu_out = ~m_src_value | ~a_src_value;
					break;
				case 017: /* [ONES] */
					alu_out = ~0;
					break;
				}
			}

			if (ir8 == 0 && ir7 == 1) {
#if 1
				alu_stat1[alu_op]++;
#endif
				/* arithmetic */
				switch (alu_op) {
				case 0: /* -1 */
					alu_out = carry_in ? 0 : -1;
					alu_carry = 0;
					break;
				case 1: /* (M&A)-1 */
					lv = (m_src_value & a_src_value) -
						(carry_in ? 0 : 1);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 2: /* (M&~A)-1 */
					lv = (m_src_value & ~a_src_value) -
						(carry_in ? 0 : 1);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 3: /* M-1 */
					lv = m_src_value - (carry_in ? 0 : 1);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 4: /* M|~A */
					lv = (m_src_value | ~a_src_value) +
						(carry_in ? 1 : 0);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 5: /* (M|~A)+(M&A) */
					lv = (m_src_value | ~a_src_value) +
						(m_src_value & a_src_value) +
						(carry_in ? 1 : 0);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 6: /* M-A-1 [SUB] */
					lv = m_src_value - a_src_value -
						(carry_in ? 0 : 1);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 7: /* (M|~A)+M */
					lv = (m_src_value | ~a_src_value) +
						m_src_value +
						(carry_in ? 1 : 0);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 010: /* M|A */
					lv = m_src_value | a_src_value +
						(carry_in ? 1 : 0);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 011: /* M+A [ADD] */
					lv = a_src_value + m_src_value +
						(carry_in ? 1 : 0);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 012: /* (M|A)+(M&~A) */
					lv = (m_src_value | a_src_value) +
						(m_src_value & ~a_src_value) +
						(carry_in ? 1 : 0);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 013: /* (M|A)+M */
					lv = (m_src_value | a_src_value) +
						m_src_value +
						(carry_in ? 1 : 0);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 014: /* M */
					lv = m_src_value + (carry_in ? 1 : 0);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 015: /* M+(M&A) */
					lv = m_src_value +
						(m_src_value & a_src_value) +
						(carry_in ? 1 : 0);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 016: /* M+(M|~A) */
					lv = m_src_value +
						(m_src_value | ~a_src_value) +
						(carry_in ? 1 : 0);
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 017: /* M+M */
//					lv = m_src_value + m_src_value +
//						(carry_in ? 1 : 0);
//					alu_out = lv;
//					alu_carry = (lv >> 32) ? 1 : 0;
					alu_out = (m_src_value << 1) | 
						(carry_in ? 1 : 0);
					alu_carry = (m_src_value & 0x80000000)
						? 1 : 0;
					break;
				}
			}

			if (ir8 == 1) {
				/* conditional alu op code */
				switch (alu_op) {
				case 0: /* multiply step */
					/* ADD if Q<0>=1, else SETM */
					do_add = q & 1;
					if (do_add) {
						lv = a_src_value +
							m_src_value +
							(carry_in ? 1 : 0);
						alu_out = lv;
						alu_carry = (lv >> 32) ? 1 : 0;
					} else {
						alu_out = m_src_value;
						alu_carry = 0;
					}
					break;
				case 1: /* divide step */
					tracef("divide step\n");
#define DIVIDE_HACK
#ifdef DIVIDE_HACK
					if (out_bus == 1) {
						goto alu_done;
					}
#endif
					do_sub = q & 1;
					tracef("do_sub %d\n", do_sub);

					if (do_sub) {
						lv =
							m_src_value -
							a_src_value -
							(carry_in ? 1 : 0);
					} else {
						lv =
							m_src_value +
							a_src_value +
							(carry_in ? 1 : 0);
					}
					alu_out = lv;
					alu_carry = (lv >> 32) ? 1 : 0;
					break;
				case 5: /* remainder correction */
					tracef("remainder correction\n");
					do_sub = q & 1;
					if (a_src_value & 0x80000000)
						do_add = !do_add;
tracef("do_sub %d\n", do_sub);
					if (do_sub) {
						/* setm */
#ifndef DIVIDE_HACK
						alu_out = m_src_value;
						alu_out = q;
#endif
						alu_carry = 0;
					} else {
						lv =
							alu_out +
							a_src_value +
							(carry_in ? 1 : 0);
						alu_out = lv;
						alu_carry = (lv >> 32) ? 1 : 0;
					}

#ifndef DIVIDE_HACK
					q >>= 1; 
					alu_out >>= 1;
#endif
					break;
				case 011:
					/* initial divide step */
					tracef("divide-first-step\n");
#if 0
q = 4;
q = 8;
a_src_value = 2;
a_memory[011] = 2;

q = 10/2;
a_src_value = 3;
a_memory[011] = 3;
#endif
tracef("divide: %o / %o \n", q, a_src_value);

					lv = m_src_value -
						a_src_value -
						(carry_in ? 1 : 0);

					alu_out = lv;
tracef("alu_out %08x %o %d\n", alu_out, alu_out, alu_out);
					alu_carry = (lv >> 32) ? 1 : 0;
					break;

				default:
					printf("UNKNOWN cond alu op code %o\n",
					       alu_op);
				}
			}

			take_jump = 0;

			/* Q control */
			switch (u & 3) {
			case 1:
				tracef("q<<\n");
				q <<= 1;
				/* inverse of alu sign */
				if ((alu_out & 0x80000000) == 0)
					q |= 1;
				break;
			case 2:
				tracef("q>>\n");
				q >>= 1;
				if (alu_out & 1)
					q |= 0x80000000;
				break;
			case 3:
				tracef("q<-alu\n");
				q = alu_out;
				break;
			}

			/* output bus control */
			switch (out_bus) {
			case 0:
				printf("out_bus == 0!\n");
				break;
			case 1: out_bus = alu_out;
				break;
			case 2: out_bus = (alu_out >> 1) | 
					(alu_out & 0x80000000);
				break;
			case 3: out_bus = (alu_out << 1) | 
					((q & 0x80000000) ? 1 : 0);
				break;
			}

			write_dest(u, dest, out_bus);

			tracef("alu_out 0x%08x, alu_carry %d, q 0x%08x\n",
			       alu_out, alu_carry, q);
		alu_done:
			break;

		case 1: /* jump */
			new_pc = (u >> 12) & 037777;

			tracef("a=%o (%o), m=%o (%o)\n",
			       a_src, a_src_value,
			       m_src, m_src_value);

			r_bit = (u >> 9) & 1;
			p_bit = (u >> 8) & 1;
			n_bit = (u >> 7) & 1;
			invert_sense = (u >> 6) & 1;
			take_jump = 0;

			/* halt-cons? */
			if (((u >> 10) & 3) == 1) {
				printf("halted\n");
				run_ucode_flag = 0;
				break;
			}

		process_jump:
			/* jump condition */
			if (u & (1<<5)) {
				switch (u & 017) {
				case 0:
					if (op_code != 2)
						printf("jump-condition == 0! u_pc=%o\n",
						       p0_pc);
					break;
				case 1:
					take_jump = m_src_value < a_src_value;
					break;
				case 2:
					take_jump = m_src_value <= a_src_value;
#if 0
					tracef("%o <= %o; take_jump %o\n",
					       m_src_value, a_src_value, take_jump);
#endif
					break;
				case 3:
					take_jump = m_src_value == a_src_value;
					break;
				case 4: 
					take_jump = page_fault_flag;
					break;
				case 5:
					tracef("jump i|pf\n");
					take_jump = page_fault_flag |
						(interrupt_enable_flag ?
						 interrupt_pending_flag :0);
					break;
				case 6:
					tracef("jump i|pf|sb\n");
					take_jump = page_fault_flag |
						(interrupt_enable_flag ?
						 interrupt_pending_flag:0) |
						sequence_break_flag;
					break;
				case 7:
					take_jump = 1;
					break;
				}
			} else {
				rot = u & 037;
				tracef("jump-if-bit; rot %o, before %o ",
				       rot, m_src_value);
				m_src_value = rotate_left(m_src_value, rot);
				tracef("after %o\n", m_src_value);
				take_jump = m_src_value & 1;
			}

			if (((u >> 10) & 3) == 3) {
				printf("jump w/misc-3!\n");
			}
 
			if (invert_sense)
				take_jump = !take_jump;

			if (p_bit && take_jump) {
				if (!n_bit)
					push_spc(u_pc);
				else
					push_spc(u_pc-1);
			}

			/* P & R & jump-inst -> write ucode */
			if (p_bit && r_bit && op_code == 1) {
				w = ((ucw_t)(a_src_value & 0177777) << 32) |
					(unsigned int)m_src_value;
				write_ucode(new_pc, w);
			}

			if (r_bit && take_jump) {
				new_pc = pop_spc();

				/* spc<14> */
				if ((new_pc >> 14) & 1) {
					advance_lc(&new_pc);
				}

				new_pc &= 037777;
			}

			if (take_jump) {

//				if (new_pc == u_pc && n_bit && !p_bit) {
//					printf("loop detected pc %o\n", u_pc);
//					run_ucode_flag = 0;
//				}

				if (n_bit)
					no_exec_next = 1;

				u_pc = new_pc;

#if 0
				/* I don't think this ever happens */
				if (popj && r_bit == 0 && p_bit == 0) {
					pop_spc();
				}
#endif

				/* inhibit possible popj */
				popj = 0;
			}

			break;

		case 2: /* dispatch */
			disp_const = (u >> 32) & 01777;

			n_plus1 = (u >> 25) & 1;
			enable_ish = (u >> 24) & 1;
			disp_addr = (u >> 12) & 03777;
			map = (u >> 8) & 3;
			len = (u >> 5) & 07;
			pos = u & 037;

			/* misc function 3 */
			if (((u >> 10) & 3) == 3) {
				if (lc_byte_mode_flag) {
					/* byte mode */
					char ir4, ir3, lc1, lc0;

					ir4 = (u >> 4) & 1;
					ir4 = (u >> 3) & 1;
					lc1 = (lc >> 1) & 1;
					lc0 = (lc >> 0) & 1;

					pos = u & 007;
					pos |= ((ir4 ^ (lc1 ^ lc0)) << 4) |
						((ir3 ^ lc0) << 3);

					tracef("byte-mode, pos %o\n", pos);
				} else {
					/* 16 bit mode */
					char ir4, lc1;

					ir4 = (u >> 4) & 1;
					lc1 = (lc >> 1) & 1;

					pos = u & 017;
//					pos |= (ir4 ^ lc1) << 4;
					/* (spec) result needs to be inverted*/
					pos |= ((ir4 ^ lc1) ? 0 : 1) << 4;
					tracef("16b-mode, pos %o\n", pos);
				}
			}

			/* misc function 2 */
			if (((u >> 10) & 3) == 2) {
				tracef("dispatch_memory[%o] <- %o\n",
				       disp_addr, a_src_value);
				dispatch_memory[disp_addr] = a_src_value;
				goto dispatch_done;
			}

			tracef("m-src %o, ", m_src_value);

			/* rotate m-source */
			m_src_value = rotate_left(m_src_value, pos);

			/* generate mask */
			left_mask_index = (len - 1) & 037;

			mask = ~0;
			mask >>= 31 - left_mask_index;

			/* len == 0 */
			if (len == 0)
				mask = 0;

			/* put ldb into dispatch-addr */
			disp_addr |= m_src_value & mask;

			tracef("rotated %o, mask %o, result %o\n",
			       m_src_value, mask, m_src_value & mask);

			/* tweek dispatch-addr with l2 map bits */
			if (map) {
				int l2_map, bit18, bit19;

				/* (spec) bit 0 is or'd, not replaced */
				/* disp_addr &= ~1; */

				l2_map = map_vtop(md, (int *)0, (int *)0);

				/* (spec) schematics show this as bit 19,18 */
				bit19 = ((l2_map >> 19) & 1) ? 1 : 0;
				bit18 = ((l2_map >> 18) & 1) ? 1 : 0;

				tracef("md %o, l2_map %o, b19 %o, b18 %o\n",
				       md, l2_map, bit19, bit18);

				switch (map) {
				case 1: disp_addr |= bit18; break;
				case 2: disp_addr |= bit19; break;
				case 3: disp_addr |= bit18 | bit19; break;
				}
			}

			disp_addr &= 03777;

			tracef("dispatch[%o] -> %o ",
			       disp_addr, dispatch_memory[disp_addr]);

			disp_addr = dispatch_memory[disp_addr];

			dispatch_constant = disp_const;

			/* 14 bits */
			new_pc = disp_addr & 037777;

			n_bit = (disp_addr >> 14) & 1;
			p_bit = (disp_addr >> 15) & 1;
			r_bit = (disp_addr >> 16) & 1;

			tracef("%s%s%s\n",
			       n_bit ? "N " : "",
			       p_bit ? "P " : "",
			       r_bit ? "R " : "");

			if (n_plus1 && n_bit) {
				u_pc--;
			}

			invert_sense = 0;
			take_jump = 1;
			u = 1<<5;

			/* enable instruction sequence hardware */
			if (enable_ish) {
				advance_lc((int *)0);
			}

			if (p_bit && r_bit) {
				if (n_bit)
					no_exec_next = 1;
				goto dispatch_done;
			}

			goto process_jump;

		dispatch_done:
			break;

		case 3: /* byte */
			dest = (u >> 14) & 07777;
			mr_sr_bits = (u >> 12) & 3;

			tracef("a=%o (%o), m=%o (%o), dest=%o\n",
			       a_src, a_src_value,
			       m_src, m_src_value, dest);

			widthm1 = (u >> 5) & 037;
			pos = u & 037;

#if 1
			/* misc function 3 */
			if (((u >> 10) & 3) == 3) {
				if (lc_byte_mode_flag) {
					/* byte mode */
					char ir4, ir3, lc1, lc0;

					ir4 = (u >> 4) & 1;
					ir4 = (u >> 3) & 1;
					lc1 = (lc >> 1) & 1;
					lc0 = (lc >> 0) & 1;

					pos = u & 007;
					pos |= ((ir4 ^ (lc1 ^ lc0)) << 4) |
						((ir3 ^ lc0) << 3);

					tracef("byte-mode, pos %o\n", pos);
				} else {
					/* 16 bit mode */
					char ir4, lc1;

					ir4 = (u >> 4) & 1;
					lc1 = (lc >> 1) & 1;

					pos = u & 017;
//					pos |= (ir4 ^ lc1) << 4;
					pos |= ((ir4 ^ lc1) ? 0 : 1) << 4;

					tracef("16b-mode, pos %o\n", pos);
				}
			}
#endif

			if (mr_sr_bits & 2)
				right_mask_index = pos;
			else
				right_mask_index = 0;

			left_mask_index = (right_mask_index + widthm1) & 037;

			left_mask = ~0;
			right_mask = ~0;

			left_mask >>= 31 - left_mask_index;
			right_mask <<= right_mask_index;

			mask = left_mask & right_mask;

			tracef("widthm1 %o, pos %o, mr_sr_bits %o\n",
			       widthm1, pos, mr_sr_bits);

			tracef("left_mask_index %o, right_mask_index %o\n",
				left_mask_index, right_mask_index);

			tracef("left_mask %o, right_mask %o, mask %o\n",
			       left_mask, right_mask, mask);

			out_bus = 0;

			switch (mr_sr_bits) {
			case 0:
				break;
			case 1: /* ldb */
				tracef("ldb; m %o\n", m_src_value);

				m_src_value = rotate_left(m_src_value, pos);

				out_bus = (m_src_value & mask) |
					(a_src_value & ~mask);

				tracef("ldb; m-rot %o, mask %o, result %o\n", 
				       m_src_value, mask, out_bus);
				break;
			case 2: /* selective desposit */
				out_bus = (m_src_value & mask) |
					(a_src_value & ~mask);
				tracef("sel-dep; a %o, m %o, mask %o -> %o\n", 
				       a_src_value, m_src_value, mask, out_bus);
				break;
			case 3: /* dpb */
				tracef("dpb; m %o, pos %o\n", 
				       m_src_value, pos);

				/* mask is already rotated */

				m_src_value = rotate_left(m_src_value, pos);

				out_bus = (m_src_value & mask) |
					(a_src_value & ~mask);

				tracef("dpb; mask %o, result %o\n", 
				       mask, out_bus);
				break;
			}

			write_dest(u, dest, out_bus);
			break;
		}

		if (popj) {
			tracef("popj; ");
			u_pc = pop_spc();

			/* spc<14> */
			if ((u_pc >> 14) & 1) {
				advance_lc(&u_pc);
			}

			u_pc &= 037777;
		}
	}

	{
		int offset;
		sym = sym_find_last(!prom_enabled_flag, u_pc, &offset);
		printf("%s+%o:\n", sym, offset);
	}

	timing_stop();

	dump_state();
}