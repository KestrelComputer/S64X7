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
