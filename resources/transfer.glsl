#version 430

// Game of Life logic shader

#define WIN_SIZE 512

struct Agent {
    float x;         // x coordinate of the slime command
    float y;         // y coordinate of the slime command
    float angle;  // whether to enable or disable zone
};

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// Output game of life grid buffer
layout(std430, binding = 1) buffer slimeBufferLayout
{
    float slimeBuffer[]; // golBuffer[x, y] = golBuffer[x + GOL_WIDTH * y]
};

// Command buffer
layout(std430, binding = 3) readonly restrict buffer slimeUpdateLayout
{
    
    Agent agents[];
};



#define isInside(x, y) (((x) >= 0) && ((y) >= 0) && ((x) < WIN_SIZE-1) && ((y) < WIN_SIZE-1))


#define setGol(x, y, value) slimeBuffer[(x) + WIN_SIZE*(y)] = value

#define fetchGol(x, y) ((((x) < 0) || ((y) < 0) || ((x) > WIN_SIZE) || ((y) > WIN_SIZE)) \
    ? (0) \
    : slimeBuffer[(x) + WIN_SIZE * (y)])

void main()
{
    uint agentIndex = gl_GlobalInvocationID.x;
    Agent curAgent = agents[agentIndex];

    
    if (isInside(uint(curAgent.x), uint(curAgent.y)))
    {
        float orgValue = fetchGol(uint(curAgent.x), uint(curAgent.y));
        setGol(uint(curAgent.x), uint(curAgent.y),1.0);
    }
    
}