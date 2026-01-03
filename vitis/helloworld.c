#include "xil_types.h"
#include "xuartps.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "xaxidma.h"
#include "xil_exception.h"
#include "xscugic.h"
#include "xil_cache.h"

/* -------------------- IMAGE CONFIG -------------------- */
#define IMAGE_WIDTH     28
#define IMAGE_HEIGHT    28
#define IMAGE_SIZE      (IMAGE_WIDTH*IMAGE_HEIGHT)

#define KERNEL_SIZE     3
#define WINDOW_SIZE     8
#define NUM_PATCHES     ((IMAGE_WIDTH-KERNEL_SIZE+1)*(IMAGE_HEIGHT-KERNEL_SIZE+1))

/* -------------------- DMA CONFIG -------------------- */
#define DMA_DEV_ID      XPAR_AXIDMA_0_DEVICE_ID

#define TX_INTR_ID      XPAR_FABRIC_AXIDMA_0_MM2S_INTROUT_VEC_ID
#define RX_INTR_ID      XPAR_FABRIC_AXIDMA_0_S2MM_INTROUT_VEC_ID

#define UART_DEVICE_ID  XPAR_PS7_UART_1_DEVICE_ID
#define INTC_DEVICE_ID  XPAR_SCUGIC_SINGLE_DEVICE_ID

#define MAX_COUNT           512
#define RX_PKT_LEN_BYTES    (MAX_COUNT * sizeof(u32))

#define INTC            XScuGic
#define INTC_HANDLER    XScuGic_InterruptHandler

/* -------------------- GLOBALS -------------------- */
static XAxiDma AxiDma;
static INTC Intc;

volatile int TxDone;
volatile int RxDone;
volatile int Error;

static u32 RxBuffer[MAX_COUNT];

/* -------------------- IM2COL -------------------- */
void im2col(u8 image[IMAGE_HEIGHT][IMAGE_WIDTH],
            u8 cols[KERNEL_SIZE*KERNEL_SIZE][NUM_PATCHES])
{
    int out_h = IMAGE_HEIGHT - KERNEL_SIZE + 1;
    int out_w = IMAGE_WIDTH  - KERNEL_SIZE + 1;
    int patch = 0;

    for (int y = 0; y < out_h; y++) {
        for (int x = 0; x < out_w; x++) {
            int k = 0;
            for (int i = 0; i < KERNEL_SIZE; i++)
                for (int j = 0; j < KERNEL_SIZE; j++)
                    cols[k++][patch] = image[y+i][x+j];
            patch++;
        }
    }
}

/* -------------------- REORDER -------------------- */
void reorder_for_dma(u8 cols[KERNEL_SIZE*KERNEL_SIZE][NUM_PATCHES],
                     u8 *buffer)
{
    int win = NUM_PATCHES / WINDOW_SIZE;
    int rem = NUM_PATCHES % WINDOW_SIZE;

    for (int w = 0; w < win; w++)
        for (int k = 0; k < KERNEL_SIZE*KERNEL_SIZE; k++)
            for (int p = 0; p < WINDOW_SIZE; p++)
                buffer[w*KERNEL_SIZE*KERNEL_SIZE*WINDOW_SIZE +
                       k*WINDOW_SIZE + p] =
                       cols[k][w*WINDOW_SIZE + p];

    if (rem) {
        int base = win*KERNEL_SIZE*KERNEL_SIZE*WINDOW_SIZE;
        for (int k = 0; k < KERNEL_SIZE*KERNEL_SIZE; k++)
            for (int p = 0; p < rem; p++)
                buffer[base + k*WINDOW_SIZE + p] =
                    cols[k][win*WINDOW_SIZE + p];
    }
}

/* -------------------- PACK U8 -> U32 -------------------- */
void pack_u8_to_u32(u8 *src, u32 *dst, int bytes)
{
    for (int i = 0; i < (bytes+3)/4; i++) dst[i] = 0;

    for (int i = 0; i < bytes; i++)
        dst[i/4] |= ((u32)src[i]) << (8*(i%4));
}

/* -------------------- TX ISR -------------------- */
static void TxIntrHandler(void *Callback)
{
    u32 IrqStatus = XAxiDma_IntrGetIrq(&AxiDma, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrAckIrq(&AxiDma, IrqStatus, XAXIDMA_DMA_TO_DEVICE);

    if (IrqStatus & XAXIDMA_IRQ_ERROR_MASK) {
        xil_printf("[TX] DMA ERROR\r\n");
        Error = 1;
        XAxiDma_Reset(&AxiDma);
        return;
    }

    if (IrqStatus & XAXIDMA_IRQ_IOC_MASK) {
        TxDone = 1;
        xil_printf("[TX] DMA DONE\r\n");
    }
}

/* -------------------- RX ISR -------------------- */
static void RxIntrHandler(void *Callback)
{
    u32 IrqStatus = XAxiDma_IntrGetIrq(&AxiDma, XAXIDMA_DEVICE_TO_DMA);
    XAxiDma_IntrAckIrq(&AxiDma, IrqStatus, XAXIDMA_DEVICE_TO_DMA);

    if (IrqStatus & XAXIDMA_IRQ_ERROR_MASK) {
        xil_printf("[RX] DMA ERROR\r\n");
        Error = 1;
        XAxiDma_Reset(&AxiDma);
        return;
    }

    if (IrqStatus & XAXIDMA_IRQ_IOC_MASK) {
        RxDone = 1;
        xil_printf("[RX] DMA DONE\r\n");
    }
}

/* -------------------- INTERRUPT SETUP -------------------- */
static int SetupIntrSystem(void)
{
    XScuGic_Config *Cfg = XScuGic_LookupConfig(INTC_DEVICE_ID);
    if (!Cfg) return XST_FAILURE;

    XScuGic_CfgInitialize(&Intc, Cfg, Cfg->CpuBaseAddress);

    XScuGic_Connect(&Intc, TX_INTR_ID,
        (Xil_InterruptHandler)TxIntrHandler, &AxiDma);
    XScuGic_Connect(&Intc, RX_INTR_ID,
        (Xil_InterruptHandler)RxIntrHandler, &AxiDma);

    XScuGic_Enable(&Intc, TX_INTR_ID);
    XScuGic_Enable(&Intc, RX_INTR_ID);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)INTC_HANDLER, &Intc);
    Xil_ExceptionEnable();

    return XST_SUCCESS;
}

/* -------------------- MAIN -------------------- */
int main(void)
{
    xil_printf("\n--- UART → TX DMA → RX DMA PIPELINE ---\r\n");

    int Status;
    XAxiDma_Config *Cfg;
    XUartPs Uart;

    static u8 image[IMAGE_HEIGHT][IMAGE_WIDTH];
    static u8 cols[KERNEL_SIZE*KERNEL_SIZE][NUM_PATCHES];

    static u8  tx_u8[KERNEL_SIZE*KERNEL_SIZE*NUM_PATCHES];
    static u32 tx_u32[(KERNEL_SIZE*KERNEL_SIZE*NUM_PATCHES + 3)/4];

    int tx_bytes = KERNEL_SIZE*KERNEL_SIZE*NUM_PATCHES;
    int tx_words = (tx_bytes + 3)/4;

    /* UART INIT */
    XUartPs_Config *Ucfg = XUartPs_LookupConfig(UART_DEVICE_ID);
    XUartPs_CfgInitialize(&Uart, Ucfg, Ucfg->BaseAddress);
    XUartPs_SetBaudRate(&Uart, 115200);

    xil_printf("[UART] Waiting for image (%d bytes)\r\n", IMAGE_SIZE);
    int recvd = 0;
    while (recvd < IMAGE_SIZE)
        recvd += XUartPs_Recv(&Uart, &image[0][0] + recvd,
                              IMAGE_SIZE - recvd);
    xil_printf("[UART] Image received\r\n");

    /* DMA INIT */
    Cfg = XAxiDma_LookupConfig(DMA_DEV_ID);
    XAxiDma_CfgInitialize(&AxiDma, Cfg);
    if (XAxiDma_HasSg(&AxiDma)) return XST_FAILURE;

    SetupIntrSystem();

    XAxiDma_IntrEnable(&AxiDma,
        XAXIDMA_IRQ_IOC_MASK | XAXIDMA_IRQ_ERROR_MASK,
        XAXIDMA_DMA_TO_DEVICE);

    XAxiDma_IntrEnable(&AxiDma,
        XAXIDMA_IRQ_IOC_MASK | XAXIDMA_IRQ_ERROR_MASK,
        XAXIDMA_DEVICE_TO_DMA);

    /* PROCESS */
    xil_printf("[CPU] Performing im2col...\r\n");
    im2col(image, cols);

    xil_printf("[CPU] Reordering data for DMA...\r\n");
    reorder_for_dma(cols, tx_u8);

    pack_u8_to_u32(tx_u8, tx_u32, tx_bytes);

    Xil_DCacheFlushRange((UINTPTR)tx_u32, tx_words*4);
    Xil_DCacheInvalidateRange((UINTPTR)RxBuffer, RX_PKT_LEN_BYTES);

    TxDone = RxDone = Error = 0;

    /* -------------------- START TX DMA FIRST -------------------- */
    xil_printf("[DMA] TX start (%d bytes)\r\n", tx_words*4);
    XAxiDma_SimpleTransfer(&AxiDma,
        (UINTPTR)tx_u32, tx_words*4,
        XAXIDMA_DMA_TO_DEVICE);

    /* DEBUG: confirm TX started */
    xil_printf("[DEBUG] TX transfer initiated, waiting for completion...\r\n");

    /* -------------------- START RX DMA -------------------- */
    xil_printf("[DMA] RX start (%d bytes)\r\n", RX_PKT_LEN_BYTES);
    XAxiDma_SimpleTransfer(&AxiDma,
        (UINTPTR)RxBuffer, RX_PKT_LEN_BYTES,
        XAXIDMA_DEVICE_TO_DMA);

    /* Wait for completion */
    while (!TxDone || !RxDone) {
        if (Error) {
            xil_printf("[ERROR] DMA operation failed!\r\n");
            return XST_FAILURE;
        }
    }

    xil_printf("[DEBUG] Both TX and RX DMA completed successfully!\r\n");

    /* -------------------- PRINT RX DATA -------------------- */
    xil_printf("\n[RX DATA]\r\n");
    for (int i = 0; i < MAX_COUNT; i++)
        xil_printf("Word %3d : 0x%08x\r\n", i, RxBuffer[i]);

    xil_printf("\n--- ALL DONE ---\r\n");
    return 0;
}
