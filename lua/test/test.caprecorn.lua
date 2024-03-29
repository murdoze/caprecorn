--
C = require('caprecorn')
_log = require('_log')

C.arch(C.arch.X86_64)
--C.arch(C.arch.AARCH64)
C.engine(C.engine.UNICORN)
C.disasm(C.disasm.CAPSTONE)

C.open()
_log.write("Before mmap")
C.mem.map(0x555555550000, 0x100000)
_log.write("After mmap")

C.win.begin_layout()

local dump = C.win.tab()

local dump_buf = C.buf.new("Boot dump")
local dis_buf = C.buf.new("Boot disassembly")
local reg_buf = C.buf.new("Regs")
reg_buf.opts = {
  filter = { base = false, flags = false, vector = false, segment = false, fp = false, system = false, }
}
local vector_reg_buf = C.buf.new("Vector Regs")
vector_reg_buf.opts = {
  filter = { base = false, vector = true, }
}

local total_width = dump.width()
local dis = dump.vsplit()
local dump_bottom = dis.split()
dump_bottom.height(10)
dis.width(math.floor(total_width * 0.8))
dump.focus()
local reg = dump.split()
dis.buf(dis_buf)
reg.buf(reg_buf)
C.win.end_layout()

dis_buf.on_change = function()
  C.reg.dump(reg_buf)
end

local program, stack, addr, start, size
-- program = '/bin/ls'
-- addr = 0x07c000
-- size = 142144

program = '/home/john/bin/malware/2/dance'
stack = 0x555555553000
addr  = 0x555555554000
start = 0x555555555120
size = 65536

-- program = '/home/john/src/junk/a.out'
-- addr =  0x000000
-- start = 0x000244
-- size = 4096

local fdesc = io.open(program)
if fdesc ~= nil then
  local code = fdesc:read(size)


  _log.write("Before mem write code size=" .. tostring(#code))
  C.mem.write(addr, code)
  _log.write("After mem write")
  fdesc:close()

  C.reg.sp(stack)
  C.reg.pc(start)

  C.hex.dump(dump_buf, addr, #code)
  dump_bottom.buf(dump_buf)
  C.dis.maxsize = 16384 --TODO: Why maxsize in opts does not work? 
  C.dis.dis(dis_buf, start, #code, { pc = C.reg.pc(), maxsize = 4096 })

  C.reg.dump(reg_buf)
  C.reg.dump(vector_reg_buf)

  dis.focus()
else
  print("Faled to open program file!")
end

--C.close()
