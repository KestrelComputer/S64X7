`timescale 1ns / 1ps

`define OPC_NOP     4'b0000
`define OPC_LIT8    4'b0001
`define OPC_LIT16   4'b0010
`define OPC_LIT32   4'b0011
`define OPC_STORES  4'b0100

`define N_SBM       4'b0000
`define N_SHM       4'b0001
`define N_SWM       4'b0010
`define N_SDM       4'b0011

module S64X7(
    input         clk_i,
    input         reset_i,
    input         ack_i,
    input [63:0]  dat_i,

    output  [63:3]  adr_o,
    output          cyc_o,
    output          stb_o,
    output  [7:0]   sel_o,
    output          we_o,
    output          vpa_o,
    output  [3:0]   opc_o,
    output  [63:0]  dat_o
);
  reg [63:3]  adr_o;
  reg         cyc_o, we_o, vpa_o;
  reg [7:0]   sel_o;
  reg [63:0]  dat_o;

  reg [63:0]  ir, dr, ndr;
  reg [63:3]  p, np;
  reg [3:0]   t, nt;
  reg [63:0]  x, y, z, nx, ny, nz;

  assign stb_o = cyc_o;

  wire is_instr_fetch = (t == 0) | (t == ir[63:60]);
  wire [3:0] opcode =
    (t == 1) ? ir[59:56] :
    (t == 2) ? ir[55:52] :
    (t == 3) ? ir[51:48] :
    (t == 4) ? ir[47:44] :
    (t == 5) ? ir[43:40] :
    (t == 6) ? ir[39:36] :
    (t == 7) ? ir[35:32] :
    `OPC_NOP;

  assign opc_o = opcode;

  always @(*) begin
    casez({reset_i, is_instr_fetch})
    2'b1?: begin
      adr_o <= p;
      cyc_o <= 1;
      we_o <= 0;
      vpa_o <= 1;
      sel_o <= 8'hFF;
      dat_o <= 64'd0;

      np <= 61'h1C00_0000_0000_0000; // 64'hE000_0000_0000_0000
      nt <= 0;

      nx <= x;
      ny <= y;
      nz <= z;
      ndr <= dr;
    end
    2'b01: begin
      adr_o <= p;
      cyc_o <= 1;
      we_o <= 0;
      vpa_o <= 1;
      sel_o <= 8'hFF;
      dat_o <= 64'd0;

      np <= p + 1;
      nt <= 1;

      nx <= x;
      ny <= y;
      nz <= z;
      ndr <= dr;
    end
    2'b00: begin
      case(opcode)
      `OPC_NOP: begin
        adr_o <= 0;
        cyc_o <= 0;
        we_o <= 0;
        vpa_o <= 0;
        sel_o <= 0;
        dat_o <= 64'd0;

        np <= p;
        nt <= t+1;

        nx <= x;
        ny <= y;
        nz <= z;
        ndr <= dr;
      end

      `OPC_LIT8: begin
        adr_o <= 0;
        cyc_o <= 0;
        we_o <= 0;
        vpa_o <= 0;
        sel_o <= 0;
        dat_o <= 64'd0;

        np <= p;
        nt <= t+1;

        nx <= y;
        ny <= z;
        nz <= {{52{dr[7]}}, dr[7:0]};
        ndr <= dr >> 8;
      end

      `OPC_LIT16: begin
        adr_o <= 0;
        cyc_o <= 0;
        we_o <= 0;
        vpa_o <= 0;
        sel_o <= 0;
        dat_o <= 64'd0;

        np <= p;
        nt <= t+1;

        nx <= y;
        ny <= z;
        nz <= {{48{dr[15]}}, dr[15:0]};
        ndr <= dr >> 16;
      end

      `OPC_LIT32: begin
        adr_o <= 0;
        cyc_o <= 0;
        we_o <= 0;
        vpa_o <= 0;
        sel_o <= 0;
        dat_o <= 64'd0;

        np <= p;
        nt <= t+1;

        nx <= y;
        ny <= z;
        nz <= {{32{dr[31]}}, dr[31:0]};
        ndr <= dr >> 32;
      end

      `OPC_STORES: begin
        case(dr[3:0])
        `N_SBM: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 1;
          vpa_o <= 0;
          sel_o <= 1 << z[2:0];
          dat_o <= {8{y[7:0]}};

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= x;
          nz <= x;
          ndr <= dr >> 4;
        end
        `N_SHM: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 1;
          vpa_o <= 0;
          sel_o <= 3 << {z[2:1], 1'b0};
          dat_o <= {4{y[15:0]}};

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= x;
          nz <= x;
          ndr <= dr >> 4;
        end
        `N_SWM: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 1;
          vpa_o <= 0;
          sel_o <= 15 << {z[2], 2'b0};
          dat_o <= {2{y[31:0]}};

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= x;
          nz <= x;
          ndr <= dr >> 4;
        end
        `N_SDM: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 1;
          vpa_o <= 0;
          sel_o <= 8'b11111111;
          dat_o <= y;

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= x;
          nz <= x;
          ndr <= dr >> 4;
        end
        endcase
      end
      default: begin
        adr_o <= 0;
        cyc_o <= 0;
        we_o <= 0;
        vpa_o <= 0;
        sel_o <= 0;

        np <= p;
        nt <= t+1;

        nx <= x;
        ny <= y;
        nz <= z;
        ndr <= dr;
      end
      endcase
    end
    endcase
  end

// always @(clk_i) begin $display("CLK=%d T=%d O=%4b P=%016X NP=%016X ADR=%016X IIF=%d", clk_i, t, opcode, p, np, adr_o, is_instr_fetch); end

  always @(posedge clk_i) begin
    t <= nt;
    p <= np;
    if(is_instr_fetch) begin
      ir <= dat_i;
      dr <= dat_i;
    end
    else begin
      dr <= ndr;
    end
    x <= nx;
    y <= ny;
    z <= nz;
  end
endmodule

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

  task assert_dat_i;
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

  initial begin
    clk_o <= 0;
    reset_o <= 0;
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
    // SBM

    start(24'h000100);
    reset_o <= 0;
    dat_o <= 64'h4134001111111141;
    ack_o <= 1;
    tick();   // currently executing LIT8
    assert_cyc_o(0);
    assert_vpa_o(0);
    assert_opcode(1);
    start(24'h000101);
    tick();   // now executing LIT32
    assert_cyc_o(0);
    assert_vpa_o(0);
    assert_opcode(3);
    start(24'h000102);
    tick();   // now executing SBM
    assert_cyc_o(1);
    assert_vpa_o(0);
    assert_opcode(4);
    assert_adr_o(64'h0000_0000_1111_1111);
    assert_sel_o(8'b00000010);
    assert_dat_i(64'h4141_4141_4141_4141);
    assert_we_o(1);
    start(24'h000103);
    tick();  // now fetching next instruction packet
    assert_cyc_o(1);
    assert_vpa_o(1);
    assert_adr_o(64'hE000_0000_0000_0008);
    assert_sel_o(8'b11111111);
    assert_we_o(0);

    // LIT8	$41
    // LIT32    $22222220
    // SHM

    start(24'h000200);
    dat_o <= 64'h4134012222222041;
    ack_o <= 1;
    tick();   // currently executing LIT8
    assert_cyc_o(0);
    assert_vpa_o(0);
    assert_opcode(1);
    start(24'h000201);
    tick();   // now executing LIT32
    assert_cyc_o(0);
    assert_vpa_o(0);
    assert_opcode(3);
    start(24'h000202);
    tick();   // now executing SHM
    assert_cyc_o(1);
    assert_vpa_o(0);
    assert_opcode(4);
    assert_adr_o(64'h0000_0000_2222_2220);
    assert_sel_o(8'b00000011);
    assert_dat_i(64'h0041_0041_0041_0041);
    assert_we_o(1);
    start(24'h000203);
    tick();  // now fetching next instruction packet
    assert_cyc_o(1);
    assert_vpa_o(1);
    assert_adr_o(64'hE000_0000_0000_0010);
    assert_sel_o(8'b11111111);
    assert_we_o(0);

    // LIT8	$41
    // LIT32    $33333334
    // SWM

    start(24'h000300);
    dat_o <= 64'h4134023333333441;
    ack_o <= 1;
    tick();   // currently executing LIT8
    assert_cyc_o(0);
    assert_vpa_o(0);
    assert_opcode(1);
    start(24'h000301);
    tick();   // now executing LIT32
    assert_cyc_o(0);
    assert_vpa_o(0);
    assert_opcode(3);
    start(24'h000302);
    tick();   // now executing SWM
    assert_cyc_o(1);
    assert_vpa_o(0);
    assert_opcode(4);
    assert_adr_o(64'h0000_0000_3333_3334);
    assert_sel_o(8'b11110000);
    assert_dat_i(64'h0000_0041_0000_0041);
    assert_we_o(1);
    start(24'h000303);
    tick();  // now fetching next instruction packet
    assert_cyc_o(1);
    assert_vpa_o(1);
    assert_adr_o(64'hE000_0000_0000_0018);
    assert_sel_o(8'b11111111);
    assert_we_o(0);

    // LIT8	$41
    // LIT32    $44444448
    // SDM

    start(24'h000400);
    dat_o <= 64'h4134034444444841;
    ack_o <= 1;
    tick();   // currently executing LIT8
    assert_cyc_o(0);
    assert_vpa_o(0);
    assert_opcode(1);
    start(24'h000401);
    tick();   // now executing LIT32
    assert_cyc_o(0);
    assert_vpa_o(0);
    assert_opcode(3);
    start(24'h000402);
    tick();   // now executing SDM
    assert_cyc_o(1);
    assert_vpa_o(0);
    assert_opcode(4);
    assert_adr_o(64'h0000_0000_4444_4448);
    assert_sel_o(8'b11111111);
    assert_dat_i(64'h0000_0000_0000_0041);
    assert_we_o(1);
    start(24'h000403);
    tick();  // now fetching next instruction packet
    assert_cyc_o(1);
    assert_vpa_o(1);
    assert_adr_o(64'hE000_0000_0000_0020);
    assert_sel_o(8'b11111111);
    assert_we_o(0);

    $display("@I Done.");
    $stop;
  end
endmodule

