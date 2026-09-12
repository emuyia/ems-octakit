        .include "abi.inc"
        .section .exception_report,"a",@progbits
        .align  2
        .global gk_exception_report_format
        .type   gk_exception_report_format,@object
gk_exception_report_format:
        .ascii  "D0:%08x\nSP:%08x\nMK%01x 1.40C R0178\nCFW:26912-163229"
        .byte   0
        .size   gk_exception_report_format,.-gk_exception_report_format
