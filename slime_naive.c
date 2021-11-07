/*******************************************************************************************
*
*   raylib [rlgl] example - compute shader - Conway's Game of Life
*
*   NOTE: This example requires raylib OpenGL 4.3 versions for compute shaders support,
*         shaders used in this example are #version 430 (OpenGL 4.3)
*
*   This example has been created using raylib 4.0 (www.raylib.com)
*   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
*
*   Example contributed by Teddy Astie (@tsnake41) and reviewed by Ramon Santamaria (@raysan5)
*
*   Copyright (c) 2021 Teddy Astie (@tsnake41)
*
********************************************************************************************/

#include "raylib.h"
#include "rlgl.h"

#include <math.h>
#include <stdlib.h>

#include <stdio.h>

// IMPORTANT: This must match slime*.glsl slime_WIDTH constant.
// This must be a multiple of 16 (check slimeLogic compute dispatch).

// Brincar com a quantidade de agentes
// #define NUM_AGENTS 65535 // NUMERO MAXIMO 65535
//#define WIN_SIZE 980 // tem que ser igual esse valor em TODOS os arquivos


#define NUM_AGENTS 50000
 #define WIN_SIZE 512

// Game Of Life Update Command
typedef struct Agent
{
    float x; // x coordinate of the slime command
    float y; // y coordinate of the slime command
    float angle;    // whether to enable or disable zone
} Agent;

// Game Of Life Update Commands SSBO

int main(void)
{
    // Initialization
    //--------------------------------------------------------------------------------------
    // Essa engine usa o framerate pra decidir a velocidade das coisas (sem tempo pra pensar em deltaTime)
    // Ou seja +FPS + Rapido
    InitWindow(WIN_SIZE, WIN_SIZE, "compute shader - Slime Simulation");
    //SetTargetFPS(60);
    // SetTargetFPS(120);
    // SetTargetFPS(30);
    printf("%d\n", sizeof(Agent));


    const Vector2 resolution = {WIN_SIZE, WIN_SIZE};

    // Game of Life logic compute shader
    char *slimeLogicCode = LoadFileText("resources/agent.glsl");
    unsigned int slimeLogicShader = rlCompileShader(slimeLogicCode, RL_COMPUTE_SHADER);
    unsigned int slimeLogicProgram = rlLoadComputeShaderProgram(slimeLogicShader);
    UnloadFileText(slimeLogicCode);

    // Game of Life logic compute shader
    Shader slimeRenderShader = LoadShader(NULL, "resources/render.glsl");
    int resUniformLoc = GetShaderLocation(slimeRenderShader, "resolution");

    // Game of Life transfert shader
    char *slimeTransfertCode = LoadFileText("resources/transfer.glsl");
    unsigned int slimeTransfertShader = rlCompileShader(slimeTransfertCode, RL_COMPUTE_SHADER);
    unsigned int slimeTransfertProgram = rlLoadComputeShaderProgram(slimeTransfertShader);
    UnloadFileText(slimeTransfertCode);

    // SSBOs
    float ssboA = rlLoadShaderBuffer(WIN_SIZE * WIN_SIZE * sizeof(unsigned int), NULL, RL_DYNAMIC_COPY);
    // unsigned int ssboB = rlLoadShaderBuffer(WIN_SIZE * WIN_SIZE * sizeof(unsigned int), NULL, RL_DYNAMIC_COPY);

    Agent *transferBuffer = (Agent *)malloc(sizeof(Agent) * NUM_AGENTS);

    int transferSSBO = rlLoadShaderBuffer(sizeof(Agent) * NUM_AGENTS, NULL, RL_DYNAMIC_COPY);

    

    // Create a white texture of the size of the window to update
    // each pixel of the window using the fragment shader
    Image whiteImage = GenImageColor(WIN_SIZE, WIN_SIZE, WHITE);
    Texture whiteTex = LoadTextureFromImage(whiteImage);
    UnloadImage(whiteImage);
    //--------------------------------------------------------------------------------------

    // Logica de inicialização dos agentes
    for (int i = 0; i < NUM_AGENTS; i++)
    {
        //Posição inicial
        transferBuffer[i].x = WIN_SIZE/2 + ((((float)rand()/(float)(RAND_MAX)) * 2 * WIN_SIZE/2) - WIN_SIZE/2);
        transferBuffer[i].y = WIN_SIZE/2 + ((((float)rand()/(float)(RAND_MAX)) * 2 * WIN_SIZE/2) - WIN_SIZE/2);
        // transferBuffer[i].x = WIN_SIZE/2;
        // transferBuffer[i].y = WIN_SIZE/2;

        // Angulo inicial
        transferBuffer[i].angle = PI + atan2( -(transferBuffer[i].y - (float)WIN_SIZE/2) , transferBuffer[i].x - (float)WIN_SIZE/2  ); //TODO: brincar com angulos inicias
        // transferBuffer[i].angle = 0;
        // transferBuffer[i].angle = ((float)rand()/(float)(RAND_MAX)) * 2 * PI;
    }
    rlUpdateShaderBufferElements(transferSSBO, transferBuffer, sizeof(Agent) * NUM_AGENTS, 0);
    

    // Main game loop
    while (!WindowShouldClose())
    {
        // Update
        //----------------------------------------------------------------------------------

        // rlUpdateShaderBufferElements(transferSSBOAux, &transferBufferAux, sizeof(Agent) * NUM_AGENTS, 0);

        // Update agents position
        rlEnableShader(slimeLogicProgram);
        rlBindShaderBuffer(transferSSBO, 1);
        rlBindShaderBuffer(ssboA, 3);
        rlComputeShaderDispatch(NUM_AGENTS, 1, 1); // each GPU unit will process a command
        rlDisableShader();

        

        // rlUpdateShaderBufferElements(transferSSBO, &transferBuffer, sizeof(Agent) * NUM_AGENTS, 0);

        
        

        // Transfer from Agent array to texture
        rlEnableShader(slimeTransfertProgram);
        rlBindShaderBuffer(ssboA, 1);
        rlBindShaderBuffer(transferSSBO, 3);
        rlComputeShaderDispatch(NUM_AGENTS, 1, 1); // each GPU unit will process a command
        rlDisableShader();

        rlBindShaderBuffer(ssboA, 1);
        SetShaderValue(slimeRenderShader, resUniformLoc, &resolution, SHADER_UNIFORM_VEC2);
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        BeginDrawing();

        ClearBackground(BLANK);

        BeginShaderMode(slimeRenderShader);
            DrawTexture(whiteTex, 0, 0, WHITE);
        EndShaderMode();

        // DrawRectangleLines(GetMouseX() - brushSize/2, GetMouseY() - brushSize/2, brushSize, brushSize, RED);

        // DrawText("Use Mouse wheel to increase/decrease brush size", 10, 10, 20, WHITE);
        // DrawFPS(GetScreenWidth() - 100, 10);
        DrawFPS(10, 10);

        EndDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    // Unload shader buffers objects.
    rlUnloadShaderBuffer(ssboA);
    // rlUnloadShaderBuffer(ssboB);
    rlUnloadShaderBuffer(transferSSBO);

    // // Unload compute shader programs
    rlUnloadShaderProgram(slimeTransfertProgram);
    // rlUnloadShaderProgram(slimeLogicProgram);

    UnloadTexture(whiteTex);         // Unload white texture
    UnloadShader(slimeRenderShader); // Unload rendering fragment shader

    CloseWindow(); // Close window and OpenGL context
    //--------------------------------------------------------------------------------------

    return 0;
}