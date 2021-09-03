MEMORY
{
  ROM : ORIGIN = 0x00000000, LENGTH = 4K
  RAM : ORIGIN = 0x00001000, LENGTH = 4K
}

REGION_ALIAS("REGION_TEXT", ROM);
REGION_ALIAS("REGION_RODATA", ROM);
REGION_ALIAS("REGION_DATA", RAM);
REGION_ALIAS("REGION_BSS", RAM);
REGION_ALIAS("REGION_HEAP", RAM);
REGION_ALIAS("REGION_STACK", RAM);