`timescale 1ns / 1ps

`define OPC_NOP     4'b0000
`define OPC_LIT8    4'b0001
`define OPC_LIT16   4'b0010
`define OPC_LIT32   4'b0011
`define OPC_STORES  4'b0100
`define OPC_LOADS   4'b0101

`define N_SBM       4'b0000
`define N_SHM       4'b0001
`define N_SWM       4'b0010
`define N_SDM       4'b0011

`define N_LBMU      4'b0000
`define N_LHMU      4'b0001
`define N_LWMU      4'b0010
`define N_LDMU      4'b0011
`define N_LBMS      4'b0100
`define N_LHMS      4'b0101
`define N_LWMS      4'b0110
`define N_LDMS      4'b0111


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

  wire [7:0] byte_in =
    (z[2:0] == 3'b000) ? dat_i[7:0] :
    (z[2:0] == 3'b001) ? dat_i[15:8] :
    (z[2:0] == 3'b010) ? dat_i[23:16] :
    (z[2:0] == 3'b011) ? dat_i[31:24] :
    (z[2:0] == 3'b100) ? dat_i[39:32] :
    (z[2:0] == 3'b101) ? dat_i[47:40] :
    (z[2:0] == 3'b110) ? dat_i[55:48] :
    dat_i[63:56];

  wire [15:0] hword_in =
    (z[2:1] == 2'b00) ? dat_i[15:0] :
    (z[2:1] == 2'b01) ? dat_i[31:16] :
    (z[2:1] == 2'b10) ? dat_i[47:32] :
    dat_i[63:48];

  wire [31:0] word_in =
    (z[2] == 0) ? dat_i[31:0] :
    dat_i[63:32];

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

      `OPC_LOADS: begin
        case(dr[3:0])
        `N_LBMU: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 1 << z[2:0];

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= y;
          nz <= {56'd0, byte_in};
          ndr <= dr >> 4;
        end
        `N_LHMU: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 3 << {z[2:1], 1'b0};

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= y;
          nz <= {48'd0, hword_in};
          ndr <= dr >> 4;
        end
        `N_LWMU: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 15 << {z[2], 2'b0};

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= y;
          nz <= {32'd0, word_in};
          ndr <= dr >> 4;
        end
        `N_LDMU: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 8'b11111111;

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= y;
          nz <= dat_i;
          ndr <= dr >> 4;
        end
        `N_LBMS: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 1 << z[2:0];

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= y;
          nz <= {{56{byte_in[7]}}, byte_in};
          ndr <= dr >> 4;
        end
        `N_LHMS: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 3 << {z[2:1], 1'b0};

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= y;
          nz <= {{48{hword_in[15]}}, hword_in};
          ndr <= dr >> 4;
        end
        `N_LWMS: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 15 << {z[2], 2'b0};

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= y;
          nz <= {{32{word_in[31]}}, word_in};
          ndr <= dr >> 4;
        end
        `N_LDMS: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 8'b11111111;

          np <= p;
          nt <= t+1;

          nx <= x;
          ny <= y;
          nz <= dat_i;
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

always @(posedge clk_i) begin #5 $display("CLK=%d T=%d O=%4b DI=%016X DO=%016X ADR=%016X IIF=%d IR=%016X DR=%016X", clk_i, t, opcode, dat_i, dat_o, adr_o, is_instr_fetch, ir, dr); end

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

    $display("@I Done.");
    $stop;
  end
endmodule

