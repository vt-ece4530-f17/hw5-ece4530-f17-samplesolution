proc sendByteSerial {serialportaddr c} {
    global jtag_master 
    global log	
    set fifosize 0    
    while { $fifosize < 64 } {
	  set fifosize [master_read_32 $jtag_master [expr $serialportaddr + 4] 1]
	  set fifosize [expr ($fifosize >> 16) & 0xFF]  
    }
    foreach databyte $c {   
       master_write_8 $jtag_master $serialportaddr $databyte	  
	}
}

proc sendStringSerial  {serialportaddr s} {
    global jtag_master
    for {set i 0} {$i < [string length $s]} {incr i} {
	set mychar [string index $s $i]
	scan $mychar %c ascii
	sendByteSerial $serialportaddr $ascii
    }
}

proc readByteSerial {serialportaddr} {
    global jtag_master
    
    set data  [master_read_32 $jtag_master $serialportaddr 1]
    set char  [expr $data & 0xFF]
    set valid [expr ($data >> 15) & 0x1]
    
    if { $valid == 0 } {
	return [list 0 0]
    } else {
	return [list 1 $char]
    }   
}   

proc readStringSerial {serialportaddr} {
    global jtag_master
    
    set c [readByteSerial $serialportaddr]
    append r [format %c [lindex $c 1]]
    
    while { [lindex $c 0] == 1 } {
        set c [readByteSerial $serialportaddr]
        append r [format %c [lindex $c 1]]
    }
    return [string trimright $r [format %c 0]]    
}

# ----------------------------------------------------------------------------------
# reads one byte from debug byte address adr
proc msp430_debug_read8 {adr} {
    global rs232debug
    sendByteSerial $rs232debug [expr 0x40 + $adr]
    while 1 {
	set c [readByteSerial $rs232debug]
	if {[lindex $c 0] == 1} break;
    }
    return [lindex $c 1]
}

# reads a list of two bytes from debug byte address adr
proc msp430_debug_read16 {adr} {
    global rs232debug
    sendByteSerial $rs232debug [expr 0x0 + $adr]
    while 1 {
	set c0 [readByteSerial $rs232debug]
	if {[lindex $c0 0] == 1} break;
    }
    while 1 {
	set c1 [readByteSerial $rs232debug]
	if {[lindex $c1 0] == 1} break;
    }
    return [list [lindex $c0 1] [lindex $c1 1]]
}

# writes one byte to debug byte address adr
proc msp430_debug_write8 {adr data} {
    global rs232debug
    sendByteSerial $rs232debug [expr 0x80 + 0x40 + $adr]
    sendByteSerial $rs232debug [expr $data & 0xFF]
}

# writes a list of two bytes to debug byte address adr
proc msp430_debug_write16 {adr data} {
    global rs232debug
    sendByteSerial $rs232debug [expr 0x80 + $adr]
    sendByteSerial $rs232debug [expr [lindex $data 0] & 0xFF]
    sendByteSerial $rs232debug [expr [lindex $data 1] & 0xFF]
}

proc msp430_connect { } {
	global rs232debug
	
	sendByteSerial $rs232debug 0x80
	after 100
	sendByteSerial $rs232debug 0xC0
	sendByteSerial $rs232debug 0x00
}	

proc msp430_identify { } {
	global log
	global log
	
	set DEBUG_CPU_NR 0x18
	set DEBUG_CPU_ID_LO 0x0
	set DEBUG_CPU_ID_HI 0x1
	
	set cpunr   [msp430_debug_read16 $DEBUG_CPU_NR]
	set cpuidlo [msp430_debug_read16 $DEBUG_CPU_ID_LO]
	set cpuidhi [msp430_debug_read16 $DEBUG_CPU_ID_HI]

	set id_cpuversion  [expr  [lindex $cpuidlo 0] & 0x7]
	set id_perspace    [expr (([lindex $cpuidlo 1] >> 1) & 0x7F)*512]
	set id_mpy         [expr ([lindex $cpuidhi 0] & 0x1)]
	set id_dmemsz      [expr (([lindex $cpuidhi 0] >> 1) & 0x7F)]
	set id_dmemsz      [expr $id_dmemsz + (([lindex $cpuidhi 1] & 0x3) << 8)]
	set id_dmemsz      [expr $id_dmemsz*128]
	set id_pmemsz      [expr (([lindex $cpuidhi 1] >> 2) & 0x3F)*1024]
	
	puts $log "MSP430 version=$id_cpuversion mpy=$id_mpy dmem=$id_dmemsz pmem=$id_pmemsz"
}

proc msp430_halt_cpu { } {
    set DEBUG_CPU_CTL  0x2
    set DEBUG_CPU_STAT 0x3
    set c [msp430_debug_read8 $DEBUG_CPU_CTL]
    msp430_debug_write8 $DEBUG_CPU_CTL [expr $c | 0x60]
    msp430_debug_write8 $DEBUG_CPU_CTL [expr $c]
    msp430_debug_write8 $DEBUG_CPU_STAT 0x4
}

proc msp430_run_cpu { } {
    set DEBUG_CPU_CTL  0x2
    set DEBUG_CPU_STAT 0x3

    set c [msp430_debug_read8 $DEBUG_CPU_CTL]
    msp430_debug_write8 $DEBUG_CPU_CTL [expr $c | 0x40]
    msp430_debug_write8 $DEBUG_CPU_CTL [expr $c & 0x5F]
    msp430_debug_write8 $DEBUG_CPU_STAT 0x4

    set c [msp430_debug_read8 $DEBUG_CPU_CTL]
    msp430_debug_write8 $DEBUG_CPU_CTL [expr $c | 0x2]
    msp430_debug_write8 $DEBUG_CPU_CTL [expr $c]
}

proc msp430_writememraw { startaddress rawdata } {
    global rs232debug
	global log
    set DEBUG_MEM_CNT   0x7
    set DEBUG_MEM_ADDR 0x5
    set DEBUG_MEM_CTL  0x4

    set len [expr [llength $rawdata]/2 -1]
    msp430_debug_write16 $DEBUG_MEM_CNT [list [expr $len & 0xFF] [expr $len >> 8]]
    
    scan $startaddress 0x%2x%2x msb lsb
    msp430_debug_write16 $DEBUG_MEM_ADDR [list $lsb $msb]
    
    msp430_debug_write8 $DEBUG_MEM_CTL 3

	set rawblocks [expr [llength $rawdata]/64]
	
	for {set block 0} {$block < $rawblocks} {set block [expr $block + 1]} {
	   set thisblock [lrange $rawdata [expr $block*64] [expr $block*64 + 63]]
	   puts -nonewline "."
	   sendByteSerial $rs232debug $thisblock
	}
	puts "*"
}    

proc msp430_download_bin {rs232debug binfile} {
    global log
    
    if { [file exists $binfile] == 0 } {
	puts $log "ERROR: $binfile not found"
	return
    }
    
    # formatting as raw data
    set fp [open $binfile r]
    fconfigure $fp -translation binary
    binary scan [read $fp] c* rawdata yop
    close $fp
	
    puts $log "Downloading $binfile .."
    msp430_halt_cpu
    set startaddr [format "0x%04x" [expr 0x10000 - [llength $rawdata]]]
	set runtime [time {msp430_writememraw $startaddr $rawdata}]
    msp430_run_cpu
    puts $log "Download complete. Transfer time: $runtime"
}

# ----------------------------------------------------------------------------

proc startServer { Port CallBack } {
    set clientsocket [socket  -server $CallBack $Port]
    puts stderr "INFO: Opened socket on port [lindex [fconfigure $clientsocket -sockname] 2]"
    return $clientsocket
}

proc stopServer { clientsocket } {
    close $clientsocket
}

proc terminalReceivePacket {sock} {
    global log
    
    gets $sock line    
    puts $log "READ terminal packet $numpacket LINE from $sock: $line"    
    
    # forward this to terminal serial port
    global rs232user
    sendStringSerial $rs232user $line    
}

proc terminalClientAccept {sock addr port} {
    global terminalclient
    global log
    
    puts $log "INFO: Accept terminal client: $addr ($port)\n"
    
    set terminalclient [list $sock $addr $port]
    fconfigure $sock -buffering none
    fileevent  $sock readable [list terminalReceivePacket $sock]
}

# ----------------------------------------------------------------------------------

proc help {} {
    global argv0
    global cmdconf
    
    puts ""
    puts "USAGE   : $argv0 \[-sof   <de2115-sof-file>\]"
    puts "                        \[-bin <msp430-bin-file>\]"
    puts "                        \[-telnetport <port>\] (default $cmdconf(telnetport))"
    puts "                        \[-rs232debug <addr>\] (default $cmdconf(rs232debug))"
    puts "                        \[-rs232user <addr>\] (default $cmdconf(rs232user))"
}

catch {
    
    # MAIN - Parse arguments
    set cmdconf(sof)           notspecified
    set cmdconf(bin)           notspecified
    set cmdconf(telnetport)    19800
    set cmdconf(rs232user)     0x18
    set cmdconf(rs232debug)    0x10
    
    for {set i 0} {$i < $argc} {incr i} {
	switch -exact -- [lindex $argv $i] {
	    -sof                {set cmdconf(sof)           [lindex $argv [expr $i+1]]; incr i}
	    -bin                {set cmdconf(bin)           [lindex $argv [expr $i+1]]; incr i}
	    -telnetport         {set cmdconf(telnetport)    [lindex $argv [expr $i+1]]; incr i}
	    -rs232debug         {set cmdconf(rs232debug)    [lindex $argv [expr $i+1]]; incr i}
	    -rs232user          {set cmdconf(rs232user)     [lindex $argv [expr $i+1]]; incr i}
	    -h                  {help; return 0}
	    -help               {help; return 0}
	    default             {}
	}
    }
    
    set numpacket 0
    set log stderr
    
    # connect to board
    set device_index 0 ;
    set device [lindex [get_service_paths device] $device_index]
    
    # Configure sof if specified
    if {[string equal $cmdconf(sof) "notspecified"] == 0} {
	puts $log "INFO: Configuring SOF $cmdconf(sof)"
	if {[file exists $cmdconf(sof)] == 0} {
	    puts $log "ERROR: SOF file not found"
	    help
	    exit 1   
	}   
	device_download_sof $device $cmdconf(sof)   
	puts $log "INFO: Configuration completed"
    }
    
    # open JTAG access to RS232
    puts $log "INFO: Opening JTAG master"
    set jtag_master [lindex [get_service_paths master] 0]
    open_service master $jtag_master
    
    set rs232debug    $cmdconf(rs232debug)
    set rs232user     $cmdconf(rs232user)
    
    msp430_connect
    msp430_identify
    
    # Download bin if specified
    if {[string equal $cmdconf(bin) "notspecified"] == 0} {
	puts $log "INFO: Downloading MSP430 binary $cmdconf(bin)"
	if {[file exists $cmdconf(bin)] == 0} {
	    puts $log "ERROR: binary file not found"
	    help
	    exit 1   
	}   
	msp430_download_bin $rs232debug $cmdconf(bin)   
	puts $log "INFO: Download completed"
    } else {
	exit 0   
    }

    startServer $cmdconf(telnetport) terminalClientAccept
    vwait terminalclient

    while { 1 } {
	set nextline [readStringSerial $rs232user]
	if {[string length $nextline] > 0} {
	    puts -nonewline [lindex $terminalclient 0] $nextline
	}
	if {[string equal -length 12 $nextline "exit-console"]} {
	    break
	}
    }

    stopServer [lindex $terminalclient 0]
    
} errcode

puts "Error Code: $errcode"


#proc pollStringSerial {serialportaddr sock} {
#    set r1 [readStringSerial $serialportaddr]
#    if {[string length $r1] > 0} {
#	puts $sock $r1
#    }
#}


#proc debugReceivePacket {sock} {
#    global numpacket
#    global log
#    
#    gets $sock line    
#    puts $log "READ debug packet $numpacket LINE from $sock: $line"    
#    incr numpacket
#    
#    # forward this to debug serial port
#    global rs232debug
#    sendStringSerial $rs232debug $line
#    
#    # example loopback to other socket:
#    # global terminalclient
#    # puts [lindex $terminalclient 0] $line
#}

#proc debugClientAccept {sock addr port} {
#    global debugclient
#    global log
#    
#    puts $log "INFO: Accept debug client: $addr ($port)\n"
#    
#    set debugclient [list $sock $addr $port]
#    fconfigure $sock -buffering none
#    fileevent  $sock readable [list debugReceivePacket $sock]
#}

#    stopServer [lindex $debugclient 0]
#    stopServer [lindex $terminalclient 0]
    
#    startServer $cmdconf(port1) debugClientAccept    
#    vwait debugclient
    
#    startServer $cmdconf(port2) terminalClientAccept
#    vwait terminalclient

#    while { $numpacket < 5 } {
#	pollStringSerial $rs232debug    [lindex $debugclient 0]
#	pollStringSerial $rs232terminal [lindex $terminalclient 0]
#	vwait numpacket
#    }
    
#    stopServer [lindex $debugclient 0]
#    stopServer [lindex $terminalclient 0]
    
