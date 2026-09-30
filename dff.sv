module dff(clk,rst,d,q);
	input clk,rst,d;
	output reg q;

	always @(posedge clk)
	begin
		if(rst)
			q<=0;
		else
			q<=d;	
	end
endmodule
import uvm_pkg::*;
`include "uvm_macros.svh"

interface intf(input logic clk);
  logic rst,d,q;
  
  clocking Drv@(posedge clk);
    default input #1 output #1;
    output rst,d;
  endclocking
   clocking Mon@(posedge clk);
    default input #1 output #1;
    input rst,d,q;
  endclocking
  modport drv(clocking Drv);
    modport mon(clocking Mon);
endinterface

class conf extends uvm_object;
  `uvm_object_utils(conf);
  
  virtual intf vif;
  uvm_active_passive_enum is_active=UVM_ACTIVE;
  int num=1;
  
  function new(string name="conf");
    super.new(name);
  endfunction
  
endclass
class tx extends uvm_sequence_item;
  `uvm_object_utils(tx);
  
  rand bit rst;
  rand bit d;
  bit e_q;
  
  function new(string name="tx");
    super.new(name);
  endfunction
  
  function void display(string mess);
    $display($time,"class=%s,rst=%0d,d=%0d",mess,rst,d);
   // `uvm_info("tx","done",UVM_LOW);
  endfunction
endclass
    
class seq extends uvm_sequence #(tx);
  `uvm_object_utils(seq);
  tx t;
  function new(string name="seq");
    super.new(name);
  endfunction
  
  task body();
    t=tx::type_id::create("t");
    repeat(8)
      begin
        
        start_item(t);   
        t.randomize();
        finish_item(t);
        t.display("seq");
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
  tx t;
  virtual intf vif;
  conf cf;
  
  function new(string name="driver",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t=tx::type_id::create("t");
    if(!uvm_config_db #(conf)::get(this,"","hello",cf))
      `uvm_fatal("driver","mission failed at driver");
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vif=cf.vif;
  endfunction
  
  task run_phase(uvm_phase phase);//@(vif.Drv);
    forever
      begin
//	@(vif.Drv);
        seq_item_port.get_next_item(t);
        t.display("driver");
	drive();
        seq_item_port.item_done(t);
//	@(vif.Drv);
              end
  endtask
  
  task drive();
  @(vif.Drv)
    vif.Drv.rst<=t.rst;
    vif.Drv.d<=t.d;//@(vif.Drv);
	$display("-----------------*++++++++++++");
  endtask
endclass
  
    
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  uvm_analysis_port#(tx) mon_port;
  virtual intf vif;
  tx t;
  conf cf;
  
  function new(string name="monitor",uvm_component parent);
    super.new(name,parent);
    mon_port=new("mon_port",parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(conf)::get(this,"","hello",cf))
      `uvm_fatal("monitor","mission failed monitor");
    t=tx::type_id::create("t");
  endfunction
  
  function void connect_phase(uvm_phase phase);
    vif=cf.vif;
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
       data();	
	mon_port.write(t);
   //   t.display("monitor");
	$display($time,"in monitor rst=%d,d=%d,q=%d",t.rst,t.d,t.e_q);
 end
  endtask
  
  task data();
   @(vif.Mon)
    t.rst=vif.Mon.rst;
    t.d=vif.Mon.d;
    t.e_q=vif.Mon.q;//@(vif.Mon);
  endtask
endclass

class scb extends uvm_scoreboard;
  `uvm_component_utils(scb)
  uvm_analysis_imp#(tx,scb)scb_port;
  tx t;
  int a;
  int e_y;
  
  function new(string name="scb",uvm_component parent);
	super.new(name,parent);
	scb_port=new("scb_port",this);
  endfunction
  function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	t=tx::type_id::create("t");
  endfunction
/*
  task run_phase(uvm_phase phase);
	super.run_phase(phase);
	forever begin
	comp();
	$display("*********scb****** ex=%d,out=%d",t.e_q,a);end
  endtask*/

  function void write(tx t);
	t.display("scb");
	$display($time,"in scoreboard ****** rst=%d,d=%d,q=%d",t.rst,t.d,t.e_q);
	if(t.rst)
		a<=0;
	else
		a<=e_y;
	if(e_y==a)
		$display("pass  a=%d == q=%d",e_y,t.e_q);
	else
		$display("fail  a=%d == q=%d",a,t.e_q);
	e_y=t.e_q;

  endfunction
endclass



class agent extends uvm_agent;
  `uvm_component_utils(agent);
  conf cf;
  driver drv;
  seqr sq;
  monitor mon;
  function new(string name="agent",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(conf)::get(this,"","hello",cf))
    `uvm_fatal("agent","mission failed agent");
    mon=monitor::type_id::create("mon",this);
    if(cf.is_active==UVM_ACTIVE)begin
       sq=seqr::type_id::create("sq",this);
      drv=driver::type_id::create("drv",this);
     end
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    //if(!uvm_config_db #(conf)::get(this,"","hello",cf))
  	  drv.seq_item_port.connect(sq.seq_item_export);
  endfunction
  
endclass  
  
    
class env extends uvm_env;
  `uvm_component_utils(env);
  conf cf;
  agent ag[];
  int i;
  scb sb; 
  function new(string name="env",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(conf)::get(this,"","hello",cf))
      `uvm_fatal("env","mission failed in env");
    ag=new[cf.num];
    for(int i=0;i<cf.num;i++) begin
      ag[i]=agent::type_id::create($sformatf("ag[%0d]",i),this);
	end
    sb=scb::type_id::create("sb",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	for(int i=0;i<cf.num;i++)
		ag[i].mon.mon_port.connect(sb.scb_port);
  endfunction

endclass
    
class test extends uvm_test;
  `uvm_component_utils(test);
  seq se;
  virtual intf vif;
  conf cf;
  env e;
  
  function new(string name="test",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cf=conf::type_id::create("cf");
    if(!uvm_config_db #(virtual intf)::get(this,"","hi",vif))
      `uvm_fatal("test","mission failed test");
    cf.vif=vif;
    uvm_config_db #(conf)::set(this,"*","hello",cf);
    e=env::type_id::create("e",this);
    se=seq::type_id::create("se");
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    for(int i=0;i<cf.num;i++)
      se.start(e.ag[i].sq);
    phase.drop_objection(this);
  endtask
  
  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology;
  endfunction

endclass
    
    
module top;
  logic clk;
  intf vif(clk);
  dff dut(vif.clk,vif.rst,vif.d,vif.q);
  
  always #5 clk=~clk;
  
  initial begin
    clk=0;
    uvm_config_db #(virtual intf)::set(null,"*","hi",vif);
    run_test("test");
    #40 $finish();
  end
endmodule
			 
