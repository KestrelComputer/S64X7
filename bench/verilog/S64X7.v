`timescale 1ns / 1ps

`include "opcodes.vh"

module test_S64X7();
  reg [23:0]  story_o;
  reg         clk_o;
  reg         reset_o;
  reg         ack_o;
  reg [63:0]  dat_o;

  wire  [63:3]  adr_i;
  wire          cyc_i;
  wire          stb_i;
  wire  [7:0]   sel_i;
  wire          we_i;
  wire          vpa_i;
  wire  [3:0]   opc_i;
  wire  [63:0]  dat_i;

  S64X7 s(
    .clk_i(clk_o),
    .reset_i(reset_o),
    .ack_i(ack_o),
    .dat_i(dat_o),
    .opc_o(opc_i),

    .adr_o(adr_i),
    .cyc_o(cyc_i),
    .stb_o(stb_i),
    .sel_o(sel_i),
    .we_o(we_i),
    .vpa_o(vpa_i),
    .dat_o(dat_i)
  );

  // This task makes it easier to navigate the file with an editor, as it's
  // easier to search forwards or backwards for "start(".

  task start;
  input [23:0]  story;
  begin
    story_o <= story;
  end
  endtask

  task tick;
  begin
    @(posedge clk_o);
    @(negedge clk_o);
  end
  endtask

  task assert_adr_o;
  input [63:0] expected;
  begin
    if(adr_i !== expected[63:3]) begin
      $display("@E %06X ADR_O Expected $%016X; got $%016X", story_o, {expected[63:3], 3'b000}, {adr_i, 3'b000});
      $stop;
    end
  end
  endtask

  task assert_dat_o;
  input [63:0] expected;
  begin
    if(dat_i !== expected[63:0]) begin
      $display("@E %06X DAT_O Expected $%016X; got $%016X", story_o, expected, dat_i);
      $stop;
    end
  end
  endtask

  task assert_cyc_o;
  input expected;
  begin
    if(cyc_i !== expected) begin
      $display("@E %06X CYC_O Expected %d; got %d", story_o, expected, cyc_i);
      $stop;
    end
    if(stb_i !== expected) begin
      $display("@E %06X STB_O Expected %d; got %d", story_o, expected, stb_i);
      $stop;
    end
  end
  endtask

  task assert_sel_o;
  input [7:0] expected;
  begin
    if(sel_i !== expected) begin
      $display("@E %06X SEL_O Expected %08b; got %08b", story_o, expected, sel_i);
      $stop;
    end
  end
  endtask

  task assert_opcode;
  input [3:0] expected;
  begin
    if(opc_i !== expected) begin
      $display("@E %06X OPC_O Expected %04b; got %04b", story_o, expected, opc_i);
      $stop;
    end
  end
  endtask

  task assert_we_o;
  input expected;
  begin
    if(we_i !== expected) begin
      $display("@E %06X WE_O Expected %d; got %d", story_o, expected, we_i);
      $stop;
    end
  end
  endtask

  task assert_vpa_o;
  input expected;
  begin
    if(vpa_i !== expected) begin
      $display("@E %06X VPA_O Expected %d; got %d", story_o, expected, vpa_i);
      $stop;
    end
  end
  endtask

  always begin
    #20 clk_o <= ~clk_o;
  end

  task test_lit;
  input [23:0] story;
  input [31:0] addr;
  input [7:0] sel;
  input [3:0] store_type;
  input [63:0] expected;
  begin
    start(story);
    dat_o <= {20'h41340, store_type, addr, 8'h41};
    ack_o <= 1;
    tick();
    assert_opcode(1);
    assert_cyc_o(0);
    assert_vpa_o(0);

    start(story+1);
    tick();
    assert_opcode(3);
    assert_cyc_o(0);
    assert_vpa_o(0);

    start(story+2);
    tick();
    assert_opcode(4);
    assert_cyc_o(1);
    assert_vpa_o(0);
    assert_adr_o({32'h00000000, addr});
    assert_sel_o(sel);
    assert_dat_o(expected);
    assert_we_o(1);
  end
  endtask

  task test_load;
  input [23:0] story;
  input [31:0] load_addr;
  input [7:0] sel;
  input [3:0] load_type;
  input [63:0] fetched_data;
  input [63:0] expected;
  begin
    start(story);
    dat_o <= {28'h3350000, load_type, load_addr};
    tick();             // Now executing LIT32
    assert_opcode(3);
    assert_cyc_o(0);
    assert_vpa_o(0);

    start(story+1);  // Now executing LxMU
    tick();
    assert_opcode(5);
    assert_cyc_o(1);
    assert_vpa_o(0);
    assert_we_o(0);
    assert_adr_o({32'd0, load_addr});
    assert_sel_o(sel);
    dat_o <= fetched_data;

    start(story+2);  // Now fetching next instruction packet
    tick();
    assert_cyc_o(1);
    assert_vpa_o(1);
    assert_sel_o(8'hFF);
    assert_we_o(0);
    dat_o <= 64'h33400003_11111110;

    start(story+3);  // Now executing LIT32
    tick();
    assert_opcode(3);
    assert_cyc_o(0);

    start(story+4);  // Now executing SDM
    tick();
    assert_opcode(4);
    assert_cyc_o(1);
    assert_vpa_o(0);
    assert_adr_o(64'h0000_0000_1111_1110);
    assert_sel_o(8'b11111111);
    assert_we_o(1);
    assert_dat_o(expected);
  end
  endtask

  task test_intop;
  input [23:0] story;
  input [3:0] fn;
  input [63:0] expected;
  begin
    start(story);
    dat_o <= {44'h61161400300, fn, 16'h0211};
    tick();             // Now executing LIT8
    assert_opcode(`OPC_LIT8);
    assert_cyc_o(0);
    assert_vpa_o(0);

    start(story+1);  // Now executing LIT8
    tick();
    assert_opcode(`OPC_LIT8);
    assert_cyc_o(0);
    assert_vpa_o(0);

    start(story+2);  // Now executing function under test
    tick();
    assert_opcode(`OPC_INTOPS);
    assert_cyc_o(0);
    assert_vpa_o(0);

    start(story+3);  // Now executing LIT8
    tick();
    assert_opcode(`OPC_LIT8);
    assert_cyc_o(0);
    assert_vpa_o(0);

    start(story+4);  // Now executing SDM
    tick();
    assert_opcode(`OPC_STORES);
    assert_cyc_o(1);
    assert_vpa_o(0);
    assert_adr_o(64'd0);
    assert_sel_o(8'b11111111);
    assert_we_o(1);
    assert_dat_o(expected);
  end
  endtask

  task test_instr_fetch;
  input [23:0] story;
  input [63:0] expected;
  begin
    start(story+3);
    tick();  // now fetching next instruction packet
    assert_cyc_o(1);
    assert_vpa_o(1);
    assert_adr_o(expected);
    assert_sel_o(8'b11111111);
    assert_we_o(0);
  end
  endtask

  initial begin
    clk_o <= 0;
    reset_o <= 0;
    ack_o <= 0;
    tick();

    // Reset

    start(24'h000010);
    reset_o <= 1;
    tick();
    assert_adr_o(64'hE000_0000_0000_0000);
    assert_cyc_o(1);
    assert_sel_o(8'b11111111);
    assert_we_o(0);
    assert_vpa_o(1);

    // LIT8   $41
    // LIT32  $11111111
    // SBM/SHM/SWM/SDM

    //       STORY       ADDR          SEL          STORE  EXPECTED DAT_O
    //
    reset_o <= 0;
    test_lit(24'h000100, 32'h11111111, 8'b00000010, `N_SBM, 64'h41414141_41414141);
    test_instr_fetch(24'h000100, 64'hE000_0000_0000_0008);

    test_lit(24'h000200, 32'h22222220, 8'b00000011, `N_SHM, 64'h00410041_00410041);
    test_instr_fetch(24'h000200, 64'hE000_0000_0000_0010);

    test_lit(24'h000300, 32'h33333334, 8'b11110000, `N_SWM, 64'h00000041_00000041);
    test_instr_fetch(24'h000300, 64'hE000_0000_0000_0018);

    test_lit(24'h000400, 32'h44444448, 8'b11111111, `N_SDM, 64'h00000000_00000041);
    test_instr_fetch(24'h000400, 64'hE000_0000_0000_0020);

    // LIT32  $55555555
    // LBMU/LHMU/LWMU/LDMU
    // LIT32  $11111110
    // SDM

    //        STORY       LOAD ADDR     SEL          LOAD     FETCHED DATA           EXPECTED STORE DATA
    //
    test_load(24'h000500, 32'h55555555, 8'b00100000, `N_LBMU, 64'h00008100_00000000, 64'h00000000_00000081);
    test_instr_fetch(24'h000500, 64'hE000_0000_0000_0030);

    test_load(24'h000600, 32'h55555552, 8'b00001100, `N_LHMU, 64'h00000000_81000000, 64'h00000000_00008100);
    test_instr_fetch(24'h000600, 64'hE000_0000_0000_0040);

    test_load(24'h000700, 32'h55555554, 8'b11110000, `N_LWMU, 64'h81000000_00000000, 64'h00000000_81000000);
    test_instr_fetch(24'h000700, 64'hE000_0000_0000_0050);

    test_load(24'h000800, 32'h55555550, 8'b11111111, `N_LDMU, 64'h81000000_00000000, 64'h81000000_00000000);
    test_instr_fetch(24'h000800, 64'hE000_0000_0000_0060);

    test_load(24'h000510, 32'h55555555, 8'b00100000, `N_LBMS, 64'h00008100_00000000, 64'hFFFFFFFF_FFFFFF81);
    test_instr_fetch(24'h000510, 64'hE000_0000_0000_0070);

    test_load(24'h000610, 32'h55555552, 8'b00001100, `N_LHMS, 64'h00000000_81000000, 64'hFFFFFFFF_FFFF8100);
    test_instr_fetch(24'h000610, 64'hE000_0000_0000_0080);

    test_load(24'h000710, 32'h55555554, 8'b11110000, `N_LWMS, 64'h81000000_00000000, 64'hFFFFFFFF_81000000);
    test_instr_fetch(24'h000710, 64'hE000_0000_0000_0090);

    test_load(24'h000810, 32'h55555550, 8'b11111111, `N_LDMS, 64'h81000000_00000000, 64'h81000000_00000000);
    test_instr_fetch(24'h000810, 64'hE000_0000_0000_00A0);

    // LIT8   $11
    // LIT8   $02
    // ADD/SUB/SLL/SLT/SLTU/XOR/SRA/SRL/OR/AND
    // LIT8   $00
    // SDM
    //
    // 61161400300f0211
    //
    //         STORY       FN      EXPECTED RESULT
    //
    test_intop(24'h000900, `N_ADD, 64'h0000_0000_0000_0013);
    test_instr_fetch(24'h000900, 64'hE000_0000_0000_00A8);

    test_intop(24'h000A00, `N_SUB, 64'h0000_0000_0000_000F);
    test_instr_fetch(24'h000A00, 64'hE000_0000_0000_00B0);

    test_intop(24'h000B00, `N_SLL, 64'h0000_0000_0000_0044);
    test_instr_fetch(24'h000B00, 64'hE000_0000_0000_00B8);

    test_intop(24'h000C00, `N_SLT, 64'h0000_0000_0000_0000);
    test_instr_fetch(24'h000C00, 64'hE000_0000_0000_00C0);

    test_intop(24'h000D00, `N_SLTU, 64'h0000_0000_0000_0000);
    test_instr_fetch(24'h000D00, 64'hE000_0000_0000_00C8);

    test_intop(24'h000E00, `N_XOR, 64'h0000_0000_0000_0013);
    test_instr_fetch(24'h000E00, 64'hE000_0000_0000_00D0);

    test_intop(24'h000F00, `N_SRL, 64'h0000_0000_0000_0004);
    test_instr_fetch(24'h000F00, 64'hE000_0000_0000_00D8);

    test_intop(24'h001000, `N_SRA, 64'h0000_0000_0000_0004);
    test_instr_fetch(24'h001000, 64'hE000_0000_0000_00E0);

    test_intop(24'h001100, `N_OR, 64'h0000_0000_0000_0013);
    test_instr_fetch(24'h001100, 64'hE000_0000_0000_00E8);

    test_intop(24'h001200, `N_AND, 64'h0000_0000_0000_0000);
    test_instr_fetch(24'h001200, 64'hE000_0000_0000_00F0);

    $display("@I Done.");
    $stop;
  end
endmodule

