import uvm_pkg::*;
`include "uvm_macros.svh"

module counter(clk,rst,load,mode,din,count);
  input clk,rst,load,mode;
  input [3:0]din;
  output reg [3:0]count;
  
  always @(posedge clk)
    begin
      if(rst)
        count<=0;
      else if(load)
        count<=din;
      else begin
        if(mode)
          count<=count+1;
        else 
          count<=count-1;
      end
    end
endmodule


interface intf(input logic clk);
  logic rst,load,mode;
  logic [3:0]din,count;
  
  clocking Drv @(posedge clk);
    default input #0 output #1;
    output rst,load,mode;
    output din;
  endclocking
  
  clocking Mon @(posedge clk);
    default input #1 output #0;
    input rst,load,mode;
    input din,count;
  endclocking
  
  modport drv(clocking Drv);
  modport mon(clocking Mon);

  property reset;
	@(posedge clk) $rose(rst) |=> (count==0);
  endproperty

  property load1;
	@(posedge clk) disable iff(rst)
		(load) |=> (count==din);
  endproperty

  property mode1;
	@(posedge clk) disable iff(rst)
		(!load && mode) |=> count==$past(count,1)+1;
  endproperty

  property mode_off;
	@(posedge clk) disable iff(rst)
		(!load && !mode) |=> if(count<=15) count==$past(count,1)-1
					else count==0; 
  endproperty 

  Reset: assert property(reset);
  Load: assert property(load1);
  Mode: assert property(mode1);
  Mode_off: assert property(mode_off);

endinterface

class conf extends uvm_object;
  `uvm_object_utils(conf);
  
  virtual intf vif;
  int num=1;
  uvm_active_passive_enum is_active=UVM_ACTIVE;
  uvm_active_passive_enum is_passive=UVM_PASSIVE;
  
  function new(string name="conf");
    super.new(name);
  endfunction
endclass

class tx extends uvm_sequence_item;
  
  `uvm_object_utils(tx)
  
  rand bit load,mode;
  rand bit [3:0] din;
  bit [3:0] e_count;
  bit rst;
  function new(string name="tx");
    super.new(name);
  endfunction
  
  function void display(string mess);
    $display($time,"class= %s : rst=%0d,load=%0d,mode=%0d,din=%0d",mess,rst,load,mode,din);
  endfunction
endclass

class seq1 extends uvm_sequence #(tx);
  `uvm_object_utils(seq1)
  function new(string name="seq1");
	super.new(name);
  endfunction
endclass

class seq extends seq1;
  `uvm_object_utils(seq);
  tx t;
  function new(string name="seq");
    super.new(name);
  endfunction
  
  task body();
    
    repeat(8)
      begin   
	t=tx::type_id::create("t");
        start_item(t);
        t.randomize() with {din<=6;};
        finish_item(t);
      //  t.display("seq");
      end
  endtask
endclass

class seq2 extends seq1;
  `uvm_object_utils(seq2)
  tx t; 
 
function new(string name="seq2");
	super.new(name);
  endfunction
  
  task body();
	repeat(3)begin
	t=tx::type_id::create("t");
	start_item(t);
	t.randomize with{din>6;};
	finish_item(t);
//	t.display("seq2");
	end
  endtask
endclass

class seqr extends uvm_sequencer #(tx);
  `uvm_component_utils(seqr);
  
  function new(string name="seqr",uvm_component parent);
    super.new(name,parent);
  endfunction
endclass

class driver extends uvm_driver #(tx);
  `uvm_component_utils(driver);
  virtual intf vif;
  conf cf;
  tx t;
  function new(string name="driver",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t=tx::type_id::create("t");
    if(!uvm_config_db #(conf)::get(this,"","hello",cf))
       `uvm_fatal("driver","mission failed in driver");
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vif=cf.vif;
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    t.rst<=0;
    @(vif.Drv) t.rst<=1;
    @(vif.Drv) t.rst<=0;
    forever begin
      seq_item_port.get_next_item(t);
      drive();
      seq_item_port.item_done();
    //  t.display("driver");
    end
  endtask

  task drive();
    @(vif.Drv);    
    vif.Drv.load<=t.load;
    vif.Drv.mode<=t.mode;
    vif.Drv.din<=t.din;
  endtask
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  tx t;
  uvm_analysis_port#(tx) mon_port;
  virtual intf vif;
  conf cf;
  
  function new(string name="monitor",uvm_component parent);
    super.new(name,parent);
    mon_port=new("mon_port",this);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t=tx::type_id::create("tx");
    if(!uvm_config_db #(conf)::get(this,"","hello",cf))
      `uvm_fatal("monitor","mission failed in monitor");
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vif=cf.vif;
  endfunction
  
  task run_phase(uvm_phase phase);
    forever begin
      mon();
      $display($time,"rst=%0d,load=%0d,mode=%0d,din=%0d,count=%0d",t.rst,t.load,t.mode,t.din,t.e_count);
    end
  endtask
  
  task mon();
    t.rst=vif.Mon.rst;
    t.load=vif.Mon.load;
    t.mode=vif.Mon.mode;
    t.din=vif.Mon.din;//@(vif.Mon);
    t.e_count=vif.Mon.count;@(vif.Mon);

  endtask
endclass


class agent extends uvm_agent;
  `uvm_component_utils(agent);

  seqr sq;
  driver drv;
  monitor mon;
  conf cf;
  
  function new(string name="agent",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    if(!uvm_config_db #(conf)::get(this,"","hello",cf))
      `uvm_fatal("agent","mission failed in agent");
     mon=monitor::type_id::create("mon",this);
    if(cf.is_active==UVM_ACTIVE)
      begin
        sq=seqr::type_id::create("sq",this);
        drv=driver::type_id::create("drv",this);
      end
  endfunction
  
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sq.seq_item_export);
  endfunction
endclass

class env extends uvm_env;
  `uvm_component_utils(env);
  conf cf;
  agent ag[];
  int num;
  
  function new(string name="env",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(conf)::get(this,"","hello",cf))
      `uvm_fatal("env","mission failed in env");
    num=cf.num;
    ag=new[num];
   //if(cf.is_active) begin
    for(int i=0;i<num;i++)
      ag[i]=agent::type_id::create($sformatf("ag[%d]",i),this);//end

  /* if(cf.is_passive) begin
    for(int i=1;i<num;i++)
      ag[i]=agent::type_id::create($sformatf("ag[%d]",i),this);end
*/
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test);
  env e;
  conf cf;
  seq s;
  seq2 s2;
  virtual intf vif;
  
  function new(string name="test",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    cf=conf::type_id::create("cf");
    e=env::type_id::create("s",this);
    s=seq::type_id::create("s");
    s2=seq2::type_id::create("s2");
    if(!uvm_config_db #(virtual intf)::get(this,"","hi",vif))
      `uvm_fatal("test","mission failed at test");
    cf.vif=vif;
    uvm_config_db #(conf)::set(this,"*","hello",cf);
  endfunction
  
  task run_phase(uvm_phase phase);
    
      phase.raise_objection(this);
      for(int i=0;i<cf.num;i++)begin
      	s.start(e.ag[i].sq);
	s2.start(e.ag[i].sq);end
      phase.drop_objection(this);
  endtask

   function void end_of_elaboration_phase(uvm_phase phase);
	uvm_top.print_topology();
	endfunction
  
endclass
	
module top;
  logic clk;
  intf vif(clk);
  counter dut(vif.clk,vif.rst,vif.load,vif.mode,vif.din,vif.count);
  
  always #5 clk=~clk;
//  bind counter count_h(vif.clk,vif.rst,vif.load,vif.mode,vif.din,vif.count);

  initial begin
    $dumpfile("dum.vcd");
    $dumpvars(0);
    clk=0;
    uvm_config_db#(virtual intf)::set(null,"*","hi",vif);
    run_test("test");
  //  #50 $finish();
  end
endmodule


