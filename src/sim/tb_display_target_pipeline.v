`timescale 1ns/1ps
// Reuse the complete real resource-chain fixture in explicitly targeted mode.
module tb_display_target_pipeline;
    wire S_test_pass;
    tb_display_timed_pipeline #(.TARGETED(1)) u_fixture ();
    assign S_test_pass=u_fixture.S_test_pass;
endmodule
