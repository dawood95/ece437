/*
  Eric Villasenor
  evillase@gmail.com

  register file test bench
*/

// mapped needs this
`include "register_file_if.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

module register_file_tb;

  parameter PERIOD = 10;

  logic CLK = 0, nRST;

  // test vars
  int v1 = 1;
  int v2 = 4721;
  int v3 = 25119;

  // clock
  always #(PERIOD/2) CLK++;

  // interface
  register_file_if rfif ();
  // test program
  test PROG (CLK, nRST, rfif);
  // DUT
`ifndef MAPPED
  register_file DUT(CLK, nRST, rfif);
`else
  register_file DUT(
    .\rfif.rdat2 (rfif.rdat2),
    .\rfif.rdat1 (rfif.rdat1),
    .\rfif.wdat (rfif.wdat),
    .\rfif.rsel2 (rfif.rsel2),
    .\rfif.rsel1 (rfif.rsel1),
    .\rfif.wsel (rfif.wsel),
    .\rfif.WEN (rfif.WEN),
    .\nRST (nRST),
    .\CLK (CLK)
  );
`endif

endmodule


program test (
  input logic CLK,
  output logic nRST,
  register_file_if.tb rfif_tb
);

initial begin
  parameter PERIOD = 10;
  int testnum, chknRST, i;

  // initial reset
  nRST = 0;
  #(PERIOD);
  nRST = 1;
  #(PERIOD);

  // write values into every register
  rfif_tb.WEN = 1;
  for (int i=1; i <= 32; i++) begin
    rfif_tb.wsel = i-1;
    rfif_tb.wdat = i;
    #(PERIOD);
  end

  $display("\n\n***** START OF TESTS *****\n");

  // TEST 1: check that register[0] is 0 even though we wrote a 1
  testnum = 1;
  rfif_tb.rsel1 = 0;
  #(PERIOD);
  if (rfif_tb.rdat1 != 0) $error("TEST 1 FAILED: register[0] is %d", rfif_tb.rdat1);
  else $display("TEST  1 passed");

  // TEST 2-33: check the values in every register
  for (i=1; i<32; i++) begin
    testnum++;
    rfif_tb.rsel1 = i;
    #(PERIOD);
    if (rfif_tb.rdat1 == i+1) $display("TEST %2d passed", testnum);
    else $error("TEST %d FAILED: rfif_tb.rdat1 = %d", i, rfif_tb.rdat1);
  end

  // TEST 34: asynchronous reset
  testnum++;
  nRST = 0;
  #(PERIOD);
  for (i=0; i<32; i++) begin
    rfif_tb.rsel2 = i;
    #(PERIOD)
    if (rfif_tb.rdat2 != 0)
    begin
      break;
      chknRST = 0;
    end
    else chknRST = 1;
  end

  if (!chknRST) $error("TEST 34 FAILED at reg %d", i);
  else $display("TEST 34 passed");

  #(PERIOD);

  $display("\n***** END OF TESTS *****\n\n");
end

endprogram
