`timescale 1ns / 1ps

`include "opcodes.vh"


module stack8(
    input           clk_i,
    input           push_en_i,
    input           pop_en_i,
    input           pop2_en_i,
    input   [63:0]  dat_i,

    output  [63:0]  dat0_o,
    output  [63:0]  dat1_o
);
  reg [63:0] a, b, c, d, e, f, g, h;
  reg [63:0] na, nb, nc, nd, ne, nf, ng, nh;

  assign dat0_o = a;
  assign dat1_o = b;

  always @(*) begin
    if(push_en_i) begin
      na <= dat_i;
      nb <= a;
      nc <= b;
      nd <= c;
      ne <= d;
      nf <= e;
      ng <= f;
      nh <= g;
    end
    else if(pop_en_i) begin
      na <= b;
      nb <= c;
      nc <= d;
      nd <= e;
      ne <= f;
      nf <= g;
      ng <= h;
      nh <= h;
    end
    else if(pop2_en_i) begin
      na <= c;
      nb <= d;
      nc <= e;
      nd <= f;
      ne <= g;
      nf <= h;
      ng <= h;
      nh <= h;
    end
    else begin
      na <= a;
      nb <= b;
      nc <= c;
      nd <= d;
      ne <= e;
      nf <= f;
      ng <= g;
      nh <= h;
    end
  end

  always @(posedge clk_i) begin
    a <= na;
    b <= nb;
    c <= nc;
    d <= nd;
    e <= ne;
    f <= nf;
    g <= ng;
    h <= nh;
  end
endmodule


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
  reg [63:3]  p, np;  // Pointer to next instruction packet
  reg [63:3]  ia, nia;  // Pointer to current instruction packet
  reg [3:0]   t, nt;
  reg [63:0]  x, y, z, nx, ny, nz;

  reg dpush, dpop, dpop2;
  wire [63:0] ds0, ds1;

  stack8 ds(
    .clk_i(clk_i),
    .push_en_i(dpush),
    .pop_en_i(dpop),
    .pop2_en_i(dpop2),
    .dat_i(x),
    .dat0_o(ds0),
    .dat1_o(ds1)
  );

  reg           rpush, rpop;
  reg   [63:0]  rz, nrz;
  wire  [63:0] rs0;

  stack8 rs(
    .clk_i(clk_i),
    .push_en_i(rpush),
    .pop_en_i(rpop),
    .pop2_en_i(1'b0),
    .dat_i(rz),
    .dat0_o(rs0)
    // .dat1_o(rs1) unused
  );

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

      nia <= ia;
      np <= 61'h1C00_0000_0000_0000; // 64'hE000_0000_0000_0000
      nt <= 0;

      dpush <= 0;
      dpop <= 0;
      dpop2 <= 0;
      nx <= x;
      ny <= y;
      nz <= z;

      rpush <= 0;
      rpop <= 0;
      nrz <= rz;

      ndr <= dr;
    end
    2'b01: begin
      adr_o <= p;
      cyc_o <= 1;
      we_o <= 0;
      vpa_o <= 1;
      sel_o <= 8'hFF;
      dat_o <= 64'd0;

      nia <= p;
      np <= p + 1;
      nt <= 1;

      dpush <= 0;
      dpop <= 0;
      nx <= x;
      ny <= y;
      nz <= z;

      rpush <= 0;
      rpop <= 0;
      nrz <= rz;

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

        nia <= ia;
        np <= p;
        nt <= t+1;

        dpush <= 0;
        dpop <= 0;
        nx <= x;
        ny <= y;
        nz <= z;

        rpush <= 0;
        rpop <= 0;
        nrz <= rz;

        ndr <= dr;
      end

      `OPC_LIT8: begin
        adr_o <= 0;
        cyc_o <= 0;
        we_o <= 0;
        vpa_o <= 0;
        sel_o <= 0;
        dat_o <= 64'd0;

        nia <= ia;
        np <= p;
        nt <= t+1;

        dpush <= 1;
        dpop <= 0;
        nx <= y;
        ny <= z;
        nz <= {{56{dr[7]}}, dr[7:0]};

        rpush <= 0;
        rpop <= 0;
        nrz <= rz;

        ndr <= dr >> 8;
      end

      `OPC_LIT16: begin
        adr_o <= 0;
        cyc_o <= 0;
        we_o <= 0;
        vpa_o <= 0;
        sel_o <= 0;
        dat_o <= 64'd0;

        nia <= ia;
        np <= p;
        nt <= t+1;

        dpush <= 1;
        dpop <= 0;
        nx <= y;
        ny <= z;
        nz <= {{48{dr[15]}}, dr[15:0]};

        rpush <= 0;
        rpop <= 0;
        nrz <= rz;

        ndr <= dr >> 16;
      end

      `OPC_LIT32: begin
        adr_o <= 0;
        cyc_o <= 0;
        we_o <= 0;
        vpa_o <= 0;
        sel_o <= 0;
        dat_o <= 64'd0;

        nia <= ia;
        np <= p;
        nt <= t+1;

        dpush <= 1;
        dpop <= 0;
        nx <= y;
        ny <= z;
        nz <= {{32{dr[31]}}, dr[31:0]};

        rpush <= 0;
        rpop <= 0;
        nrz <= rz;

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

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= ds1;
          ny <= ds0;
          nz <= x;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SHM: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 1;
          vpa_o <= 0;
          sel_o <= 3 << {z[2:1], 1'b0};
          dat_o <= {4{y[15:0]}};

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= ds1;
          ny <= ds0;
          nz <= x;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SWM: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 1;
          vpa_o <= 0;
          sel_o <= 15 << {z[2], 2'b0};
          dat_o <= {2{y[31:0]}};

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= ds1;
          ny <= ds0;
          nz <= x;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SDM: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 1;
          vpa_o <= 0;
          sel_o <= 8'b11111111;
          dat_o <= y;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= ds1;
          ny <= ds0;
          nz <= x;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

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

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= x;
          ny <= y;
          nz <= {56'd0, byte_in};

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_LHMU: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 3 << {z[2:1], 1'b0};

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= x;
          ny <= y;
          nz <= {48'd0, hword_in};

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_LWMU: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 15 << {z[2], 2'b0};

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= x;
          ny <= y;
          nz <= {32'd0, word_in};

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_LDMU: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 8'b11111111;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= x;
          ny <= y;
          nz <= dat_i;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_LBMS: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 1 << z[2:0];

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= x;
          ny <= y;
          nz <= {{56{byte_in[7]}}, byte_in};

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_LHMS: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 3 << {z[2:1], 1'b0};

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= x;
          ny <= y;
          nz <= {{48{hword_in[15]}}, hword_in};

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_LWMS: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 15 << {z[2], 2'b0};

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= x;
          ny <= y;
          nz <= {{32{word_in[31]}}, word_in};

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_LDMS: begin
          adr_o <= z[63:3];
          cyc_o <= 1;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 8'b11111111;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= x;
          ny <= y;
          nz <= dat_i;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        endcase
      end

      `OPC_INTOPS: begin
        case(dr[3:0])
        `N_ADD: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y + z;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SUB: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y - z;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SLL: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y << z;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SLT: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= $signed(y) < $signed(z);

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SLTU: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= $unsigned(y) < $unsigned(z);

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SGE: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= $signed(y) >= $signed(z);

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SGEU: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= $unsigned(y) >= $unsigned(z);

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SEQ: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y == z;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SNE: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y != z;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_XOR: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y ^ z;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SRL: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= $unsigned(y) >> $unsigned(z);

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_SRA: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= $signed(y) >> $signed(z);

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_OR: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y | z;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_AND: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y & z;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_BIC: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= p;
          nt <= t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y & ~z;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        endcase
      end

      `OPC_JUMPS: begin
        case(dr[3:0])
        `N_JT8: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= (|z) ? ia + dr[11:4] : p;
          nt <= (|z) ? 0 : t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 12;
        end
        `N_JF8: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= (|z) ? p : ia + dr[11:4];
          nt <= (|z) ? t+1 : 0;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 12;
        end
        `N_J8: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= ia + dr[11:4];
          nt <= 0;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 12;
        end
        `N_CALL8: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= ia + dr[11:4];
          nt <= 0;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y;

          rpush <= 1;
          rpop <= 0;
          nrz <= {p, 3'b000};

          ndr <= dr >> 12;
        end
        `N_JT16: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= (|z) ? ia + dr[19:4] : p;
          nt <= (|z) ? 0 : t+1;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 20;
        end
        `N_JF16: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= (|z) ? p : ia + dr[19:4];
          nt <= (|z) ? t+1 : 0;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 20;
        end
        `N_J16: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= ia + dr[19:4];
          nt <= 0;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 20;
        end
        `N_CALL16: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= ia + dr[19:4];
          nt <= 0;

          dpush <= 0;
          dpop <= 1;
          nx <= ds0;
          ny <= x;
          nz <= y;

          rpush <= 1;
          rpop <= 0;
          nrz <= {p, 3'b000};

          ndr <= dr >> 20;
        end
        `N_JTI: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= (|y) ? z[63:3] : p;
          nt <= (|y) ? 0 : t+1;

          dpush <= 0;
          dpop <= 0;
          nx <= ds1;
          ny <= ds0;
          nz <= x;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_JFI: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= (|y) ? p : z[63:3];
          nt <= (|y) ? t+1 : 0;

          dpush <= 0;
          dpop <= 0;
          nx <= ds1;
          ny <= ds0;
          nz <= y;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_JI: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= z[63:3];
          nt <= 0;

          dpush <= 0;
          dpop <= 0;
          nx <= ds1;
          ny <= ds0;
          nz <= y;

          rpush <= 0;
          rpop <= 0;
          nrz <= rz;

          ndr <= dr >> 4;
        end
        `N_CALLI: begin
          adr_o <= 0;
          cyc_o <= 0;
          we_o <= 0;
          vpa_o <= 0;
          sel_o <= 0;

          nia <= ia;
          np <= z[63:3];
          nt <= 0;

          dpush <= 0;
          dpop <= 0;
          nx <= ds1;
          ny <= ds0;
          nz <= y;

          rpush <= 1;
          rpop <= 0;
          nrz <= {p, 3'b000};

          ndr <= dr >> 4;
        end
        endcase
      end

      `OPC_RET: begin
        adr_o <= 0;
        cyc_o <= 0;
        we_o <= 0;
        vpa_o <= 0;
        sel_o <= 0;

        nia <= ia;
        np <= rz[63:3];
        nt <= 0;

        dpush <= 0;
        dpop <= 0;
        dpop2 <= 0;
        nx <= x;
        ny <= y;
        nz <= z;

        rpush <= 0;
        rpop <= 1;
        nrz <= rs0;

        ndr <= dr;
      end

      default: begin
        adr_o <= 0;
        cyc_o <= 0;
        we_o <= 0;
        vpa_o <= 0;
        sel_o <= 0;

        nia <= ia;
        np <= p;
        nt <= t+1;

        dpush <= 0;
        dpop <= 0;
        nx <= x;
        ny <= y;
        nz <= z;

        rpush <= 0;
        rpop <= 0;
        nrz <= rz;

        ndr <= dr;
      end
      endcase
    end
    endcase
  end

// always @(posedge clk_i) begin #5 $display("CLK=%d T=%d O=%4b DI=%016X DO=%016X ADR=%016X IIF=%d IR=%016X DR=%016X", clk_i, t, opcode, dat_i, dat_o, adr_o, is_instr_fetch, ir, dr); end

  always @(posedge clk_i) begin
    t <= nt;
    ia <= nia;
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
    rz <= nrz;
  end
endmodule
