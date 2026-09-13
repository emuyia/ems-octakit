        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_pattern_copy_capture
        .type   gk_stock_pattern_copy_capture,@function
gk_stock_pattern_copy_capture:
        move.l  4(%sp),-(%sp)
        bsr.w   gk_stock_pattern_copy_capture_trampoline
        addq.l  #4,%sp
        bra.w   gk_pattern_kit_capture_workspace
        .size   gk_stock_pattern_copy_capture,.-gk_stock_pattern_copy_capture
        .global gk_stock_pattern_copy_capture_trampoline
        .type   gk_stock_pattern_copy_capture_trampoline,@function
gk_stock_pattern_copy_capture_trampoline:
        .incbin "stock/0434.bin", 0, 4
        .incbin "stock/0434.bin", 4, 6
        .global gk_stock_pattern_copy_capture_trampoline_jump
gk_stock_pattern_copy_capture_trampoline_jump:
        jmp     GK_STOCK_PATTERN_COPY_CAPTURE_CONTINUE
        .size   gk_stock_pattern_copy_capture_trampoline,.-gk_stock_pattern_copy_capture_trampoline
        .global gk_pattern_kit_capture_workspace
        .type   gk_pattern_kit_capture_workspace,@function
gk_pattern_kit_capture_workspace:
        .incbin "stock/0435.bin", 0, 4
        .incbin "stock/0435.bin", 4, 4
        clr.b   __gk_pattern_kit_valid
        clr.b   __gk_pattern_kit_armed
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_pattern_kit_capture_busy
        tst.l   __gk_persistence_snapshot_gate
        bne.w   .Lgk_pattern_kit_capture_busy
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_pattern_kit_capture_busy
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_pattern_kit_capture_busy
        moveq   #0,%d2
        move.b  __gk_workspace_descriptor,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_pattern_kit_capture_corrupt
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        move.l  %d0,%d1
        andi.l  #0xef,%d1
        cmpi.l  #GK_DESC_WORKSPACE_STABLE,%d1
        bne.w   .Lgk_pattern_kit_capture_busy
        tst.l   GK_DESC_PAYLOAD(%a2)
        beq.w   .Lgk_pattern_kit_capture_corrupt
        lea     __gk_pattern_kit_payload,%a4
        movea.l %a4,%a0
        moveq   #GK_PATTERN_KIT_SPILL_ID,%d1
        move.l  %d2,%d0
        jsr     gk_descriptor_begin_copy
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_capture_restore
        move.l  %d2,%d0
        jsr     gk_descriptor_copy_payload
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_capture_restore
        move.w  %sr,%d5
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        move.l  %d0,%d1
        andi.l  #0xef,%d1
        cmpi.l  #0x0b,%d1
        bne.s   .Lgk_pattern_kit_capture_finish_corrupt
        cmpa.l  GK_DESC_CANDIDATE(%a2),%a4
        bne.s   .Lgk_pattern_kit_capture_finish_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_SPILL(%a2),%d1
        cmpi.l  #GK_PATTERN_KIT_SPILL_ID,%d1
        bne.s   .Lgk_pattern_kit_capture_finish_corrupt
        clr.l   GK_DESC_CANDIDATE(%a2)
        move.b  #GK_ID_NONE,GK_DESC_SPILL(%a2)
        andi.l  #0xfd,%d0
        move.b  %d0,GK_DESC_FLAGS(%a2)
        move.l  __gk_workspace_name,%d0
        move.l  %d0,__gk_pattern_kit_name
        move.l  __gk_workspace_name + 4,%d0
        move.l  %d0,__gk_pattern_kit_name + 4
        moveq   #1,%d0
        move.b  %d0,__gk_pattern_kit_valid
        move.w  %d5,%sr
        moveq   #GK_OK,%d0
        bra.s   .Lgk_pattern_kit_capture_restore
.Lgk_pattern_kit_capture_finish_corrupt:
        move.w  %d5,%sr
.Lgk_pattern_kit_capture_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_pattern_kit_capture_restore
.Lgk_pattern_kit_capture_busy:
        moveq   #GK_ERR_BUSY,%d0
.Lgk_pattern_kit_capture_restore:
        movem.l (%sp),%d2-%d5/%a2-%a4
        lea     28(%sp),%sp
        rts
        .size   gk_pattern_kit_capture_workspace,.-gk_pattern_kit_capture_workspace
        .global gk_pattern_kit_allocate
        .type   gk_pattern_kit_allocate,@function
gk_pattern_kit_allocate:
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        lsl.l   #4,%d0
        moveq   #0,%d1
        move.b  __gk_current_pattern,%d1
        add.l   %d1,%d0
        bra.w   gk_pattern_kit_allocate_for_pattern
        .size   gk_pattern_kit_allocate,.-gk_pattern_kit_allocate
        .global gk_pattern_kit_allocate_for_pattern
        .type   gk_pattern_kit_allocate_for_pattern,@function
gk_pattern_kit_allocate_for_pattern:
        lea     -24(%sp),%sp
        movem.l %d2-%d7,(%sp)
        move.l  %d0,%d7
        cmpi.l  #GK_PATTERN_ASSIGNMENT_COUNT - 1,%d7
        bhi.w   .Lgk_pattern_kit_allocate_range
        lea     __gk_ui_referenced_bitmap,%a0
        moveq   #0,%d0
        moveq   #8,%d1
.Lgk_pattern_kit_refs_clear:
        move.l  %d0,(%a0)+
        subq.l  #1,%d1
        bne.s   .Lgk_pattern_kit_refs_clear
        moveq   #0,%d2
.Lgk_pattern_kit_ref_pattern_loop:
        cmp.l   %d7,%d2
        beq.s   .Lgk_pattern_kit_ref_pattern_next
        move.l  %d2,%d0
        move.l  %d2,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_pattern_assignment_valid,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_pattern_kit_ref_pattern_next
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d3
        move.b  (%a0,%d2.l),%d3
        move.l  %d3,%d0
        move.l  %d3,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_ui_referenced_bitmap,%a0
        bset    %d1,(%a0,%d0.l)
.Lgk_pattern_kit_ref_pattern_next:
        addq.l  #1,%d2
        cmpi.l  #GK_PATTERN_ASSIGNMENT_COUNT,%d2
        blo.s   .Lgk_pattern_kit_ref_pattern_loop
        moveq   #0,%d4
        move.b  __gk_current_kit,%d4
        addq.l  #1,%d4
        andi.l  #0xff,%d4
        moveq   #0,%d6
.Lgk_pattern_kit_candidate_pass:
        move.l  %d4,%d5
        moveq   #0,%d7
        move.w  #GK_KIT_COUNT - 1,%d7
.Lgk_pattern_kit_candidate_loop:
        move.l  %d5,%d0
        move.l  %d5,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_ui_referenced_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        bne.s   .Lgk_pattern_kit_candidate_next
        tst.l   %d6
        bne.s   .Lgk_pattern_kit_candidate_found
        lea     __gk_initialized_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_pattern_kit_candidate_found
.Lgk_pattern_kit_candidate_next:
        addq.l  #1,%d5
        andi.l  #0xff,%d5
        subq.l  #1,%d7
        bpl.s   .Lgk_pattern_kit_candidate_loop
        addq.l  #1,%d6
        cmpi.l  #2,%d6
        blo.s   .Lgk_pattern_kit_candidate_pass
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_pattern_kit_allocate_restore
.Lgk_pattern_kit_candidate_found:
        move.l  %d5,%d0
        bra.s   .Lgk_pattern_kit_allocate_restore
.Lgk_pattern_kit_allocate_range:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_pattern_kit_allocate_restore:
        movem.l (%sp),%d2-%d7
        lea     24(%sp),%sp
        rts
        .size   gk_pattern_kit_allocate_for_pattern,.-gk_pattern_kit_allocate_for_pattern
        .type   gk_pattern_kit_rollback_capture,@function
gk_pattern_kit_rollback_capture:
        move.l  %d2,-(%sp)
        move.l  %a2,-(%sp)
        move.l  %d0,%d2
        move.b  %d2,__gk_pattern_kit_rollback_target
        move.l  %d2,%d0
        move.l  %d2,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_pattern_kit_rollback_empty
        moveq   #1,%d0
        move.b  %d0,__gk_pattern_kit_rollback_occupied
        move.l  %d2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a0
        adda.l  %d0,%a0
        lea     __gk_pattern_kit_rollback_payload,%a1
        jsr     gk_copy_payload_interruptible
        move.l  %d2,%d0
        lsl.l   #3,%d0
        lea     __gk_kit_names,%a2
        adda.l  %d0,%a2
        move.l  (%a2),%d0
        move.l  %d0,__gk_pattern_kit_rollback_name
        move.l  4(%a2),%d0
        move.l  %d0,__gk_pattern_kit_rollback_name + 4
        moveq   #GK_OK,%d0
        bra.s   .Lgk_pattern_kit_rollback_capture_restore
.Lgk_pattern_kit_rollback_empty:
        clr.b   __gk_pattern_kit_rollback_occupied
        clr.l   __gk_pattern_kit_rollback_name
        clr.l   __gk_pattern_kit_rollback_name + 4
        moveq   #GK_OK,%d0
.Lgk_pattern_kit_rollback_capture_restore:
        move.l  (%sp)+,%a2
        move.l  (%sp)+,%d2
        rts
        .size   gk_pattern_kit_rollback_capture,.-gk_pattern_kit_rollback_capture
        .type   gk_pattern_kit_record_apply,@function
gk_pattern_kit_record_apply:
        moveq   #1,%d1
        lea     __gk_pattern_kit_payload,%a0
        lea     __gk_pattern_kit_name,%a1
        jmp     gk_kit_record_apply
        .size   gk_pattern_kit_record_apply,.-gk_pattern_kit_record_apply
        .type   gk_pattern_kit_rollback_apply,@function
gk_pattern_kit_rollback_apply:
        moveq   #0,%d0
        move.b  __gk_pattern_kit_rollback_target,%d0
        moveq   #0,%d1
        move.b  __gk_pattern_kit_rollback_occupied,%d1
        tst.l   %d1
        beq.s   .Lgk_pattern_kit_rollback_apply_empty
        lea     __gk_pattern_kit_rollback_payload,%a0
        lea     __gk_pattern_kit_rollback_name,%a1
        jmp     gk_kit_record_apply
.Lgk_pattern_kit_rollback_apply_empty:
        lea     __gk_default_payload,%a0
        lea     __gk_pattern_kit_rollback_name,%a1
        jmp     gk_kit_record_apply
        .size   gk_pattern_kit_rollback_apply,.-gk_pattern_kit_rollback_apply
        .global gk_pattern_kit_paste_dispatch
        .type   gk_pattern_kit_paste_dispatch,@function
gk_pattern_kit_paste_dispatch:
        moveq   #1,%d0
        cmp.l   12(%sp),%d0
        bne.w   .Lgk_pattern_kit_paste_not_handled
        .incbin "stock/0436.bin", 0, 4
        .incbin "stock/0436.bin", 4, 4
        jsr     gk_function_map_active
        tst.l   %d0
        beq.w   .Lgk_pattern_kit_paste_not_handled_restore
        .incbin "stock/0437.bin", 0, 4
        .incbin "stock/0437.bin", 4, 6
        .incbin "stock/0437.bin", 10, 2
        .incbin "stock/0437.bin", 12, 2
        .incbin "stock/0437.bin", 14, 2
        .byte 0x01,0x92
        pea     GK_STOCK_PASTE_PRESS_INPUT
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        beq.w   .Lgk_pattern_kit_paste_not_handled_restore
        moveq   #0,%d0
        move.b  __gk_pattern_kit_valid,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        moveq   #0,%d0
        move.b  __gk_pattern_kit_armed,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        tst.b   __gk_ui_mode
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        tst.l   GK_STOCK_CALLBACK_MENU_OBJECT
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        tst.l   GK_STOCK_TEXT_EDITOR_OBJECT
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        moveq   #0,%d1
        move.b  __gk_pattern_kit_bank,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        moveq   #0,%d1
        move.b  __gk_pattern_kit_pattern,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        bsr.w   gk_pattern_kit_allocate
        tst.l   %d0
        bmi.w   .Lgk_pattern_kit_paste_finish
        move.l  %d0,%d4
        jsr     gk_persistence_snapshot_begin
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_paste_finish
        move.l  %d4,%d0
        bsr.w   gk_pattern_kit_rollback_capture
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_paste_snapshot_abort
        move.l  %d4,%d0
        bsr.w   gk_pattern_kit_record_apply
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_paste_snapshot_abort
        jsr     gk_persistence_snapshot_end
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_paste_finish
        moveq   #0,%d2
        move.b  __gk_current_bank,%d2
        moveq   #0,%d3
        move.b  __gk_current_pattern,%d3
        move.l  %d2,%d0
        move.l  %d3,%d1
        move.l  %d4,%d2
        jsr     gk_stock_load_kit_transaction
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_rollback
        moveq   #0,%d1
        move.b  __gk_current_bank,%d1
        moveq   #1,%d0
        lsl.l   %d1,%d0
        jsr     gk_stock_dirty_mark_bank_mask
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_finish
        clr.b   __gk_pattern_kit_armed
        moveq   #GK_OK,%d0
        bra.s   .Lgk_pattern_kit_paste_finish
.Lgk_pattern_kit_paste_rollback:
        move.l  %d0,%d5
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        moveq   #0,%d1
        move.b  __gk_pattern_kit_bank,%d1
        cmp.l   %d1,%d0
        bne.s   .Lgk_pattern_kit_paste_rollback_record
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        moveq   #0,%d1
        move.b  __gk_pattern_kit_pattern,%d1
        cmp.l   %d1,%d0
        bne.s   .Lgk_pattern_kit_paste_rollback_record
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.l   %d4,%d0
        beq.s   .Lgk_pattern_kit_paste_late_failure
.Lgk_pattern_kit_paste_rollback_record:
        jsr     gk_persistence_snapshot_begin
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_corrupt
        bsr.w   gk_pattern_kit_rollback_apply
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_snapshot_abort_corrupt
        jsr     gk_persistence_snapshot_end
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_corrupt
        move.l  %d5,%d0
        bra.s   .Lgk_pattern_kit_paste_finish
.Lgk_pattern_kit_paste_late_failure:
        move.l  %d5,%d0
        bra.s   .Lgk_pattern_kit_paste_finish
.Lgk_pattern_kit_paste_snapshot_abort_corrupt:
        jsr     gk_persistence_snapshot_end
.Lgk_pattern_kit_paste_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_pattern_kit_paste_finish
.Lgk_pattern_kit_paste_snapshot_abort:
        move.l  %d0,%d5
        jsr     gk_persistence_snapshot_end
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_corrupt
        move.l  %d5,%d0
.Lgk_pattern_kit_paste_finish:
        move.l  %d0,%d4
        clr.b   __gk_pattern_kit_armed
        move.l  %d4,%d0
        lea     .Lgk_pattern_kit_paste_message,%a0
        jsr     gk_part_edit_notify_result
        moveq   #0,%d0
        bra.s   .Lgk_pattern_kit_paste_restore
.Lgk_pattern_kit_paste_not_handled_restore:
        moveq   #1,%d0
.Lgk_pattern_kit_paste_restore:
        movem.l (%sp),%d2-%d7/%a2-%a3
        lea     32(%sp),%sp
        rts
.Lgk_pattern_kit_paste_not_handled:
        moveq   #1,%d0
        rts
        .size   gk_pattern_kit_paste_dispatch,.-gk_pattern_kit_paste_dispatch
        .align  4
.Lgk_pattern_kit_paste_message:
        .byte 0x4b,0x49,0x54,0x20
        .incbin "stock/0438.bin", 0, 5
        .byte 0x44,0x00
        .align  4
        .global gk_pattern_kit_mkii_part_dispatch
        .type   gk_pattern_kit_mkii_part_dispatch,@function
gk_pattern_kit_mkii_part_dispatch:
        bsr.w   gk_pattern_kit_paste_dispatch
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_mkii_part_stock
        rts
.Lgk_pattern_kit_mkii_part_stock:
        moveq   #GK_QUICK_SAVE_INITIATOR_PART,%d0
        move.b  %d0,__gk_ui_state_pad + 2
        .byte 0x4e,0xf9
        .incbin "stock/0439.bin", 0, 4
        .size   gk_pattern_kit_mkii_part_dispatch,.-gk_pattern_kit_mkii_part_dispatch
        .align  4
        .global gk_pattern_kit_mki_part_dispatch
        .type   gk_pattern_kit_mki_part_dispatch,@function
gk_pattern_kit_mki_part_dispatch:
        bsr.w   gk_pattern_kit_paste_dispatch
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_mki_part_stock
        rts
.Lgk_pattern_kit_mki_part_stock:
        .byte 0x4e,0xf9
        .incbin "stock/0440.bin", 0, 4
        .size   gk_pattern_kit_mki_part_dispatch,.-gk_pattern_kit_mki_part_dispatch
        .global gk_pattern_kit_mki_part_lifecycle_dispatch
        .type   gk_pattern_kit_mki_part_lifecycle_dispatch,@function
gk_pattern_kit_mki_part_lifecycle_dispatch:
        lea     -12(%sp),%sp
        moveq   #1,%d0
        move.l  %d0,8(%sp)
        bsr.w   gk_pattern_kit_paste_dispatch
        lea     12(%sp),%sp
        rts
        .size   gk_pattern_kit_mki_part_lifecycle_dispatch,.-gk_pattern_kit_mki_part_lifecycle_dispatch
        .align  4
        .global gk_next_pattern_clone_ptn_press
        .type   gk_next_pattern_clone_ptn_press,@function
gk_next_pattern_clone_ptn_press:
        clr.b   __gk_next_pattern_clone_latch
        .byte 0x4e,0xf9
        .incbin "stock/0441.bin", 0, 4
        .size   gk_next_pattern_clone_ptn_press,.-gk_next_pattern_clone_ptn_press
        .type   gk_next_pattern_clone_copy_image,@function
gk_next_pattern_clone_copy_image:
        move.l  #(GK_STOCK_PATTERN_STRIDE / 4),%d0
.Lgk_next_pattern_clone_copy_image_loop:
        move.l  (%a2)+,(%a3)+
        subq.l  #1,%d0
        bne.s   .Lgk_next_pattern_clone_copy_image_loop
        rts
        .size   gk_next_pattern_clone_copy_image,.-gk_next_pattern_clone_copy_image
        .global gk_next_pattern_clone_execute
        .type   gk_next_pattern_clone_execute,@function
gk_next_pattern_clone_execute:
        .incbin "stock/0442.bin", 0, 4
        .incbin "stock/0442.bin", 4, 4
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_next_pattern_clone_busy
        cmp.b   GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        bne.w   .Lgk_next_pattern_clone_busy
        move.l  %d0,%d6
        lsl.l   #4,%d6
        moveq   #0,%d1
        move.b  __gk_current_pattern,%d1
        cmpi.l  #15,%d1
        bhi.w   .Lgk_next_pattern_clone_busy
        cmp.b   GK_STOCK_CURRENT_PATTERN_PRIMARY,%d1
        bne.w   .Lgk_next_pattern_clone_busy
        add.l   %d1,%d6
        move.l  %d6,%d7
        addq.l  #1,%d7
        andi.l  #0xff,%d7
        moveq   #0,%d4
        move.b  __gk_current_kit,%d4
        move.l  %d7,%d0
        lsr.l   #4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a0
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_BANK_STATUS_OFFSET,%a0
        tst.l   (%a0)
        bne.w   .Lgk_next_pattern_clone_busy
        move.l  %d7,%d0
        bsr.w   gk_pattern_kit_allocate_for_pattern
        cmpi.l  #GK_ERR_CORRUPT,%d0
        beq.w   gk_next_pattern_clone_allocate_report_fatal
        tst.l   %d0
        bmi.w   .Lgk_next_pattern_clone_finish
        move.l  %d0,%d5
        jsr     gk_workspace_save
        cmpi.l  #GK_ERR_CORRUPT,%d0
        beq.w   gk_next_pattern_clone_save_report_fatal
        tst.l   %d0
        bne.w   .Lgk_next_pattern_clone_finish
        moveq   #1,%d0
        move.l  %d6,%d1
        lsr.l   #4,%d1
        lsl.l   %d1,%d0
        move.l  %d0,%d2
        moveq   #1,%d0
        move.l  %d7,%d1
        lsr.l   #4,%d1
        lsl.l   %d1,%d0
        or.l    %d2,%d0
        jsr     gk_stock_dirty_mark_bank_mask
        tst.l   %d0
        bne.w   gk_next_pattern_clone_dirty_report_fatal
        jsr     gk_persistence_snapshot_begin
        cmpi.l  #GK_ERR_CORRUPT,%d0
        beq.w   gk_next_pattern_clone_snapshot_begin_report_fatal
        tst.l   %d0
        bne.w   .Lgk_next_pattern_clone_finish
        move.l  %d4,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a0
        adda.l  %d0,%a0
        move.l  %d4,%d0
        lsl.l   #3,%d0
        lea     __gk_kit_names,%a1
        adda.l  %d0,%a1
        move.l  %d5,%d0
        moveq   #1,%d1
        jsr     gk_kit_record_apply
        tst.l   %d0
        bne.w   gk_next_pattern_clone_kit_apply_report_fatal
        move.l  %d6,%d0
        move.l  %d0,%d1
        andi.l  #15,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        lsr.l   #4,%d1
        move.l  #GK_STOCK_BANK_STRIDE,%d2
        muls.l  %d2,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        move.l  %d7,%d0
        move.l  %d0,%d1
        andi.l  #15,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        lsr.l   #4,%d1
        move.l  #GK_STOCK_BANK_STRIDE,%d2
        muls.l  %d2,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        adda.l  %d0,%a3
        bsr.w   gk_next_pattern_clone_copy_image
        move.l  %d6,%d0
        lsr.l   #4,%d0
        move.l  %d7,%d1
        lsr.l   #4,%d1
        cmp.l   %d1,%d0
        bne.s   .Lgk_next_pattern_clone_pattern_copied
        move.l  %d6,%d0
        andi.l  #15,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a2
        adda.l  %d0,%a2
        move.l  %d7,%d0
        andi.l  #15,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a3
        adda.l  %d0,%a3
        bsr.w   gk_next_pattern_clone_copy_image
.Lgk_next_pattern_clone_pattern_copied:
        lea     __gk_pattern_assignments,%a0
        move.b  %d5,(%a0,%d7.l)
        move.l  %d7,%d0
        move.l  %d7,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_pattern_assignment_valid,%a0
        bset    %d1,(%a0,%d0.l)
        move.l  %d7,%d0
        move.l  %d5,%d1
        .global gk_next_pattern_clone_assignment_v3_dirty_call
gk_next_pattern_clone_assignment_v3_dirty_call:
        jsr     gk_persistence_v3_mark_assignment_dirty
        tst.l   %d0
        bne.w   gk_next_pattern_clone_assignment_dirty_report_fatal
        jsr     gk_persistence_snapshot_end
        tst.l   %d0
        bne.w   gk_next_pattern_clone_snapshot_end_report_fatal
        moveq   #1,%d0
        move.b  %d0,__gk_next_pattern_clone_latch
        move.l  %d7,%d0
        andi.l  #15,%d0
        move.l  %d0,-(%sp)
        move.l  %d7,%d0
        lsr.l   #4,%d0
        move.l  %d0,-(%sp)
        jsr     GK_STOCK_PATTERN_SCHEDULE_REQUEST_ENTRY
        addq.l  #8,%sp
        moveq   #-1,%d0
        move.l  %d0,GK_STOCK_PATTERN_SELECTION_PERFORMED
        moveq   #GK_OK,%d0
        bra.s   .Lgk_next_pattern_clone_finish
.Lgk_next_pattern_clone_busy:
        moveq   #GK_ERR_BUSY,%d0
.Lgk_next_pattern_clone_finish:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
        .size   gk_next_pattern_clone_execute,.-gk_next_pattern_clone_execute
        .align  4
        .global gk_next_pattern_clone_right_dispatch
        .type   gk_next_pattern_clone_right_dispatch,@function
gk_next_pattern_clone_right_dispatch:
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne.w   .Lgk_next_pattern_clone_right_stock
        tst.b   __gk_next_pattern_clone_latch
        bne.w   .Lgk_next_pattern_clone_right_consumed
        cmp.l   GK_STOCK_PATTERN_SELECT_STATE,%d0
        bne.w   .Lgk_next_pattern_clone_right_stock
        pea     GK_STOCK_PATTERN_PRESS_INPUT
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        beq.w   .Lgk_next_pattern_clone_right_stock
        .incbin "stock/0443.bin", 0, 4
        .incbin "stock/0443.bin", 4, 6
        .incbin "stock/0443.bin", 10, 2
        .incbin "stock/0443.bin", 12, 2
        .incbin "stock/0443.bin", 14, 3
        .byte 0x3e
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_next_pattern_clone_right_stock
        tst.b   __gk_ui_mode
        bne.w   .Lgk_next_pattern_clone_right_stock
        tst.l   GK_STOCK_CALLBACK_MENU_OBJECT
        bne.w   .Lgk_next_pattern_clone_right_stock
        tst.l   GK_STOCK_TEXT_EDITOR_OBJECT
        bne.w   .Lgk_next_pattern_clone_right_stock
        bsr.w   gk_next_pattern_clone_execute
        move.l  %d0,-(%sp)
        lea     .Lgk_next_pattern_clone_message,%a0
        jsr     gk_part_edit_notify_result
        move.l  (%sp)+,%d0
.Lgk_next_pattern_clone_right_consumed:
        rts
.Lgk_next_pattern_clone_right_stock:
        .byte 0x4e,0xf9
        .incbin "stock/0444.bin", 0, 4
        .size   gk_next_pattern_clone_right_dispatch,.-gk_next_pattern_clone_right_dispatch
        .align  4
.Lgk_next_pattern_clone_message:
        .asciz  "PAT+KIT CLONED"
        .align  2
        .global gk_next_pattern_clone_allocate_report_fatal
        .type gk_next_pattern_clone_allocate_report_fatal,@function
gk_next_pattern_clone_allocate_report_fatal:
        illegal
        .size gk_next_pattern_clone_allocate_report_fatal,.-gk_next_pattern_clone_allocate_report_fatal
        .global gk_next_pattern_clone_save_report_fatal
        .type gk_next_pattern_clone_save_report_fatal,@function
gk_next_pattern_clone_save_report_fatal:
        illegal
        .size gk_next_pattern_clone_save_report_fatal,.-gk_next_pattern_clone_save_report_fatal
        .global gk_next_pattern_clone_dirty_report_fatal
        .type gk_next_pattern_clone_dirty_report_fatal,@function
gk_next_pattern_clone_dirty_report_fatal:
        illegal
        .size gk_next_pattern_clone_dirty_report_fatal,.-gk_next_pattern_clone_dirty_report_fatal
        .global gk_next_pattern_clone_snapshot_begin_report_fatal
        .type gk_next_pattern_clone_snapshot_begin_report_fatal,@function
gk_next_pattern_clone_snapshot_begin_report_fatal:
        illegal
        .size gk_next_pattern_clone_snapshot_begin_report_fatal,.-gk_next_pattern_clone_snapshot_begin_report_fatal
        .global gk_next_pattern_clone_kit_apply_report_fatal
        .type gk_next_pattern_clone_kit_apply_report_fatal,@function
gk_next_pattern_clone_kit_apply_report_fatal:
        illegal
        .size gk_next_pattern_clone_kit_apply_report_fatal,.-gk_next_pattern_clone_kit_apply_report_fatal
        .global gk_next_pattern_clone_assignment_dirty_report_fatal
        .type gk_next_pattern_clone_assignment_dirty_report_fatal,@function
gk_next_pattern_clone_assignment_dirty_report_fatal:
        illegal
        .size gk_next_pattern_clone_assignment_dirty_report_fatal,.-gk_next_pattern_clone_assignment_dirty_report_fatal
        .global gk_next_pattern_clone_snapshot_end_report_fatal
        .type gk_next_pattern_clone_snapshot_end_report_fatal,@function
gk_next_pattern_clone_snapshot_end_report_fatal:
        illegal
        .size gk_next_pattern_clone_snapshot_end_report_fatal,.-gk_next_pattern_clone_snapshot_end_report_fatal
        .global gk_next_pattern_clone_fatal
        .type   gk_next_pattern_clone_fatal,@function
gk_next_pattern_clone_fatal:
        illegal
        bra.s   gk_next_pattern_clone_fatal
        .size   gk_next_pattern_clone_fatal,.-gk_next_pattern_clone_fatal
