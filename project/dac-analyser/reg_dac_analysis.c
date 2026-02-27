/* ATC2603C DAC Register Decoder

- Reads and decodes all DAC registers based on datasheet
- Compile: gcc -o dac_decoder dac_decoder.c
- 
       arm-linux-gcc -o dac_decoder dac_decoder.c -static
  

*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define CODEC_REG_FILE "/sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg"

/* Register values */
typedef struct {
uint16_t reg[16];  /* Registers 0x00 to 0x0F */
} codec_regs_t;

/* Read all codec registers */
int read_codec_registers(codec_regs_t *regs)
{
FILE *fp = fopen(CODEC_REG_FILE, "r");
if (!fp) {
perror("Failed to open codec registers");
return -1;
}


char line[256];
while (fgets(line, sizeof(line), fp)) {
    unsigned int addr, val;
    if (sscanf(line, "%x: %x", &addr, &val) == 2) {
        if (addr < 16) {
            regs->reg[addr] = (uint16_t)val;
        }
    }
}

fclose(fp);
return 0;


}

/* Decode register 0x00 - AUDIOINOUT_CTL */
void decode_reg_00(uint16_t val)
{
printf("═══════════════════════════════════════════════════════════\n");
printf("REG 0x00: AUDIOINOUT_CTL (I2S Configuration)\n");
printf("  Value: 0x%04X = 0b", val);
for (int i = 15; i >= 0; i--)
    printf("%d", (val >> i) & 1);
printf("\n");
printf("───────────────────────────────────────────────────────────\n");


printf("  Bit 11   MDD (MCLK Divided):          %s\n", 
       (val & (1<<11)) ? "DIV=2" : "DIV=1");
printf("  Bit 10   HIOID (Headset IRQ):         %s\n",
       (val & (1<<10)) ? "Enabled" : "Disabled");
printf("  Bit 9    OCIEN (Over Current IRQ):    %s\n",
       (val & (1<<9)) ? "Enabled" : "Disabled");
printf("  Bit 8    OEN (I2S Output Enable):     %s\n",
       (val & (1<<8)) ? "Enabled" : "Disabled");

int ims = (val >> 5) & 0x03;
const char *ims_str[] = {"3 wires", "4 wires", "6 wires", "Reserved"};
printf("  Bit 6-5  IMS (I2S Mode):              %s\n", ims_str[ims]);
printf("\n");

}

/* Decode register 0x02 - DAC_DIGITALCTL */
void decode_reg_02(uint16_t val)
{
printf("═══════════════════════════════════════════════════════════\n");
printf("REG 0x02: DAC_DIGITALCTL (DAC Digital Control) ⭐\n");
printf("  Value: 0x%04X = 0b", val);
for (int i = 15; i >= 0; i--)
printf("%d", (val >> i) & 1);
printf("\n");
printf("───────────────────────────────────────────────────────────\n");


int dacinsel = (val >> 10) & 0x03;
const char *dacinsel_str[] = {"I2S0 (music)", "Reserved", "Reserved", "Reserved"};
printf("  Bit 11-10 DACINSEL (Input Source):   %s\n", dacinsel_str[dacinsel]);

printf("  Bit 9    DEDFL_FR (Dither):          %s %s\n",
       (val & (1<<9)) ? "✓ ENABLED" : "✗ Disabled",
       (val & (1<<9)) ? "← GOOD!" : "← Enable for better quality!");

printf("  Bit 8    DISRS (Input Sample Rate):  %s\n",
       (val & (1<<8)) ? "MCLK/128" : "MCLK/256");

int bw = (val >> 6) & 0x03;
const char *bw_str[] = {"Wide (full)", "Middle", "Narrow (GB)", "Reserved"};
printf("  Bit 7-6  DBWFL_FR (Bandwidth):       %s\n", bw_str[bw]);

int osrs = (val >> 4) & 0x03;
const char *osrs_str[] = {"MCLK/16", "MCLK/8", "MCLK/4", "MCLK/2"};
printf("  Bit 5-4  DOSRSFL_FR (Output SR):     %s\n", osrs_str[osrs]);

printf("  Bit 3    DMFR (Mute Right):          %s\n",
       (val & (1<<3)) ? "✗ MUTED" : "✓ Unmuted");
printf("  Bit 2    DMFL (Mute Left):           %s\n",
       (val & (1<<2)) ? "✗ MUTED" : "✓ Unmuted");
printf("  Bit 1    DEFR (Enable Right):        %s\n",
       (val & (1<<1)) ? "✓ Enabled" : "✗ Disabled");
printf("  Bit 0    DEFL (Enable Left):         %s\n",
       (val & (1<<0)) ? "✓ Enabled" : "✗ Disabled");
printf("\n");


}

/* Decode register 0x03 - DAC_VOLUMECTL0 */
void decode_reg_03(uint16_t val)
{
printf("═══════════════════════════════════════════════════════════\n");
printf("REG 0x03: DAC_VOLUMECTL0 (DAC Volume Control)\n");
printf("  Value: 0x%04X\n", val);
printf("───────────────────────────────────────────────────────────\n");

int vol_r = (val >> 8) & 0xFF;
int vol_l = val & 0xFF;

float db_r = (vol_r == 0) ? -72.0f : (vol_r - 0xC0) * 0.375f;
float db_l = (vol_l == 0) ? -72.0f : (vol_l - 0xC0) * 0.375f;

printf("  Bit 15-8 DACFR_VOLUME (Right):       0x%02X = %.1f dB\n", vol_r, db_r);
printf("  Bit 7-0  DACFL_VOLUME (Left):        0x%02X = %.1f dB\n", vol_l, db_l);
printf("\n");


}

/* Decode register 0x05 - DAC_ANALOG1 */
void decode_reg_05(uint16_t val)
{
printf("═══════════════════════════════════════════════════════════\n");
printf("REG 0x05: DAC_ANALOG1 (DAC Analog Control) ⭐ CRITICAL\n");
printf("  Value: 0x%04X = 0b", val);
for (int i = 15; i >= 0; i--)
printf("%d", (val >> i) & 1);
printf("\n");
printf("───────────────────────────────────────────────────────────\n");


printf("  Bit 15   MICMUTE:                    %s\n",
       (val & (1<<15)) ? "Unmuted" : "Muted");
printf("  Bit 14   FMMUTE:                     %s\n",
       (val & (1<<14)) ? "Unmuted" : "Muted");

printf("  Bit 10   DACFL_FRMUTE (Playback):    %s %s\n",
       (val & (1<<10)) ? "✓ UNMUTED" : "✗ MUTED",
       (val & (1<<10)) ? "← GOOD!" : "← CRITICAL! Must be 1!");

int paiq = (val >> 8) & 0x03;
const char *paiq_str[] = {"Smallest", "Small", "Medium", "Biggest"};
printf("  Bit 9-8  PAIQ (PA IQ Control):       %s\n", paiq_str[paiq]);

printf("  Bit 7    ZERODT (Zero Data):         %s\n",
       (val & (1<<7)) ? "Enabled" : "Disabled");

printf("  Bit 6    PASW (PA Swing):            %s\n",
       (val & (1<<6)) ? "1.6Vpp (headphone)" : "2.828Vpp (lineout)");

int volume = val & 0x3F;
printf("  Bit 5-0  VOLUME (PA Volume):         %d / 40 levels\n", volume);
printf("\n");


}

/* Decode register 0x06 - DAC_ANALOG2 */
void decode_reg_06(uint16_t val)
{
printf("═══════════════════════════════════════════════════════════\n");
printf("REG 0x06: DAC_ANALOG2 (Bias Control)\n");
printf("  Value: 0x%04X\n", val);
printf("───────────────────────────────────────────────────────────\n");


int opdacib = (val >> 12) & 0x07;
printf("  Bit 14-12 OPDACIB (DAC Bias):        %d (%s)\n", 
       opdacib, opdacib == 3 ? "Optimal" : "Adjust if needed");

int opcoib = (val >> 9) & 0x07;
printf("  Bit 11-9  OPCOIB (Common Bias):      %d (%s)\n",
       opcoib, opcoib == 3 ? "Optimal" : "Adjust if needed");

printf("  Bit 8    DACGM (Gain Mode):          %s\n",
       (val & (1<<8)) ? "Special" : "Normal");

int dalr = (val >> 6) & 0x03;
const char *dalr_str[] = {"Both off", "Left only", "Right only", "Both on"};
printf("  Bit 7-6  DALR (L/R Control):         %s\n", dalr_str[dalr]);

printf("  Bit 5    DVEN (Direct Drive):        %s\n",
       (val & (1<<5)) ? "Enabled" : "Disabled");
printf("  Bit 4    AVEN (AUX Enable):          %s\n",
       (val & (1<<4)) ? "Enabled" : "Disabled");
printf("\n");


}

/* Decode register 0x07 - DAC_ANALOG3 */
void decode_reg_07(uint16_t val)
{
printf("═══════════════════════════════════════════════════════════\n");
printf("REG 0x07: DAC_ANALOG3 (PA & DAC Enable) ⭐ CRITICAL\n");
printf("  Value: 0x%04X = 0b", val);
for (int i = 15; i >= 0; i--)
printf("%d", (val >> i) & 1);
printf("\n");
printf("───────────────────────────────────────────────────────────\n");


printf("  Bit 14   OVLS (Overload Status):     %s\n",
       (val & (1<<14)) ? "⚠ OVERLOAD!" : "Normal");

printf("  Bit 13   VLCHD (Volume Delay):       %s\n",
       (val & (1<<13)) ? "✓ Enabled (smooth)" : "Disabled");

printf("  Bit 10   BIASEN (All Bias):          %s %s\n",
       (val & (1<<10)) ? "✓ Enabled" : "✗ Disabled",
       (val & (1<<10)) ? "" : "← Must be 1!");

printf("  Bit 9    ATPLP2 (Antipop):           %s\n",
       (val & (1<<9)) ? "✓ Enabled (good!)" : "Disabled");

int opcm1ib = (val >> 7) & 0x03;
const char *curr_str[] = {"Smallest", "Small", "Medium", "Biggest"};
printf("  Bit 8-7  OPCM1IB (Bias Current):     %s\n", curr_str[opcm1ib]);

int opvroib = (val >> 4) & 0x07;
printf("  Bit 6-4  OPVROIB (VRO Bias):         %d (%s)\n",
       opvroib, opvroib == 7 ? "Biggest (good!)" : "Increase if needed");

printf("  Bit 3    PAOSEN (PA Output Stage):   %s %s\n",
       (val & (1<<3)) ? "✓ Enabled" : "✗ Disabled",
       (val & (1<<3)) ? "" : "← Must be 1!");

printf("  Bit 2    PAEN (PA Enable):           %s %s\n",
       (val & (1<<2)) ? "✓ Enabled" : "✗ Disabled",
       (val & (1<<2)) ? "" : "← Must be 1!");

printf("  Bit 1    DACEN_FL (DAC Left):        %s %s\n",
       (val & (1<<1)) ? "✓ Enabled" : "✗ Disabled",
       (val & (1<<1)) ? "" : "← Must be 1!");

printf("  Bit 0    DACEN_FR (DAC Right):       %s %s\n",
       (val & (1<<0)) ? "✓ Enabled" : "✗ Disabled",
       (val & (1<<0)) ? "" : "← Must be 1!");
printf("\n");


}

/* Overall quality assessment */
void assess_quality(codec_regs_t *regs)
{
printf("═══════════════════════════════════════════════════════════\n");
printf("AUDIO QUALITY ASSESSMENT\n");
printf("═══════════════════════════════════════════════════════════\n");


int issues = 0;
int warnings = 0;

/* Check critical bits */
printf("\n🔍 Checking critical settings...\n\n");

/* 0x02 bit 9 - Dither */
if (!(regs->reg[0x02] & (1<<9))) {
    printf("  ⚠ WARNING: DAC dither disabled (reg 0x02 bit 9)\n");
    printf("     → Enable for better audio quality\n");
    printf(" echo \"2 0x%04x\" > %s", (regs->reg[0x02] | (1<<9)), CODEC_REG_FILE);
    warnings++;
} else {
    printf("  ✓ DAC dither enabled\n");
}

/* 0x05 bit 10 - Unmute */
if (!(regs->reg[0x05] & (1<<10))) {
    printf("  ✗ CRITICAL: DAC playback MUTED (reg 0x05 bit 10)\n");
    printf("     → This is why audio is quiet/broken!\n");
    printf(" echo \"5 0x%04x\" > %s", (regs->reg[0x05] | (1<<10)), CODEC_REG_FILE);
    issues++;
} else {
    printf("  ✓ DAC playback unmuted\n");
}

/* 0x07 bit 10 - Bias */
if (!(regs->reg[0x07] & (1<<10))) {
    printf("  ✗ CRITICAL: All bias disabled (reg 0x07 bit 10)\n");
    printf(" echo \"7 0x%04x\" > %s", (regs->reg[0x07] | (1<<10)), CODEC_REG_FILE);
    issues++;
} else {
    printf("  ✓ All bias enabled\n");
}

/* 0x07 bits 3,2,1,0 - PA and DAC enable */
if ((regs->reg[0x07] & 0x0F) != 0x0F) {
    printf("  ✗ CRITICAL: PA/DAC not fully enabled (reg 0x07 bits 3-0)\n");
    printf("     Current: 0x%X, Should be: 0xF\n", regs->reg[0x07] & 0x0F);
    printf(" echo \"7 0x%04x\" > %s", (regs->reg[0x07] & 0x0F), CODEC_REG_FILE);
    issues++;
} else {
    printf("  ✓ PA and DAC fully enabled\n");
}

/* 0x07 bit 9 - Antipop */
if (!(regs->reg[0x07] & (1<<9))) {
    printf("  ⚠ WARNING: Antipop disabled (reg 0x07 bit 9)\n");
    printf("     → Enable to reduce clicks/pops\n");
    printf(" echo \"7 0x%04x\" > %s", (regs->reg[0x07] | (1<<9)), CODEC_REG_FILE);
    warnings++;
} else {
    printf("  ✓ Antipop enabled\n");
}

/* Bandwidth check */
int bw = (regs->reg[0x02] >> 6) & 0x03;
if (bw == 0) {
    printf("  ✓ Bandwidth: Wide (full quality)\n");
} else if (bw == 2) {
    printf("  ℹ Bandwidth: Narrow (GB optimized)\n");
} else {
    printf("  ℹ Bandwidth: Middle\n");
}

printf("\n");
printf("═══════════════════════════════════════════════════════════\n");
if (issues == 0 && warnings == 0) {
    printf("✨ PERFECT! Audio configuration is optimal!\n");
} else {
    printf("Summary: %d critical issue(s), %d warning(s)\n", issues, warnings);
    if (issues > 0) {
        printf("\n⚠ FIX CRITICAL ISSUES IMMEDIATELY!\n");
        printf("Run: sh /mnt/card/ultimate_audio_config.sh\n");
    }
}
printf("═══════════════════════════════════════════════════════════\n");


}

int main(int argc, char *argv[])
{
codec_regs_t regs = {0};


printf("\n");
printf("╔═══════════════════════════════════════════════════════════╗\n");
printf("║   ATC2603C DAC Register Decoder v1.0                     ║\n");
printf("║   Powkiddy X39 Pro Audio Codec Analysis                  ║\n");
printf("╚═══════════════════════════════════════════════════════════╝\n");
printf("\n");

if (read_codec_registers(&regs) < 0) {
    fprintf(stderr, "ERROR: Cannot read codec registers\n");
    fprintf(stderr, "Make sure debugfs is mounted and you have permissions\n");
    return 1;
}

/* Decode all DAC-related registers */
decode_reg_00(regs.reg[0x00]);
decode_reg_02(regs.reg[0x02]);
decode_reg_03(regs.reg[0x03]);
decode_reg_05(regs.reg[0x05]);
decode_reg_06(regs.reg[0x06]);
decode_reg_07(regs.reg[0x07]);

/* Overall assessment */
assess_quality(&regs);

printf("\n");

return 0;

}
