ENTRY(_start)

SECTIONS {
    . = 1M;

    .multiboot ALIGN(4) : {
        KEEP(*(.multiboot))
    }

    .text ALIGN(4K) : {
        *(.text .text.*)
    }

    .rodata ALIGN(4K) : {
        *(.rodata .rodata.*)
    }

    .data ALIGN(4K) : {
        *(.data .data.*)
    }

    .bss ALIGN(4K) : {
        . = ALIGN(4K);
        *(COMMON)
        *(.bss .bss.*)
        . = ALIGN(4K);
    }

    /DISCARD/ : {
        *(.note.gnu.build-id)
        *(.comment)
        *(.eh_frame)
        *(.eh_frame_hdr)
    }
}