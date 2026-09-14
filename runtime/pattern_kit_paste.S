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
        .incbin "stock/0437.bin", 0, 4
        .incbin "stock/0437.bin", 4, 6
        .global gk_stock_pattern_copy_capture_trampoline_jump
gk_stock_pattern_copy_capture_trampoline_jump:
        jmp     GK_STOCK_PATTERN_COPY_CAPTURE_FIXED_CONTINUE
        .size   gk_stock_pattern_copy_capture_trampoline,.-gk_stock_pattern_copy_capture_trampoline
        .global gk_pattern_kit_capture_workspace
        .type   gk_pattern_kit_capture_workspace,@function
gk_pattern_kit_capture_workspace:
        .incbin "stock/0438.bin", 0, 4
        .incbin "stock/0438.bin", 4, 4
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        lsl.l   #4,%d0
        moveq   #0,%d1
        move.b  __gk_current_pattern,%d1
        add.l   %d1,%d0
        bsr.w   gk_inactive_pattern_capture_clipboard_assignment
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
        .incbin "stock/0439.bin", 0, 4
        .incbin "stock/0439.bin", 4, 4
        jsr     gk_function_map_active
        tst.l   %d0
        beq.w   .Lgk_pattern_kit_paste_not_handled_restore
        .incbin "stock/0440.bin", 0, 4
        .incbin "stock/0440.bin", 4, 6
        .incbin "stock/0440.bin", 10, 2
        .incbin "stock/0440.bin", 12, 2
        .incbin "stock/0440.bin", 14, 2
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
        .incbin "stock/0441.bin", 0, 5
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
        .incbin "stock/0442.bin", 0, 4
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
        .incbin "stock/0443.bin", 0, 4
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
        clr.b   __gk_inactive_pattern_mode
        clr.b   __gk_inactive_pattern_target
        clr.b   __gk_inactive_pattern_target_trig
        clr.b   __gk_inactive_pattern_action_latch
        .byte 0x4e,0xf9
        .incbin "stock/0444.bin", 0, 4
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
        .incbin "stock/0445.bin", 0, 4
        .incbin "stock/0445.bin", 4, 4
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
        move.b  %d7,__gk_next_pattern_clone_target
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
        .incbin "stock/0446.bin", 0, 4
        .incbin "stock/0446.bin", 4, 6
        .incbin "stock/0446.bin", 10, 2
        .incbin "stock/0446.bin", 12, 2
        .incbin "stock/0446.bin", 14, 3
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
        .incbin "stock/0447.bin", 0, 4
        .size   gk_next_pattern_clone_right_dispatch,.-gk_next_pattern_clone_right_dispatch
        .align  4
        .global gk_next_pattern_clone_save_route
        .type   gk_next_pattern_clone_save_route,@function
gk_next_pattern_clone_save_route:
        lea     -16(%sp),%sp
        movem.l %d2-%d4/%a0,(%sp)
        move.l  %d0,%d4
        moveq   #0,%d0
        move.b  __gk_next_pattern_clone_latch,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_next_pattern_clone_save_route_latch_corrupt
        beq.s   .Lgk_next_pattern_clone_save_route_active
        bra.w   .Lgk_next_pattern_clone_save_route_ordinary
.Lgk_next_pattern_clone_save_route_active:
        moveq   #0,%d2
        move.b  __gk_current_bank,%d2
        cmpi.l  #15,%d2
        bhi.w   .Lgk_next_pattern_clone_save_route_bank_corrupt
        lsl.l   #4,%d2
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_next_pattern_clone_save_route_pattern_corrupt
        add.l   %d0,%d2
        moveq   #0,%d3
        move.b  __gk_next_pattern_clone_target,%d3
        cmp.l   %d3,%d2
        beq.s   .Lgk_next_pattern_clone_save_route_activated
        moveq   #0,%d0
        move.b  GK_STOCK_QUEUED_BANK,%d0
        cmpi.l  #15,%d0
        bhi.s   .Lgk_next_pattern_clone_save_route_stale
        lsl.l   #4,%d0
        moveq   #0,%d1
        move.b  GK_STOCK_QUEUED_PATTERN,%d1
        cmpi.l  #15,%d1
        bhi.s   .Lgk_next_pattern_clone_save_route_stale
        add.l   %d1,%d0
        cmp.l   %d3,%d0
        bne.s   .Lgk_next_pattern_clone_save_route_stale
        move.l  %d3,%d0
        move.l  %d3,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_pattern_assignment_valid,%a0
        btst    %d1,(%a0,%d0.l)
        beq.w   .Lgk_next_pattern_clone_save_route_valid_corrupt
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d0
        move.b  (%a0,%d3.l),%d0
        cmp.l   %d4,%d0
        beq.s   .Lgk_next_pattern_clone_save_route_target
        bra.s   .Lgk_next_pattern_clone_save_route_ordinary
.Lgk_next_pattern_clone_save_route_activated:
.Lgk_next_pattern_clone_save_route_stale:
        clr.b   __gk_next_pattern_clone_latch
.Lgk_next_pattern_clone_save_route_ordinary:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_next_pattern_clone_save_route_finish
.Lgk_next_pattern_clone_save_route_target:
        moveq   #1,%d0
.Lgk_next_pattern_clone_save_route_finish:
        movem.l (%sp),%d2-%d4/%a0
        lea     16(%sp),%sp
        rts
.Lgk_next_pattern_clone_save_route_latch_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.w   gk_next_pattern_clone_save_route_latch_report_fatal
.Lgk_next_pattern_clone_save_route_bank_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.w   gk_next_pattern_clone_save_route_bank_report_fatal
.Lgk_next_pattern_clone_save_route_pattern_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.w   gk_next_pattern_clone_save_route_pattern_report_fatal
.Lgk_next_pattern_clone_save_route_valid_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.w   gk_next_pattern_clone_save_route_valid_report_fatal
        .size   gk_next_pattern_clone_save_route,.-gk_next_pattern_clone_save_route
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
        .global gk_next_pattern_clone_save_route_latch_report_fatal
        .type gk_next_pattern_clone_save_route_latch_report_fatal,@function
gk_next_pattern_clone_save_route_latch_report_fatal:
        illegal
        .size gk_next_pattern_clone_save_route_latch_report_fatal,.-gk_next_pattern_clone_save_route_latch_report_fatal
        .global gk_next_pattern_clone_save_route_bank_report_fatal
        .type gk_next_pattern_clone_save_route_bank_report_fatal,@function
gk_next_pattern_clone_save_route_bank_report_fatal:
        illegal
        .size gk_next_pattern_clone_save_route_bank_report_fatal,.-gk_next_pattern_clone_save_route_bank_report_fatal
        .global gk_next_pattern_clone_save_route_pattern_report_fatal
        .type gk_next_pattern_clone_save_route_pattern_report_fatal,@function
gk_next_pattern_clone_save_route_pattern_report_fatal:
        illegal
        .size gk_next_pattern_clone_save_route_pattern_report_fatal,.-gk_next_pattern_clone_save_route_pattern_report_fatal
        .global gk_next_pattern_clone_save_route_valid_report_fatal
        .type gk_next_pattern_clone_save_route_valid_report_fatal,@function
gk_next_pattern_clone_save_route_valid_report_fatal:
        illegal
        .size gk_next_pattern_clone_save_route_valid_report_fatal,.-gk_next_pattern_clone_save_route_valid_report_fatal
        .global gk_next_pattern_clone_fatal
        .type   gk_next_pattern_clone_fatal,@function
gk_next_pattern_clone_fatal:
        illegal
        bra.s   gk_next_pattern_clone_fatal
        .size   gk_next_pattern_clone_fatal,.-gk_next_pattern_clone_fatal
        .align  4
        .global gk_inactive_pattern_bank_press
        .type   gk_inactive_pattern_bank_press,@function
gk_inactive_pattern_bank_press:
        moveq   #GK_INACTIVE_PATTERN_MODE_BANK_SELECT,%d0
        move.b  %d0,__gk_inactive_pattern_mode
        clr.b   __gk_inactive_pattern_target
        clr.b   __gk_inactive_pattern_target_trig
        clr.b   __gk_inactive_pattern_action_latch
        clr.b   __gk_inactive_pattern_pending_notice
        .byte 0x4e,0xf9
        .incbin "stock/0448.bin", 0, 4
        .size   gk_inactive_pattern_bank_press,.-gk_inactive_pattern_bank_press
        .align  4
        .global gk_inactive_pattern_bank_release
        .type   gk_inactive_pattern_bank_release,@function
gk_inactive_pattern_bank_release:
        move.l  %d2,-(%sp)
        moveq   #0,%d2
        move.b  __gk_inactive_pattern_pending_notice,%d2
        clr.b   __gk_inactive_pattern_pending_notice
        tst.b   __gk_inactive_pattern_action_latch
        beq.s   .Lgk_inactive_pattern_bank_release_state
        clr.l   GK_STOCK_BANK_SELECTION_PERFORMED
.Lgk_inactive_pattern_bank_release_state:
        clr.b   __gk_inactive_pattern_mode
        clr.b   __gk_inactive_pattern_target
        clr.b   __gk_inactive_pattern_target_trig
        .byte 0x4e,0xb9
        .incbin "stock/0449.bin", 0, 4
        tst.b   __gk_inactive_pattern_action_latch
        beq.s   .Lgk_inactive_pattern_bank_release_hidden_done
        clr.b   __gk_inactive_pattern_action_latch
        move.l  %d2,-(%sp)
        .global gk_inactive_pattern_bank_release_close_call
gk_inactive_pattern_bank_release_close_call:
        jsr     GK_STOCK_BANK_COUNTDOWN_CALLBACK
        move.l  (%sp)+,%d2
.Lgk_inactive_pattern_bank_release_hidden_done:
        tst.l   %d2
        beq.s   .Lgk_inactive_pattern_bank_release_done
        lea     GK_STOCK_PATTERN_COPY_TEXT,%a0
        moveq   #0,%d0
        cmpi.l  #1,%d2
        beq.s   .Lgk_inactive_pattern_bank_release_notify
        lea     GK_STOCK_PATTERN_CLEAR_TEXT,%a0
        cmpi.l  #2,%d2
        beq.s   .Lgk_inactive_pattern_bank_release_notify
        lea     GK_STOCK_PATTERN_PASTE_TEXT,%a0
        cmpi.l  #3,%d2
        beq.s   .Lgk_inactive_pattern_bank_release_notify
        lea     GK_STOCK_PATTERN_UNDO_TEXT,%a0
        cmpi.l  #4,%d2
        beq.s   .Lgk_inactive_pattern_bank_release_notify
        lea     .Lgk_inactive_pattern_protected_message,%a0
        cmpi.l  #5,%d2
        beq.s   .Lgk_inactive_pattern_bank_release_notify
        lea     GK_STOCK_PATTERN_COPY_TEXT,%a0
        moveq   #GK_ERR_BUSY,%d0
        cmpi.l  #6,%d2
        beq.s   .Lgk_inactive_pattern_bank_release_notify
        moveq   #GK_ERR_INVALID,%d0
.Lgk_inactive_pattern_bank_release_notify:
        jsr     gk_part_edit_notify_result
.Lgk_inactive_pattern_bank_release_done:
        move.l  (%sp)+,%d2
        rts
        .size   gk_inactive_pattern_bank_release,.-gk_inactive_pattern_bank_release
        .align  4
        .global gk_inactive_pattern_bank_panel_hide
        .type   gk_inactive_pattern_bank_panel_hide,@function
gk_inactive_pattern_bank_panel_hide:
        move.l  %a0,-(%sp)
        move.l  GK_STOCK_PATTERN_COUNTDOWN_CALLBACK,%d0
        cmpi.l  #GK_STOCK_BANK_COUNTDOWN_CALLBACK,%d0
        bne.s   .Lgk_inactive_pattern_bank_panel_hide_done
        clr.l   GK_STOCK_PATTERN_COUNTDOWN_CALLBACK
        .global gk_inactive_pattern_bank_panel_close_call
gk_inactive_pattern_bank_panel_close_call:
        jsr     GK_STOCK_PATTERN_COUNTDOWN_CLOSE
.Lgk_inactive_pattern_bank_panel_hide_done:
        move.l  (%sp)+,%a0
        rts
        .size   gk_inactive_pattern_bank_panel_hide,.-gk_inactive_pattern_bank_panel_hide
        .align  4
        .global gk_inactive_pattern_ptn_trig_press
        .type   gk_inactive_pattern_ptn_trig_press,@function
gk_inactive_pattern_ptn_trig_press:
        move.l  4(%sp),%d1
        cmpi.l  #15,%d1
        bhi.s   .Lgk_inactive_pattern_ptn_trig_stock
        tst.b   __gk_inactive_pattern_mode
        bne.s   .Lgk_inactive_pattern_ptn_trig_stock
        pea     GK_STOCK_PATTERN_PRESS_INPUT
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        beq.s   .Lgk_inactive_pattern_ptn_trig_stock
        pea     GK_STOCK_FUNCTION_PRESS_INPUT
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        beq.s   .Lgk_inactive_pattern_ptn_trig_stock
        move.l  4(%sp),%d1
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        lsl.l   #4,%d0
        add.l   %d1,%d0
        move.b  %d0,__gk_inactive_pattern_target
        move.b  %d1,__gk_inactive_pattern_target_trig
        moveq   #GK_INACTIVE_PATTERN_MODE_PTN_TARGET,%d0
        move.b  %d0,__gk_inactive_pattern_mode
        rts
.Lgk_inactive_pattern_ptn_trig_stock:
        .byte 0x4e,0xf9
        .incbin "stock/0450.bin", 0, 4
        .size   gk_inactive_pattern_ptn_trig_press,.-gk_inactive_pattern_ptn_trig_press
        .align  4
        .global gk_inactive_pattern_ptn_trig_release
        .type   gk_inactive_pattern_ptn_trig_release,@function
gk_inactive_pattern_ptn_trig_release:
        moveq   #GK_INACTIVE_PATTERN_MODE_PTN_TARGET,%d0
        cmp.b   __gk_inactive_pattern_mode,%d0
        bne.s   .Lgk_inactive_pattern_ptn_trig_release_stock
        moveq   #0,%d0
        move.b  __gk_inactive_pattern_target_trig,%d0
        cmp.l   4(%sp),%d0
        bne.s   .Lgk_inactive_pattern_ptn_trig_release_stock
        clr.b   __gk_inactive_pattern_mode
        clr.b   __gk_inactive_pattern_target
        clr.b   __gk_inactive_pattern_target_trig
        rts
.Lgk_inactive_pattern_ptn_trig_release_stock:
        .byte 0x4e,0xf9
        .incbin "stock/0451.bin", 0, 4
        .size   gk_inactive_pattern_ptn_trig_release,.-gk_inactive_pattern_ptn_trig_release
        .align  4
        .global gk_inactive_pattern_bank_trig_press
        .type   gk_inactive_pattern_bank_trig_press,@function
gk_inactive_pattern_bank_trig_press:
        moveq   #GK_INACTIVE_PATTERN_MODE_BANK_SELECT,%d0
        cmp.b   __gk_inactive_pattern_mode,%d0
        bne.s   .Lgk_inactive_pattern_bank_trig_target_candidate
        move.l  4(%sp),-(%sp)
        .byte 0x4e,0xb9
        .incbin "stock/0452.bin", 0, 4
        addq.l  #4,%sp
        moveq   #1,%d0
        cmp.l   GK_STOCK_BANK_SELECT_STATE,%d0
        bne.s   .Lgk_inactive_pattern_bank_trig_return
        move.l  4(%sp),%d1
        cmp.l   GK_STOCK_BANK_SELECTED,%d1
        bne.s   .Lgk_inactive_pattern_bank_trig_return
        moveq   #GK_INACTIVE_PATTERN_MODE_BANK_READY,%d0
        move.b  %d0,__gk_inactive_pattern_mode
.Lgk_inactive_pattern_bank_trig_return:
        rts
.Lgk_inactive_pattern_bank_trig_target_candidate:
        moveq   #GK_INACTIVE_PATTERN_MODE_BANK_READY,%d0
        cmp.b   __gk_inactive_pattern_mode,%d0
        beq.s   .Lgk_inactive_pattern_bank_trig_target
        moveq   #GK_INACTIVE_PATTERN_MODE_BANK_TARGET,%d0
        cmp.b   __gk_inactive_pattern_mode,%d0
        bne.s   .Lgk_inactive_pattern_bank_trig_stock
.Lgk_inactive_pattern_bank_trig_target:
        move.l  4(%sp),%d1
        cmpi.l  #15,%d1
        bhi.s   .Lgk_inactive_pattern_bank_trig_stock
        pea     GK_STOCK_BANK_PRESS_INPUT
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        beq.s   .Lgk_inactive_pattern_bank_trig_stock
        pea     GK_STOCK_FUNCTION_PRESS_INPUT
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        beq.s   .Lgk_inactive_pattern_bank_trig_stock
        move.l  4(%sp),%d1
        move.l  GK_STOCK_BANK_SELECTED,%d0
        cmpi.l  #15,%d0
        bhi.s   .Lgk_inactive_pattern_bank_trig_stock
        lsl.l   #4,%d0
        add.l   %d1,%d0
        move.b  %d0,__gk_inactive_pattern_target
        move.b  %d1,__gk_inactive_pattern_target_trig
        moveq   #GK_INACTIVE_PATTERN_MODE_BANK_TARGET,%d0
        move.b  %d0,__gk_inactive_pattern_mode
        rts
.Lgk_inactive_pattern_bank_trig_stock:
        .byte 0x4e,0xf9
        .incbin "stock/0453.bin", 0, 4
        .size   gk_inactive_pattern_bank_trig_press,.-gk_inactive_pattern_bank_trig_press
        .align  4
        .global gk_inactive_pattern_bank_trig_release
        .type   gk_inactive_pattern_bank_trig_release,@function
gk_inactive_pattern_bank_trig_release:
        moveq   #GK_INACTIVE_PATTERN_MODE_BANK_TARGET,%d0
        cmp.b   __gk_inactive_pattern_mode,%d0
        bne.s   .Lgk_inactive_pattern_bank_trig_release_stock
        moveq   #0,%d0
        move.b  __gk_inactive_pattern_target_trig,%d0
        cmp.l   4(%sp),%d0
        bne.s   .Lgk_inactive_pattern_bank_trig_release_stock
        moveq   #GK_INACTIVE_PATTERN_MODE_BANK_READY,%d0
        move.b  %d0,__gk_inactive_pattern_mode
        clr.b   __gk_inactive_pattern_target
        clr.b   __gk_inactive_pattern_target_trig
        rts
.Lgk_inactive_pattern_bank_trig_release_stock:
        .byte 0x4e,0xf9
        .incbin "stock/0454.bin", 0, 4
        .size   gk_inactive_pattern_bank_trig_release,.-gk_inactive_pattern_bank_trig_release
        .type   gk_inactive_pattern_target_address,@function
gk_inactive_pattern_target_address:
        move.l  %d0,%d1
        cmpi.l  #255,%d1
        bhi.s   .Lgk_inactive_pattern_target_range
        move.l  %d1,%d0
        lsr.l   #4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d2
        muls.l  %d2,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        adda.l  %d0,%a3
        movea.l %a3,%a0
        adda.l  #GK_STOCK_BANK_STATUS_OFFSET,%a0
        tst.l   (%a0)
        bne.s   .Lgk_inactive_pattern_target_busy
        move.l  %d1,%d0
        andi.l  #15,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        adda.l  %d0,%a3
        moveq   #GK_OK,%d0
        rts
.Lgk_inactive_pattern_target_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
.Lgk_inactive_pattern_target_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_inactive_pattern_target_address,.-gk_inactive_pattern_target_address
        .type   gk_inactive_pattern_protection_check,@function
gk_inactive_pattern_protection_check:
        move.l  %d0,%d2
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        lsl.l   #4,%d0
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d1
        add.l   %d1,%d0
        cmp.l   %d2,%d0
        beq.s   .Lgk_inactive_pattern_stock_current
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        lsl.l   #4,%d0
        moveq   #0,%d1
        move.b  __gk_current_pattern,%d1
        add.l   %d1,%d0
        cmp.l   %d2,%d0
        beq.s   .Lgk_inactive_pattern_protected
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        lsl.l   #4,%d0
        moveq   #0,%d1
        move.b  GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d1
        add.l   %d1,%d0
        cmp.l   %d2,%d0
        beq.s   .Lgk_inactive_pattern_protected
        move.l  GK_STOCK_SCHEDULER_STATE,%d0
        cmpi.l  #2,%d0
        bhi.w   gk_inactive_pattern_scheduler_report_fatal
        tst.l   %d0
        beq.s   .Lgk_inactive_pattern_unprotected
        moveq   #0,%d0
        move.b  GK_STOCK_QUEUED_BANK,%d0
        lsl.l   #4,%d0
        moveq   #0,%d1
        move.b  GK_STOCK_QUEUED_PATTERN,%d1
        add.l   %d1,%d0
        cmp.l   %d2,%d0
        beq.s   .Lgk_inactive_pattern_protected
.Lgk_inactive_pattern_unprotected:
        moveq   #GK_OK,%d0
        rts
.Lgk_inactive_pattern_protected:
        moveq   #GK_ERR_BUSY,%d0
        rts
.Lgk_inactive_pattern_stock_current:
        moveq   #GK_ERR_INVALID,%d0
        rts
        .size   gk_inactive_pattern_protection_check,.-gk_inactive_pattern_protection_check
        .type   gk_inactive_pattern_fill,@function
gk_inactive_pattern_fill:
        move.b  %d1,(%a0)+
        subq.l  #1,%d0
        bne.s   gk_inactive_pattern_fill
        rts
        .size   gk_inactive_pattern_fill,.-gk_inactive_pattern_fill
        .type   gk_inactive_pattern_clear_image,@function
gk_inactive_pattern_clear_image:
        lea     -12(%sp),%sp
        movem.l %d5/%a4-%a5,(%sp)
        movea.l %a3,%a4
        moveq   #7,%d5
.Lgk_inactive_pattern_clear_audio:
        movea.l %a4,%a0
        moveq   #0,%d1
        moveq   #0x40,%d0
        bsr.w   gk_inactive_pattern_fill
        move.l  #0xaaaaaaaa,%d0
        move.l  %d0,0x40(%a4)
        move.l  %d0,0x44(%a4)
        lea     0x48(%a4),%a0
        moveq   #8,%d0
        bsr.w   gk_inactive_pattern_fill
        move.b  #0x10,0x50(%a4)
        move.b  #0x02,0x51(%a4)
        lea     0x59(%a4),%a0
        moveq   #-1,%d1
        move.l  #0x800,%d0
        bsr.w   gk_inactive_pattern_fill
        lea     0x859(%a4),%a0
        moveq   #0,%d1
        moveq   #0x40,%d0
        bsr.w   gk_inactive_pattern_fill
        lea     0x89a(%a4),%a0
        move.l  #0x80,%d0
        bsr.w   gk_inactive_pattern_fill
        adda.l  #0x91a,%a4
        subq.l  #1,%d5
        bpl.w   .Lgk_inactive_pattern_clear_audio
        lea     0x48d0(%a3),%a4
        moveq   #7,%d5
.Lgk_inactive_pattern_clear_midi:
        movea.l %a4,%a0
        moveq   #0,%d1
        moveq   #0x18,%d0
        bsr.w   gk_inactive_pattern_fill
        move.l  #0xaaaaaaaa,%d0
        move.l  %d0,0x18(%a4)
        move.l  %d0,0x1c(%a4)
        lea     0x20(%a4),%a0
        moveq   #8,%d0
        bsr.w   gk_inactive_pattern_fill
        move.b  #0x10,0x28(%a4)
        move.b  #0x02,0x29(%a4)
        lea     0x30(%a4),%a0
        moveq   #-1,%d1
        move.l  #0x800,%d0
        bsr.w   gk_inactive_pattern_fill
        lea     0x830(%a4),%a0
        moveq   #0,%d1
        move.l  #0x80,%d0
        bsr.w   gk_inactive_pattern_fill
        adda.l  #0x8b0,%a4
        subq.l  #1,%d5
        bpl.w   .Lgk_inactive_pattern_clear_midi
        movea.l %a3,%a0
        adda.l  #0x8e50,%a0
        clr.b   (%a0)
        move.b  #0x40,1(%a0)
        move.b  #0x02,2(%a0)
        movem.l (%sp),%d5/%a4-%a5
        lea     12(%sp),%sp
        rts
        .size   gk_inactive_pattern_clear_image,.-gk_inactive_pattern_clear_image
        .type   gk_inactive_pattern_sync_mirror,@function
gk_inactive_pattern_sync_mirror:
        move.l  %d0,%d1
        lsr.l   #4,%d1
        moveq   #0,%d2
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d2
        cmp.l   %d2,%d1
        bne.s   .Lgk_inactive_pattern_sync_mirror_done
        move.l  %d0,%d4
        bsr.w   gk_inactive_pattern_target_address
        tst.l   %d0
        bne.s   .Lgk_inactive_pattern_sync_mirror_done
        movea.l %a3,%a2
        move.l  %d4,%d0
        andi.l  #15,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a3
        adda.l  %d0,%a3
        bsr.w   gk_next_pattern_clone_copy_image
.Lgk_inactive_pattern_sync_mirror_done:
        rts
        .size   gk_inactive_pattern_sync_mirror,.-gk_inactive_pattern_sync_mirror
        .type   gk_inactive_pattern_capture_clipboard_assignment,@function
gk_inactive_pattern_capture_clipboard_assignment:
        move.l  %d2,-(%sp)
        move.l  %a0,-(%sp)
        move.l  %d0,%d2
        clr.b   __gk_inactive_pattern_clipboard_assignment_valid
        cmpi.l  #GK_PATTERN_ASSIGNMENT_COUNT - 1,%d0
        bhi.s   .Lgk_inactive_pattern_capture_clipboard_range
        move.l  %d0,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_pattern_assignment_valid,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_inactive_pattern_capture_clipboard_done
        lea     __gk_pattern_assignments,%a0
        move.b  (%a0,%d2.l),%d0
        move.b  %d0,__gk_inactive_pattern_clipboard_assignment_kit
        moveq   #1,%d0
        move.b  %d0,__gk_inactive_pattern_clipboard_assignment_valid
.Lgk_inactive_pattern_capture_clipboard_done:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_inactive_pattern_capture_clipboard_restore
.Lgk_inactive_pattern_capture_clipboard_range:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_inactive_pattern_capture_clipboard_restore:
        move.l  (%sp)+,%a0
        move.l  (%sp)+,%d2
        rts
        .size   gk_inactive_pattern_capture_clipboard_assignment,.-gk_inactive_pattern_capture_clipboard_assignment
        .type   gk_inactive_pattern_capture_undo_assignment,@function
gk_inactive_pattern_capture_undo_assignment:
        move.l  %d2,-(%sp)
        move.l  %a0,-(%sp)
        move.l  %d0,%d2
        clr.b   __gk_inactive_pattern_undo_assignment_valid
        cmpi.l  #GK_PATTERN_ASSIGNMENT_COUNT - 1,%d0
        bhi.s   .Lgk_inactive_pattern_capture_undo_range
        move.l  %d0,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_pattern_assignment_valid,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_inactive_pattern_capture_undo_done
        lea     __gk_pattern_assignments,%a0
        move.b  (%a0,%d2.l),%d0
        move.b  %d0,__gk_inactive_pattern_undo_assignment_kit
        moveq   #1,%d0
        move.b  %d0,__gk_inactive_pattern_undo_assignment_valid
.Lgk_inactive_pattern_capture_undo_done:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_inactive_pattern_capture_undo_restore
.Lgk_inactive_pattern_capture_undo_range:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_inactive_pattern_capture_undo_restore:
        move.l  (%sp)+,%a0
        move.l  (%sp)+,%d2
        rts
        .size   gk_inactive_pattern_capture_undo_assignment,.-gk_inactive_pattern_capture_undo_assignment
        .type   gk_inactive_pattern_apply_assignment,@function
gk_inactive_pattern_apply_assignment:
        lea     -20(%sp),%sp
        movem.l %d3-%d6/%a0,(%sp)
        move.l  %d0,%d3
        move.l  %d1,%d4
        move.l  %d2,%d5
        cmpi.l  #GK_PATTERN_ASSIGNMENT_COUNT - 1,%d3
        bhi.w   .Lgk_inactive_pattern_apply_assignment_range
        cmpi.l  #1,%d4
        bhi.w   .Lgk_inactive_pattern_apply_assignment_range
        cmpi.l  #GK_KIT_COUNT - 1,%d5
        bhi.w   .Lgk_inactive_pattern_apply_assignment_range
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d3.l),%d2
        move.l  %d3,%d0
        move.l  %d3,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_pattern_assignment_valid,%a0
        moveq   #0,%d6
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_inactive_pattern_apply_assignment_current_ready
        moveq   #1,%d6
.Lgk_inactive_pattern_apply_assignment_current_ready:
        cmp.l   %d4,%d6
        bne.s   .Lgk_inactive_pattern_apply_assignment_mutate
        tst.l   %d4
        beq.s   .Lgk_inactive_pattern_apply_assignment_ok
        cmp.l   %d5,%d2
        beq.s   .Lgk_inactive_pattern_apply_assignment_ok
.Lgk_inactive_pattern_apply_assignment_mutate:
        tst.l   %d4
        beq.s   .Lgk_inactive_pattern_apply_assignment_dirty_kit_ready
        move.l  %d5,%d2
.Lgk_inactive_pattern_apply_assignment_dirty_kit_ready:
        move.w  %sr,%d6
        move.w  #0x2700,%sr
        lea     __gk_pattern_assignments,%a0
        tst.l   %d4
        beq.s   .Lgk_inactive_pattern_apply_assignment_clear
        move.b  %d5,(%a0,%d3.l)
        move.l  %d3,%d0
        move.l  %d3,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_pattern_assignment_valid,%a0
        bset    %d1,(%a0,%d0.l)
        bra.s   .Lgk_inactive_pattern_apply_assignment_restore_sr
.Lgk_inactive_pattern_apply_assignment_clear:
        move.l  %d3,%d0
        move.l  %d3,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_pattern_assignment_valid,%a0
        bclr    %d1,(%a0,%d0.l)
.Lgk_inactive_pattern_apply_assignment_restore_sr:
        move.w  %d6,%sr
        move.l  %d3,%d0
        move.l  %d2,%d1
        .global gk_inactive_pattern_assignment_v3_dirty_call
gk_inactive_pattern_assignment_v3_dirty_call:
        jsr     gk_persistence_v3_mark_assignment_dirty
        tst.l   %d0
        bne.w   gk_inactive_pattern_assignment_dirty_report_fatal
        moveq   #GK_OK,%d0
        bra.s   .Lgk_inactive_pattern_apply_assignment_restore
.Lgk_inactive_pattern_apply_assignment_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_inactive_pattern_apply_assignment_restore
.Lgk_inactive_pattern_apply_assignment_range:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_inactive_pattern_apply_assignment_restore:
        movem.l (%sp),%d3-%d6/%a0
        lea     20(%sp),%sp
        rts
        .size   gk_inactive_pattern_apply_assignment,.-gk_inactive_pattern_apply_assignment
        .type   gk_inactive_pattern_execute,@function
gk_inactive_pattern_execute:
        .incbin "stock/0455.bin", 0, 4
        .incbin "stock/0455.bin", 4, 4
        move.l  %d0,%d6
        clr.l   %d4
        clr.b   __gk_inactive_pattern_reserved
        moveq   #0,%d7
        move.b  __gk_inactive_pattern_target,%d7
        move.l  %d7,%d0
        bsr.w   gk_inactive_pattern_protection_check
        tst.l   %d0
        beq.s   .Lgk_inactive_pattern_target_allowed
        cmpi.l  #GK_ERR_INVALID,%d0
        bne.s   .Lgk_inactive_pattern_target_protected
        moveq   #3,%d1
        move.b  %d1,__gk_inactive_pattern_reserved
        bra.w   .Lgk_inactive_pattern_execute_restore
.Lgk_inactive_pattern_target_protected:
        moveq   #2,%d1
        move.b  %d1,__gk_inactive_pattern_reserved
        bra.w   .Lgk_inactive_pattern_execute_restore
.Lgk_inactive_pattern_target_allowed:
        move.l  %d7,%d0
        bsr.w   gk_inactive_pattern_target_address
        tst.l   %d0
        bne.w   .Lgk_inactive_pattern_execute_restore
        movea.l %a3,%a4
        tst.l   %d6
        bne.s   .Lgk_inactive_pattern_mutate
        movea.l %a4,%a2
        lea     GK_STOCK_PATTERN_PASTE_BUFFER,%a3
        bsr.w   gk_next_pattern_clone_copy_image
        moveq   #GK_STOCK_PATTERN_CLIPBOARD_TAG,%d0
        move.l  %d0,GK_STOCK_PATTERN_PASTE_TAG
        clr.l   GK_STOCK_PATTERN_UNDO_TAG
        clr.b   __gk_inactive_pattern_undo_action
        clr.b   __gk_inactive_pattern_undo_target
        clr.b   __gk_pattern_kit_valid
        clr.b   __gk_pattern_kit_armed
        clr.b   __gk_inactive_pattern_undo_assignment_valid
        clr.b   __gk_inactive_pattern_undo_assignment_kit
        move.l  %d7,%d0
        bsr.w   gk_inactive_pattern_capture_clipboard_assignment
        tst.l   %d0
        bne.w   .Lgk_inactive_pattern_execute_restore
        moveq   #GK_OK,%d0
        bra.w   .Lgk_inactive_pattern_execute_restore
.Lgk_inactive_pattern_mutate:
        cmpi.l  #GK_INACTIVE_PATTERN_ACTION_PASTE,%d6
        bne.s   .Lgk_inactive_pattern_repeat_check
        move.l  GK_STOCK_PATTERN_PASTE_TAG,%d0
        cmpi.l  #GK_STOCK_PATTERN_CLIPBOARD_TAG,%d0
        bne.w   .Lgk_inactive_pattern_invalid
.Lgk_inactive_pattern_repeat_check:
        move.l  GK_STOCK_PATTERN_UNDO_TAG,%d0
        cmpi.l  #GK_INACTIVE_PATTERN_UNDO_TAG,%d0
        bne.s   .Lgk_inactive_pattern_capture_undo
        moveq   #0,%d0
        move.b  __gk_inactive_pattern_undo_action,%d0
        cmp.l   %d6,%d0
        bne.s   .Lgk_inactive_pattern_capture_undo
        moveq   #0,%d0
        move.b  __gk_inactive_pattern_undo_target,%d0
        cmp.l   %d7,%d0
        beq.w   .Lgk_inactive_pattern_apply_undo
.Lgk_inactive_pattern_capture_undo:
        jsr     gk_persistence_snapshot_begin
        tst.l   %d0
        bne.w   .Lgk_inactive_pattern_execute_restore
        moveq   #1,%d4
        moveq   #1,%d0
        move.l  %d7,%d1
        lsr.l   #4,%d1
        lsl.l   %d1,%d0
        jsr     gk_stock_dirty_mark_bank_mask
        tst.l   %d0
        bne.w   gk_inactive_pattern_dirty_report_fatal
        movea.l %a4,%a2
        lea     GK_STOCK_PATTERN_UNDO_BUFFER,%a3
        bsr.w   gk_next_pattern_clone_copy_image
        move.l  #GK_INACTIVE_PATTERN_UNDO_TAG,%d0
        move.l  %d0,GK_STOCK_PATTERN_UNDO_TAG
        move.b  %d6,__gk_inactive_pattern_undo_action
        move.b  %d7,__gk_inactive_pattern_undo_target
        move.l  %d7,%d0
        bsr.w   gk_inactive_pattern_capture_undo_assignment
        tst.l   %d0
        bne.w   gk_inactive_pattern_assignment_state_report_fatal
        movea.l %a4,%a3
        cmpi.l  #GK_INACTIVE_PATTERN_ACTION_CLEAR,%d6
        bne.s   .Lgk_inactive_pattern_apply_paste
        bsr.w   gk_inactive_pattern_clear_image
        move.l  %d7,%d0
        moveq   #0,%d1
        moveq   #0,%d2
        move.b  __gk_inactive_pattern_undo_assignment_kit,%d2
        bsr.w   gk_inactive_pattern_apply_assignment
        tst.l   %d0
        bne.w   gk_inactive_pattern_assignment_state_report_fatal
        bra.w   .Lgk_inactive_pattern_mutation_done
.Lgk_inactive_pattern_apply_paste:
        movea.l %a4,%a0
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a0
        moveq   #0,%d5
        move.b  (%a0),%d5
        lea     GK_STOCK_PATTERN_PASTE_BUFFER,%a2
        movea.l %a4,%a3
        bsr.w   gk_next_pattern_clone_copy_image
        move.b  %d5,(%a0)
        move.l  %d7,%d0
        moveq   #0,%d1
        move.b  __gk_inactive_pattern_clipboard_assignment_valid,%d1
        moveq   #0,%d2
        move.b  __gk_inactive_pattern_clipboard_assignment_kit,%d2
        bsr.w   gk_inactive_pattern_apply_assignment
        tst.l   %d0
        bne.w   gk_inactive_pattern_assignment_state_report_fatal
        bra.s   .Lgk_inactive_pattern_mutation_done
.Lgk_inactive_pattern_apply_undo:
        jsr     gk_persistence_snapshot_begin
        tst.l   %d0
        bne.w   .Lgk_inactive_pattern_execute_restore
        moveq   #1,%d4
        moveq   #1,%d0
        move.l  %d7,%d1
        lsr.l   #4,%d1
        lsl.l   %d1,%d0
        jsr     gk_stock_dirty_mark_bank_mask
        tst.l   %d0
        bne.w   gk_inactive_pattern_dirty_report_fatal
        lea     GK_STOCK_PATTERN_UNDO_BUFFER,%a2
        movea.l %a4,%a3
        bsr.w   gk_next_pattern_clone_copy_image
        move.l  %d7,%d0
        moveq   #0,%d1
        move.b  __gk_inactive_pattern_undo_assignment_valid,%d1
        moveq   #0,%d2
        move.b  __gk_inactive_pattern_undo_assignment_kit,%d2
        bsr.w   gk_inactive_pattern_apply_assignment
        tst.l   %d0
        bne.w   gk_inactive_pattern_assignment_state_report_fatal
        clr.l   GK_STOCK_PATTERN_UNDO_TAG
        moveq   #1,%d0
        move.b  %d0,__gk_inactive_pattern_reserved
.Lgk_inactive_pattern_mutation_done:
        tst.l   %d4
        beq.s   .Lgk_inactive_pattern_mutation_snapshot_done
        jsr     gk_persistence_snapshot_end
        tst.l   %d0
        bne.w   gk_inactive_pattern_snapshot_end_report_fatal
.Lgk_inactive_pattern_mutation_snapshot_done:
        move.l  %d7,%d0
        bsr.w   gk_inactive_pattern_sync_mirror
        moveq   #GK_OK,%d0
        bra.s   .Lgk_inactive_pattern_execute_restore
.Lgk_inactive_pattern_invalid:
        moveq   #GK_ERR_INVALID,%d0
.Lgk_inactive_pattern_execute_restore:
        .incbin "stock/0456.bin", 0, 4
        .incbin "stock/0456.bin", 4, 4
        rts
        .size   gk_inactive_pattern_execute,.-gk_inactive_pattern_execute
        .align  4
        .global gk_inactive_pattern_action_dispatch
        .type   gk_inactive_pattern_action_dispatch,@function
gk_inactive_pattern_action_dispatch:
        .incbin "stock/0457.bin", 0, 4
        .incbin "stock/0457.bin", 4, 4
        move.l  %d0,%d4
        moveq   #1,%d0
        cmp.l   32(%sp),%d0
        bne.w   .Lgk_inactive_pattern_action_stock
        moveq   #0,%d2
        move.b  __gk_inactive_pattern_mode,%d2
        cmpi.l  #GK_INACTIVE_PATTERN_MODE_PTN_TARGET,%d2
        beq.s   .Lgk_inactive_pattern_action_owner_check
        cmpi.l  #GK_INACTIVE_PATTERN_MODE_BANK_TARGET,%d2
        bne.w   .Lgk_inactive_pattern_action_stock
.Lgk_inactive_pattern_action_owner_check:
        .incbin "stock/0458.bin", 0, 4
        .incbin "stock/0458.bin", 4, 6
        .incbin "stock/0458.bin", 10, 2
        .incbin "stock/0458.bin", 12, 2
        .incbin "stock/0458.bin", 14, 2
        .byte 0x01,0x50
        moveq   #GK_STOCK_PATTERN_PRESS_INPUT,%d3
        cmpi.l  #GK_INACTIVE_PATTERN_MODE_PTN_TARGET,%d2
        beq.s   .Lgk_inactive_pattern_action_root_ready
        moveq   #GK_STOCK_BANK_PRESS_INPUT,%d3
.Lgk_inactive_pattern_action_root_ready:
        move.l  %d3,-(%sp)
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        beq.w   .Lgk_inactive_pattern_action_stock
        moveq   #0,%d3
        move.b  __gk_inactive_pattern_target_trig,%d3
        move.l  %d3,-(%sp)
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        beq.w   .Lgk_inactive_pattern_action_stock
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_inactive_pattern_action_stock
        tst.b   __gk_ui_mode
        bne.w   .Lgk_inactive_pattern_action_stock
        tst.l   GK_STOCK_CALLBACK_MENU_OBJECT
        bne.w   .Lgk_inactive_pattern_action_stock
        tst.l   GK_STOCK_TEXT_EDITOR_OBJECT
        bne.w   .Lgk_inactive_pattern_action_stock
        move.l  %d4,%d0
        bsr.w   gk_inactive_pattern_execute
        move.l  %d0,%d3
        moveq   #0,%d0
        move.b  __gk_inactive_pattern_reserved,%d0
        cmpi.l  #3,%d0
        beq.w   .Lgk_inactive_pattern_action_delegate_stock
        cmpi.l  #2,%d0
        beq.w   .Lgk_inactive_pattern_action_protected_text
        tst.l   %d3
        bne.s   .Lgk_inactive_pattern_action_refresh_done
        cmpi.l  #GK_INACTIVE_PATTERN_MODE_PTN_TARGET,%d2
        bne.s   .Lgk_inactive_pattern_action_refresh_done
        jsr     GK_STOCK_PATTERN_OVERLAY_REFRESH
.Lgk_inactive_pattern_action_refresh_done:
        moveq   #0,%d0
        move.b  __gk_inactive_pattern_reserved,%d0
        cmpi.l  #1,%d0
        beq.s   .Lgk_inactive_pattern_action_undo_text
        lea     GK_STOCK_PATTERN_COPY_TEXT,%a0
        tst.l   %d4
        beq.s   .Lgk_inactive_pattern_action_notify
        lea     GK_STOCK_PATTERN_CLEAR_TEXT,%a0
        cmpi.l  #GK_INACTIVE_PATTERN_ACTION_CLEAR,%d4
        beq.s   .Lgk_inactive_pattern_action_notify
        lea     GK_STOCK_PATTERN_PASTE_TEXT,%a0
        bra.s   .Lgk_inactive_pattern_action_notify
.Lgk_inactive_pattern_action_undo_text:
        lea     GK_STOCK_PATTERN_UNDO_TEXT,%a0
.Lgk_inactive_pattern_action_notify:
        cmpi.l  #GK_INACTIVE_PATTERN_MODE_BANK_TARGET,%d2
        bne.s   .Lgk_inactive_pattern_action_notify_now_v4
        jsr     gk_inactive_pattern_bank_panel_hide
.Lgk_inactive_pattern_action_notify_now_v4:
        move.l  %d3,%d0
        jsr     gk_part_edit_notify_result
        cmpi.l  #GK_INACTIVE_PATTERN_MODE_BANK_TARGET,%d2
        bne.s   .Lgk_inactive_pattern_action_notify_refresh_done
        jsr     GK_STOCK_BANK_OVERLAY_REFRESH
.Lgk_inactive_pattern_action_notify_refresh_done:
        bra.s   .Lgk_inactive_pattern_action_prompt_complete
.Lgk_inactive_pattern_action_protected_text:
        cmpi.l  #GK_INACTIVE_PATTERN_MODE_BANK_TARGET,%d2
        bne.s   .Lgk_inactive_pattern_action_protected_now_v4
        jsr     gk_inactive_pattern_bank_panel_hide
.Lgk_inactive_pattern_action_protected_now_v4:
        pea     (0x44).w
        pea     .Lgk_inactive_pattern_protected_message
        jsr     GK_STOCK_NOTIFICATION_SHOW
        addq.l  #8,%sp
        cmpi.l  #GK_INACTIVE_PATTERN_MODE_BANK_TARGET,%d2
        bne.s   .Lgk_inactive_pattern_action_protected_refresh_done
        jsr     GK_STOCK_BANK_OVERLAY_REFRESH
.Lgk_inactive_pattern_action_protected_refresh_done:
.Lgk_inactive_pattern_action_prompt_complete:
        cmpi.l  #GK_INACTIVE_PATTERN_MODE_PTN_TARGET,%d2
        bne.s   .Lgk_inactive_pattern_action_bank_complete
        moveq   #-1,%d0
        move.l  %d0,GK_STOCK_PATTERN_SELECTION_PERFORMED
        bra.s   .Lgk_inactive_pattern_action_handled
.Lgk_inactive_pattern_action_bank_complete:
        moveq   #1,%d0
        move.b  %d0,__gk_inactive_pattern_action_latch
.Lgk_inactive_pattern_action_handled:
        moveq   #0,%d0
        bra.s   .Lgk_inactive_pattern_action_restore
.Lgk_inactive_pattern_action_delegate_stock:
        cmpi.l  #GK_INACTIVE_PATTERN_MODE_PTN_TARGET,%d2
        bne.s   .Lgk_inactive_pattern_action_delegate_bank
        moveq   #-1,%d0
        move.l  %d0,GK_STOCK_PATTERN_SELECTION_PERFORMED
        bra.s   .Lgk_inactive_pattern_action_stock
.Lgk_inactive_pattern_action_delegate_bank:
        moveq   #1,%d0
        move.b  %d0,__gk_inactive_pattern_action_latch
.Lgk_inactive_pattern_action_stock:
        moveq   #1,%d0
.Lgk_inactive_pattern_action_restore:
        movem.l (%sp),%d2-%d4/%a2-%a3
        lea     20(%sp),%sp
        rts
        .size   gk_inactive_pattern_action_dispatch,.-gk_inactive_pattern_action_dispatch
        .align  4
.Lgk_inactive_pattern_protected_message:
        .asciz  "PATTERN PROTECTED"
        .align  2
        .global gk_inactive_pattern_scheduler_report_fatal
        .type gk_inactive_pattern_scheduler_report_fatal,@function
gk_inactive_pattern_scheduler_report_fatal:
        illegal
        .size gk_inactive_pattern_scheduler_report_fatal,.-gk_inactive_pattern_scheduler_report_fatal
        .global gk_inactive_pattern_dirty_report_fatal
        .type gk_inactive_pattern_dirty_report_fatal,@function
gk_inactive_pattern_dirty_report_fatal:
        illegal
        .size gk_inactive_pattern_dirty_report_fatal,.-gk_inactive_pattern_dirty_report_fatal
        .global gk_inactive_pattern_assignment_state_report_fatal
        .type gk_inactive_pattern_assignment_state_report_fatal,@function
gk_inactive_pattern_assignment_state_report_fatal:
        illegal
        .size gk_inactive_pattern_assignment_state_report_fatal,.-gk_inactive_pattern_assignment_state_report_fatal
        .global gk_inactive_pattern_assignment_dirty_report_fatal
        .type gk_inactive_pattern_assignment_dirty_report_fatal,@function
gk_inactive_pattern_assignment_dirty_report_fatal:
        illegal
        .size gk_inactive_pattern_assignment_dirty_report_fatal,.-gk_inactive_pattern_assignment_dirty_report_fatal
        .global gk_inactive_pattern_snapshot_end_report_fatal
        .type gk_inactive_pattern_snapshot_end_report_fatal,@function
gk_inactive_pattern_snapshot_end_report_fatal:
        illegal
        .size gk_inactive_pattern_snapshot_end_report_fatal,.-gk_inactive_pattern_snapshot_end_report_fatal
        .global gk_inactive_pattern_fatal
        .type   gk_inactive_pattern_fatal,@function
gk_inactive_pattern_fatal:
        illegal
        bra.s   gk_inactive_pattern_fatal
        .size   gk_inactive_pattern_fatal,.-gk_inactive_pattern_fatal
