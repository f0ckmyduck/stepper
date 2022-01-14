import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, ClockCycles


@cocotb.test()
async def test_angle_to_step(dut):
    #  dut.relative_angle_i.value = 0b00011001100110011010000000000000

    # 25 MHz clock
    clock = Clock(dut.clk_i, 40, units="ns")
    cocotb.fork(clock.start())

    dut.enable_i.value = 0
    dut.relative_angle_i.value = 0b00000100000000000000000000000000

    for i in range(2):
        # Run first cycle
        print(str(i) + " cycle")
        await ClockCycles(dut.clk_i, 10, rising=True)
        
        dut.enable_i.value = 1
        # Await done signal
        await RisingEdge(dut.done_o)

        # Reset
        dut.enable_i.value = 0
        await FallingEdge(dut.done_o)
        await ClockCycles(dut.clk_i, 1000, rising=True)
