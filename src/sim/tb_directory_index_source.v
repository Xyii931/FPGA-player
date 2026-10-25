`timescale 1ns/1ps
// Real directory producer + single real index store; enum protocol endpoints are stimulus.
module tb_directory_index_source;
    // Declare shared endpoint signals before instance connections.
    reg S_allow_item=1,S_allow_string=1,S_allow_commit=1;
    reg S_acquire=0,S_release=0,S_read=0,S_read_result_ready=0;
    reg [5:0] S_read_index=0;
    reg [1:0] S_read_kind=0;
    reg [6:0] S_read_address=0;
    reg  S_I_clk=0;
    reg  S_I_reset=0;
    reg  S_I_media_valid=0;
    reg [31:0] S_I_media_generation=0;
    reg  S_I_start_valid=0;
    wire  S_O_start_ready;
    wire  S_O_lease_request;
    wire  S_O_lease_active;
    reg  S_I_lease_grant=0;
    reg  S_I_abort=0;
    reg [15:0] S_I_tag=0;
    reg [31:0] S_I_generation=0;
    reg [31:0] S_I_seed=0;
    reg [31:0] S_I_sector_budget=0;
    reg [9:0] S_I_duration=0;
    reg [9:0] S_I_transition_ms=0;
    reg [2:0] S_I_transition=0;
    reg [1:0] S_I_order=0;
    wire  S_O_done_valid;
    reg  S_I_done_ready=0;
    wire [3:0] S_O_error;
    wire [6:0] S_O_count;
    wire [7:0] S_O_warning;
    wire [7:0] S_O_directory_error;
    wire [7:0] S_O_primary_error;
    wire [3:0] S_O_storage_error;
    wire [2:0] S_O_directory_warning;
    wire [32:0] S_O_sectors;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_generation;
    wire  S_O_committed;
    wire  S_O_enum_valid;
    reg  S_I_enum_ready=0;
    wire [15:0] S_O_enum_tag;
    wire [6:0] S_O_enum_path_length;
    wire [31:0] S_O_enum_sector_budget;
    wire  S_O_enum_path_valid;
    reg  S_I_enum_path_ready=0;
    wire [7:0] S_O_enum_path_data;
    wire  S_O_enum_path_last;
    wire  S_O_enum_stop;
    wire  S_O_enum_cancel;
    reg  S_I_enum_entry_valid=0;
    wire  S_O_enum_entry_ready;
    reg [7:0] S_I_enum_attr=0;
    reg [31:0] S_I_enum_size=0;
    reg [31:0] S_I_enum_first_cluster=0;
    reg [6:0] S_I_enum_name_length=0;
    reg  S_I_enum_name_valid=0;
    wire  S_O_enum_name_ready;
    reg [7:0] S_I_enum_name_data=0;
    reg  S_I_enum_name_last=0;
    reg  S_I_enum_done_valid=0;
    wire  S_O_enum_done_ready;
    reg [15:0] S_I_enum_tag=0;
    reg [31:0] S_I_enum_generation=0;
    reg [31:0] S_I_enum_sectors=0;
    reg [7:0] S_I_enum_error=0;
    reg [3:0] S_I_enum_storage_error=0;
    reg [2:0] S_I_enum_warning=0;
    wire  S_O_store_begin_valid;
    reg  S_I_store_begin_ready=0;
    wire  S_O_store_abort;
    wire  S_O_store_item_valid;
    reg  S_I_store_item_ready=0;
    wire [6:0] S_O_store_file_length;
    wire [6:0] S_O_store_audio_length;
    wire [5:0] S_O_store_title_length;
    wire [9:0] S_O_store_duration;
    wire [9:0] S_O_store_transition_ms;
    wire [2:0] S_O_store_transition;
    wire  S_O_store_string_valid;
    reg  S_I_store_string_ready=0;
    wire [7:0] S_O_store_string_data;
    wire  S_O_store_string_last;
    wire  S_O_store_finish_valid;
    reg  S_I_store_finish_ready=0;
    wire [1:0] S_O_store_order;
    wire [31:0] S_O_store_seed;
    wire  S_O_store_commit_valid;
    wire  S_O_store_source_retired;
    reg  S_I_store_commit_ready=0;
    reg  S_I_store_done_valid=0;
    wire  S_O_store_done_ready;
    reg [3:0] S_I_store_error=0;
    directory_index_source u_source (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .O_lease_request(S_O_lease_request),
        .O_lease_active(S_O_lease_active),
        .I_lease_grant(S_I_lease_grant),
        .I_abort(S_I_abort),
        .I_tag(S_I_tag),
        .I_generation(S_I_generation),
        .I_seed(S_I_seed),
        .I_sector_budget(S_I_sector_budget),
        .I_duration(S_I_duration),
        .I_transition_ms(S_I_transition_ms),
        .I_transition(S_I_transition),
        .I_order(S_I_order),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_error(S_O_error),
        .O_count(S_O_count),
        .O_warning(S_O_warning),
        .O_directory_error(S_O_directory_error),
        .O_primary_error(S_O_primary_error),
        .O_storage_error(S_O_storage_error),
        .O_directory_warning(S_O_directory_warning),
        .O_sectors(S_O_sectors),
        .O_tag(S_O_tag),
        .O_generation(S_O_generation),
        .O_committed(S_O_committed),
        .O_enum_valid(S_O_enum_valid),
        .I_enum_ready(S_I_enum_ready),
        .O_enum_tag(S_O_enum_tag),
        .O_enum_path_length(S_O_enum_path_length),
        .O_enum_sector_budget(S_O_enum_sector_budget),
        .O_enum_path_valid(S_O_enum_path_valid),
        .I_enum_path_ready(S_I_enum_path_ready),
        .O_enum_path_data(S_O_enum_path_data),
        .O_enum_path_last(S_O_enum_path_last),
        .O_enum_stop(S_O_enum_stop),
        .O_enum_cancel(S_O_enum_cancel),
        .I_enum_entry_valid(S_I_enum_entry_valid),
        .O_enum_entry_ready(S_O_enum_entry_ready),
        .I_enum_attr(S_I_enum_attr),
        .I_enum_size(S_I_enum_size),
        .I_enum_first_cluster(S_I_enum_first_cluster),
        .I_enum_name_length(S_I_enum_name_length),
        .I_enum_name_valid(S_I_enum_name_valid),
        .O_enum_name_ready(S_O_enum_name_ready),
        .I_enum_name_data(S_I_enum_name_data),
        .I_enum_name_last(S_I_enum_name_last),
        .I_enum_done_valid(S_I_enum_done_valid),
        .O_enum_done_ready(S_O_enum_done_ready),
        .I_enum_tag(S_I_enum_tag),
        .I_enum_generation(S_I_enum_generation),
        .I_enum_sectors(S_I_enum_sectors),
        .I_enum_error(S_I_enum_error),
        .I_enum_storage_error(S_I_enum_storage_error),
        .I_enum_warning(S_I_enum_warning),
        .O_store_begin_valid(S_O_store_begin_valid),
        .I_store_begin_ready(S_I_store_begin_ready),
        .O_store_abort(S_O_store_abort),
        .O_store_item_valid(S_O_store_item_valid),
        .I_store_item_ready(S_I_store_item_ready),
        .O_store_file_length(S_O_store_file_length),
        .O_store_audio_length(S_O_store_audio_length),
        .O_store_title_length(S_O_store_title_length),
        .O_store_duration(S_O_store_duration),
        .O_store_transition_ms(S_O_store_transition_ms),
        .O_store_transition(S_O_store_transition),
        .O_store_string_valid(S_O_store_string_valid),
        .I_store_string_ready(S_I_store_string_ready),
        .O_store_string_data(S_O_store_string_data),
        .O_store_string_last(S_O_store_string_last),
        .O_store_finish_valid(S_O_store_finish_valid),
        .I_store_finish_ready(S_I_store_finish_ready),
        .O_store_order(S_O_store_order),
        .O_store_seed(S_O_store_seed),
        .O_store_commit_valid(S_O_store_commit_valid),
        .O_store_source_retired(S_O_store_source_retired),
        .I_store_commit_ready(S_I_store_commit_ready),
        .I_store_done_valid(S_I_store_done_valid),
        .O_store_done_ready(S_O_store_done_ready),
        .I_store_error(S_I_store_error)
    );
    wire [6:0] S_policy_u_store_O_read_policy;
    wire  S_M_O_begin_ready;
    wire  S_M_O_item_ready;
    wire  S_M_O_string_ready;
    wire  S_M_O_finish_ready;
    wire  S_M_O_commit_ready;
    wire  S_M_O_busy;
    wire [6:0] S_M_O_staged_count;
    wire  S_M_O_done_valid;
    wire [3:0] S_M_O_error;
    wire [15:0] S_M_O_tag;
    wire [31:0] S_M_O_generation;
    wire  S_M_O_active_valid;
    wire [6:0] S_M_O_active_count;
    wire [31:0] S_M_O_active_generation;
    wire [31:0] S_M_O_active_revision;
    wire  S_M_O_acquire_ready;
    wire  S_M_O_snapshot_valid;
    wire [6:0] S_M_O_snapshot_count;
    wire [31:0] S_M_O_snapshot_generation;
    wire [31:0] S_M_O_snapshot_revision;
    wire  S_M_O_release_ready;
    wire  S_M_O_read_ready;
    wire  S_M_O_read_result_valid;
    wire [6:0] S_M_O_read_file_length;
    wire [6:0] S_M_O_read_audio_length;
    wire [5:0] S_M_O_read_title_length;
    wire [9:0] S_M_O_read_duration;
    wire [9:0] S_M_O_read_transition_ms;
    wire [2:0] S_M_O_read_transition;
    wire [7:0] S_M_O_read_data;
    wire [15:0] S_M_O_read_tag;
    wire [3:0] S_M_O_read_error;
        wire [1:0] S_runtime_u_store_O_active_order;
    wire [1:0] S_runtime_u_store_O_active_base_order;
    wire S_runtime_u_store_O_active_base_order_explicit;
    wire S_runtime_u_store_O_reorder_ready;
    wire S_runtime_u_store_O_reorder_done_valid;
    wire [3:0] S_runtime_u_store_O_reorder_error;
    wire [15:0] S_runtime_u_store_O_reorder_tag;
    wire [31:0] S_runtime_u_store_O_reorder_generation;
    wire [31:0] S_runtime_u_store_O_reorder_revision;
    wire [5:0] S_runtime_u_store_O_reorder_current_index;
media_index_store u_store (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_begin_valid(S_O_store_begin_valid),
        .O_begin_ready(S_M_O_begin_ready),
        .I_tag(S_I_tag),
        .I_generation(S_I_generation),
        .I_abort(S_O_store_abort),
        .I_item_valid(S_O_store_item_valid && S_allow_item),
        .O_item_ready(S_M_O_item_ready),
        .I_file_length(S_O_store_file_length),
        .I_audio_length(S_O_store_audio_length),
        .I_title_length(S_O_store_title_length),
        .I_duration(S_O_store_duration),
        .I_transition_ms(S_O_store_transition_ms),
        .I_transition(S_O_store_transition),
        .I_string_valid(S_O_store_string_valid && S_allow_string),
        .O_string_ready(S_M_O_string_ready),
        .I_string_data(S_O_store_string_data),
        .I_string_last(S_O_store_string_last),
        .I_finish_valid(S_O_store_finish_valid),
        .O_finish_ready(S_M_O_finish_ready),
        .I_order(S_O_store_order),
        .I_seed(S_O_store_seed),
        .I_commit_valid(S_O_store_commit_valid && S_allow_commit),
        .I_source_retired(S_O_store_source_retired),
        .O_commit_ready(S_M_O_commit_ready),
        .O_busy(S_M_O_busy),
        .O_staged_count(S_M_O_staged_count),
        .O_done_valid(S_M_O_done_valid),
        .I_done_ready(S_O_store_done_ready),
        .O_error(S_M_O_error),
        .O_tag(S_M_O_tag),
        .O_generation(S_M_O_generation),
        .O_active_valid(S_M_O_active_valid),
        .O_active_count(S_M_O_active_count),
        .O_active_generation(S_M_O_active_generation),
        .O_active_revision(S_M_O_active_revision),
        .I_acquire_valid(S_acquire),
        .O_acquire_ready(S_M_O_acquire_ready),
        .O_snapshot_valid(S_M_O_snapshot_valid),
        .O_snapshot_count(S_M_O_snapshot_count),
        .O_snapshot_generation(S_M_O_snapshot_generation),
        .O_snapshot_revision(S_M_O_snapshot_revision),
        .I_release_valid(S_release),
        .O_release_ready(S_M_O_release_ready),
        .I_read_valid(S_read),
        .O_read_ready(S_M_O_read_ready),
        .I_read_index(S_read_index),
        .I_read_kind(S_read_kind),
        .I_read_address(S_read_address),
        .I_read_tag(16'h9071),
        .O_read_result_valid(S_M_O_read_result_valid),
        .I_read_result_ready(S_read_result_ready),
        .O_read_file_length(S_M_O_read_file_length),
        .O_read_audio_length(S_M_O_read_audio_length),
        .O_read_title_length(S_M_O_read_title_length),
        .O_read_duration(S_M_O_read_duration),
        .O_read_transition_ms(S_M_O_read_transition_ms),
        .O_read_transition(S_M_O_read_transition),
        .O_read_data(S_M_O_read_data),
        .O_read_tag(S_M_O_read_tag),
        .O_read_error(S_M_O_read_error),
        .I_policy(7'h07),
        .O_read_policy(S_policy_u_store_O_read_policy),
        .I_base_order(2'd0),
        .I_base_order_explicit(1'b0),
        .O_active_order(S_runtime_u_store_O_active_order),
        .O_active_base_order(S_runtime_u_store_O_active_base_order),
        .O_active_base_order_explicit(S_runtime_u_store_O_active_base_order_explicit),
        .I_reorder_valid(1'b0),
        .O_reorder_ready(S_runtime_u_store_O_reorder_ready),
        .I_reorder_order(2'd0),
        .I_reorder_seed(32'd0),
        .I_reorder_generation(32'd0),
        .I_reorder_tag(16'd0),
        .I_reorder_current_index(6'd0),
        .I_reorder_abort(1'b0),
        .O_reorder_done_valid(S_runtime_u_store_O_reorder_done_valid),
        .I_reorder_done_ready(1'b0),
        .O_reorder_error(S_runtime_u_store_O_reorder_error),
        .O_reorder_tag(S_runtime_u_store_O_reorder_tag),
        .O_reorder_generation(S_runtime_u_store_O_reorder_generation),
        .O_reorder_revision(S_runtime_u_store_O_reorder_revision),
        .O_reorder_current_index(S_runtime_u_store_O_reorder_current_index)
    );
    always #4 S_I_clk=~S_I_clk;
    always @* begin
        S_I_store_begin_ready=S_M_O_begin_ready;
        S_I_store_item_ready=S_M_O_item_ready && S_allow_item;
        S_I_store_string_ready=S_M_O_string_ready && S_allow_string;
        S_I_store_finish_ready=S_M_O_finish_ready;
        S_I_store_commit_ready=S_M_O_commit_ready && S_allow_commit;
        S_I_store_done_valid=S_M_O_done_valid;
        S_I_store_error=S_M_O_error;
    end
    reg S_test_pass=0;
    reg [71:0] S_primary="/PLAY/IMG";
    reg [511:0] S_name;
    reg [159:0] S_held;
    reg [7:0] S_tens,S_ones;
    integer S_i,S_j,S_k,S_case=0,S_revision=0,S_enums=0,S_before;
    task fail;
        input [767:0] message;
        begin $display("FAIL: directory source case %0d: %0s",S_case,message); $stop; end
    endtask
    task start;
        input [15:0] tag;
        input [1:0] order;
        input integer budget;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_start_valid=1; S_I_tag=tag;
            S_I_generation=S_I_media_generation; S_I_seed=32'h12345;
            S_I_duration=25; S_I_transition=3; S_I_transition_ms=600; S_I_order=order; S_I_sector_budget=budget;
            @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_start_valid=0;
            S_I_tag=0; S_I_generation=0; S_I_seed=0; S_I_duration=1;
            S_I_transition=0; S_I_transition_ms=200; S_I_order=3; S_I_sector_budget=0;
        end
    endtask
    task enum_path;
        input root_path;
        input integer budget;
        begin
            wait(S_O_enum_valid);
            if(S_O_enum_path_length!==(root_path ? 1 : 9) || S_O_enum_sector_budget!==budget ||
                S_O_enum_tag!==(S_O_tag+(root_path ? 16'd1 : 16'd0))) fail("enum path/budget/identity");
            repeat(3) @(negedge S_I_clk);
            S_I_enum_ready=1;
            @(posedge S_I_clk); if(!S_O_enum_valid) fail("enum command waiting stability");
            @(negedge S_I_clk); S_I_enum_ready=0; S_I_enum_path_ready=1;
            for(S_j=0;S_j<(root_path ? 1 : 9);S_j=S_j+1) begin
                @(posedge S_I_clk); while(!S_O_enum_path_valid) @(posedge S_I_clk);
                if(S_O_enum_path_data!==(root_path ? 8'h2f : S_primary[(8-S_j)*8+:8]) ||
                    S_O_enum_path_last!==(root_path || S_j==8)) fail("enum path byte framing");
                @(negedge S_I_clk);
            end
            S_I_enum_path_ready=0; S_I_enum_tag=S_O_enum_tag; S_I_enum_generation=S_O_generation;
        end
    endtask
    task entry_header;
        input integer length;
        input [7:0] attr;
        input integer size,cluster;
        begin
            @(negedge S_I_clk); S_I_enum_entry_valid=1; S_I_enum_name_length=length;
            S_I_enum_attr=attr; S_I_enum_size=size; S_I_enum_first_cluster=cluster;
            S_I_enum_tag=S_O_enum_tag; S_I_enum_generation=S_O_generation;
            @(posedge S_I_clk); while(!S_O_enum_entry_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_enum_entry_valid=0;
        end
    endtask
    task entry;
        input [511:0] name;
        input integer length;
        input [7:0] attr;
        input integer size,cluster;
        begin
            entry_header(length,attr,size,cluster);
            for(S_k=0;S_k<length;S_k=S_k+1) begin
                S_I_enum_name_valid=1; S_I_enum_name_data=name[(length-1-S_k)*8+:8];
                S_I_enum_name_last=S_k==length-1;
                @(posedge S_I_clk); while(!S_O_enum_name_ready) @(posedge S_I_clk);
                @(negedge S_I_clk);
            end
            S_I_enum_name_valid=0;
        end
    endtask
    task enum_done;
        input [7:0] error;
        input integer sectors;
        input [2:0] warning;
        begin
            @(negedge S_I_clk); S_I_enum_done_valid=1;
            S_I_enum_tag=S_O_enum_tag; S_I_enum_generation=S_O_generation;
            S_I_enum_error=error; S_I_enum_sectors=sectors; S_I_enum_warning=warning;
            @(posedge S_I_clk); while(!S_O_enum_done_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_enum_done_valid=0; S_I_enum_storage_error=0;
        end
    endtask
    task finish;
        input [3:0] error;
        input integer count,sectors;
        input [7:0] warning;
        input committed;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || S_O_count!==count || S_O_sectors!==sectors ||
                S_O_warning!==warning || S_O_committed!==committed) fail("source final error/count/warning/sectors/commit");
            if(committed) begin
                S_revision=S_revision+1;
                if(!S_M_O_active_valid || S_M_O_active_count!==count || S_M_O_active_revision!==S_revision ||
                    S_M_O_active_generation!==S_O_generation) fail("store atomic commit");
            end else if(S_M_O_active_revision!==S_revision) fail("failed directory changed active revision");
            S_held={S_O_error,S_O_count,S_O_sectors,S_O_warning,S_O_committed,S_O_tag,S_O_generation};
            S_I_abort=1;
            repeat(6) begin
                @(negedge S_I_clk); S_I_abort=0;
                if(!S_O_done_valid || S_O_start_ready ||
                    {S_O_error,S_O_count,S_O_sectors,S_O_warning,S_O_committed,S_O_tag,S_O_generation}!==S_held)
                    fail("terminal backpressure / late abort");
            end
            S_I_done_ready=1;
            @(negedge S_I_clk); S_I_done_ready=0;
            if(S_O_lease_active) fail("namespace lease not released");
        end
    endtask
    task acquire;
        begin
            @(negedge S_I_clk); S_acquire=1;
            @(posedge S_I_clk); while(!S_M_O_acquire_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_acquire=0;
        end
    endtask
    task release_snapshot;
        begin
            @(negedge S_I_clk); S_release=1;
            @(posedge S_I_clk); while(!S_M_O_release_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_release=0;
        end
    endtask
    task expect_record;
        input [5:0] index;
        input [511:0] file_path;
        input integer file_length;
        input [319:0] title;
        input integer title_length;
        begin
            for(S_i=0;S_i<file_length+title_length+2;S_i=S_i+1) begin
                @(negedge S_I_clk); S_read=1; S_read_index=index;
                S_read_kind=S_i<=file_length ? 0 : 2;
                S_read_address=S_i<=file_length ? S_i : S_i-file_length-1;
                @(posedge S_I_clk); while(!S_M_O_read_ready) @(posedge S_I_clk);
                @(negedge S_I_clk); S_read=0;
                wait(S_M_O_read_result_valid); #1;
                if(S_M_O_read_error!==0 || S_M_O_read_tag!==16'h9071 || S_M_O_read_file_length!==file_length ||
                    S_M_O_read_audio_length!==0 || S_M_O_read_title_length!==title_length || S_M_O_read_duration!==25 ||
                    S_M_O_read_transition!==3 || S_M_O_read_transition_ms!==600) fail("record metadata/tag/default snapshot");
                if(S_M_O_read_data!==(S_i<file_length ? file_path[(file_length-1-S_i)*8+:8] :
                    S_i==file_length || S_i==file_length+title_length+1 ? 8'd0 :
                    title[(title_length-1-(S_i-file_length-1))*8+:8])) fail("record path/title/zero padding");
                @(negedge S_I_clk); S_read_result_ready=1;
                @(negedge S_I_clk); S_read_result_ready=0;
            end
        end
    endtask
    task abort_and_wait;
        begin
            @(negedge S_I_clk); S_I_abort=1;
            @(negedge S_I_clk); S_I_abort=0;
            repeat(9) begin
                @(negedge S_I_clk);
                if(!S_O_enum_cancel || S_O_done_valid || S_O_enum_valid || S_O_store_commit_valid)
                    fail("cancel did not await actual enum retirement");
            end
        end
    endtask
    always @(posedge S_I_clk) if(!S_I_reset) begin
        if(S_O_enum_valid && S_I_enum_ready) S_enums=S_enums+1;
        if(S_O_store_commit_valid && S_I_store_commit_ready && !S_O_store_source_retired)
            fail("commit without real enum_done retirement");
    end

    initial begin
        S_I_reset=1; S_I_media_valid=1; S_I_media_generation=32'h78abcd12;
        #35; @(negedge S_I_clk); S_I_reset=0;
        // Namespace grant must be requested before ready, with no speculative store begin.
        S_I_start_valid=1;
        repeat(6) begin
            @(negedge S_I_clk);
            if(!S_O_lease_request || S_O_start_ready || S_O_store_begin_valid || S_O_enum_valid)
                fail("lease request depends on prior grant / bypasses grant");
        end
        S_I_start_valid=0; S_I_lease_grant=1;
        start(16'h3100,0,12); enum_path(0,12);
        entry("folder.bmp",10,16,100,3); entry("notes.txt",9,32,100,3);
        entry("bad/name.bmp",12,32,100,3); entry(".bmp",4,32,100,3);
        entry("tiny.bmp",8,32,53,3); entry("chain.bmp",9,32,100,1);
        entry("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.bmp",55,32,100,3);
        entry("Zoo.BMP",7,32,100,3); entry("alpha.bmp",9,32,100,3);
        // Finish copying alpha before stalling the following candidate's
        // metadata; otherwise its entry header can never be accepted.
        wait(S_O_enum_entry_ready); @(negedge S_I_clk);
        S_allow_item=0;
        entry("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ.bmp",49,32,100,3);
        wait(S_O_store_item_valid);
        repeat(4) begin @(negedge S_I_clk); if(S_O_enum_entry_ready) fail("new entry while copying metadata"); end
        S_allow_item=1;
        S_allow_commit=0;
        enum_done(0,3,2);
        wait(S_O_store_commit_valid);
        repeat(5) begin @(negedge S_I_clk); if(S_O_done_valid || S_M_O_active_valid) fail("early commit/terminal"); end
        S_allow_commit=1; finish(0,3,3,8'h56,1);
        if(S_O_directory_warning!==2) fail("directory warning aggregation");
        acquire;
        expect_record(0,"/PLAY/IMG/alpha.bmp",19,"alpha",5);
        expect_record(1,"/PLAY/IMG/Zoo.BMP",17,"Zoo",3);
        expect_record(2,"/PLAY/IMG/ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ.bmp",59,"ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ",40);

        // Keep old snapshot across root fallback/commit; root tag wraps independently.
        start(16'hffff,1,12); enum_path(0,12); enum_done(14,2,0); enum_path(1,10);
        @(negedge S_I_clk); S_I_enum_entry_valid=1; S_I_enum_name_valid=1; S_I_enum_done_valid=1;
        S_I_enum_tag=16'hffff; S_I_enum_generation=S_O_generation; S_I_enum_error=0;
        @(posedge S_I_clk);
        if(!S_O_enum_entry_ready || !S_O_enum_name_ready || !S_O_enum_done_ready || S_O_store_item_valid)
            fail("stale primary identity not drained during root attempt");
        @(negedge S_I_clk); S_I_enum_entry_valid=0; S_I_enum_name_valid=0; S_I_enum_done_valid=0;
        S_I_enum_tag=0; S_I_enum_generation=S_O_generation+1; S_I_enum_done_valid=1;
        @(posedge S_I_clk); if(!S_O_enum_done_ready) fail("stale enum generation not drained");
        @(negedge S_I_clk); S_I_enum_done_valid=0;
        entry("root.bmp",8,32,54,4); enum_done(0,1,0); finish(0,1,3,8'h21,1);
        if(S_O_primary_error!==14 || S_O_directory_error!==0) fail("primary/root diagnostic separation");
        expect_record(0,"/PLAY/IMG/alpha.bmp",19,"alpha",5);
        fork
            begin start(16'h3102,1,5); end
            begin
                wait(S_O_lease_request);
                repeat(7) begin @(negedge S_I_clk); if(S_O_start_ready) fail("overwrote retained snapshot bank"); end
                release_snapshot;
            end
        join
        enum_path(0,5); enum_done(0,3,0); enum_path(1,2); enum_done(0,1,0);
        finish(5,0,4,1,0);
        acquire; expect_record(0,"/root.bmp",9,"root",4); release_snapshot;

        // Root paths at exactly 64 bytes are legal; 65-byte assembled paths are skipped.
        start(16'h3115,1,8); enum_path(0,8); enum_done(15,1,0); enum_path(1,7);
        entry("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.bmp",64,32,100,3);
        entry("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.bmp",63,32,100,3);
        enum_done(0,1,0); finish(0,1,2,8'h63,1);
        acquire; expect_record(0,"/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.bmp",64,"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",40); release_snapshot;

        start(16'h3103,1,2); enum_path(0,2); enum_done(14,2,0); finish(1,0,2,0,0);
        if(S_O_directory_error!==10 || S_O_primary_error!==14) fail("fallback exceeded common sector budget");
        start(16'h3104,1,2); enum_path(0,2); enum_done(0,3,0); finish(4,0,3,0,0);

        start(16'h3105,1,8); enum_path(0,8); entry("partial.bmp",11,32,100,3);
        wait(S_O_count==1); S_I_enum_storage_error=4;
        enum_done(2,2,0); finish(1,1,2,0,0);
        if(S_O_storage_error!==4 || S_O_directory_error!==2) fail("raw directory I/O error");

        // Start cancellation before an enum is accepted still retires the started store.
        S_I_abort=1; start(16'h3106,1,8); S_I_abort=0; finish(2,0,0,0,0);
        // Cancel in an incomplete name; drain old traffic, wait held done.
        start(16'h3107,1,8); enum_path(0,8); entry_header(8,32,100,3);
        @(negedge S_I_clk); S_I_enum_name_valid=1; S_I_enum_name_data="x"; S_I_enum_name_last=0;
        @(negedge S_I_clk); S_I_enum_name_valid=0;
        abort_and_wait; enum_done(8,1,0); finish(2,0,1,0,0);

        // Abort a partially copied candidate without committing any part of its record.
        start(16'h3108,1,8); enum_path(0,8); S_allow_string=0;
        entry("copy.bmp",8,32,100,3); wait(S_O_store_string_valid);
        abort_and_wait; S_allow_string=1; enum_done(8,1,0); finish(2,0,1,0,0);

        // Malformed name last / invalid name_length are protocol failures, not fallback.
        start(16'h3109,1,8); enum_path(0,8); entry_header(8,32,100,3);
        @(negedge S_I_clk); S_I_enum_name_valid=1; S_I_enum_name_data="x"; S_I_enum_name_last=1;
        @(negedge S_I_clk); S_I_enum_name_valid=0;
        wait(S_O_enum_cancel); enum_done(8,1,0); finish(4,0,1,0,0);
        start(16'h3110,1,8); enum_path(0,8); entry_header(65,32,100,3);
        wait(S_O_enum_cancel); enum_done(8,1,0); finish(4,0,1,0,0);

        // Successful EOF cannot silently discard an incomplete advertised name.
        start(16'h3120,1,8); enum_path(0,8); entry_header(8,32,100,3);
        enum_done(0,1,0); finish(4,0,1,0,0);
        // A failing enum terminal may interrupt a candidate stalled at the store.
        start(16'h3121,1,8); enum_path(0,8); S_allow_string=0;
        entry("failed.bmp",10,32,100,3); wait(S_O_store_string_valid);
        S_I_enum_storage_error=4; enum_done(2,1,0); S_allow_string=1;
        finish(1,0,1,0,0);

        start(16'h3111,1,8); enum_path(0,8);
        for(S_i=0;S_i<64;S_i=S_i+1) begin
            S_tens=8'd48+S_i/10; S_ones=8'd48+S_i%10;
            S_name={"p",S_tens,S_ones,".bmp"}; entry(S_name,7,32,100,3);
        end
        wait(S_O_enum_stop);
        if(S_O_enum_cancel || S_O_done_valid) fail("capacity limit used failure / early retirement");
        enum_done(0,4,0); finish(0,64,4,8'h08,1);
        acquire; expect_record(0,"/PLAY/IMG/p00.bmp",17,"p00",3);
        expect_record(63,"/PLAY/IMG/p63.bmp",17,"p63",3); release_snapshot;

        start(16'h3112,1,8); enum_path(0,8); entry("late.bmp",8,32,100,3);
        S_allow_commit=0; enum_done(0,2,0); wait(S_O_store_commit_valid);
        @(negedge S_I_clk); S_I_abort=1;
        @(negedge S_I_clk); S_I_abort=0; S_allow_commit=1;
        finish(2,1,2,0,0);

        start(16'h3113,1,8); enum_path(0,8);
        @(negedge S_I_clk); S_I_media_valid=0;
        @(negedge S_I_clk); S_I_media_valid=1;
        wait(S_O_enum_cancel); enum_done(1,1,0); finish(3,0,1,0,0);
        if(S_M_O_active_valid) fail("short media loss revived old active index");
        S_I_media_generation=S_I_media_generation+1;
        start(16'h3114,2,8); enum_path(0,8); entry("new.bmp",7,32,100,3);
        enum_done(0,2,0); finish(0,1,2,0,1);
        acquire; expect_record(0,"/PLAY/IMG/new.bmp",17,"new",3); release_snapshot;

        start(16'h3116,3,8); finish(4,0,0,0,0);
        start(16'h3117,1,0); finish(4,0,0,0,0);
        // Explicit global reset discards both producer and store, without a fake enum_done.
        start(16'h3118,1,8); enum_path(0,8); entry_header(8,32,100,3);
        @(negedge S_I_clk); S_I_reset=1;
        repeat(4) @(negedge S_I_clk);
        S_I_reset=0; S_revision=0;
        if(S_O_lease_active || S_O_done_valid || S_M_O_active_valid) fail("global reset cleanup");
        start(16'h3119,1,8); enum_path(0,8); entry("last.bmp",8,32,100,3);
        enum_done(0,2,0); finish(0,1,2,0,1);

        S_test_pass=1;
        $display("PASS: directory_index_source candidate filtering, fallback, store ownership and retirement");
        $finish;
    end
    initial begin #50000000; fail("watchdog: directory/store handshake did not retire"); end
endmodule
