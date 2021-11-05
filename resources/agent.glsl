#version 430

// Game of Life logic shader

#define WIN_SIZE 512


#define PI 3.14159265358979323846

// Variaveis para brincar

#define SENSOR_SIZE 5 // a partir de 5 tem melhores resultados, mas chegando no limite, ou otimiza ou não dá mais
#define SENSOR_OFFSET 150.0 // valores legais sempre são maiores do que o tamanho do sensor
#define SENSOR_ANGLE PI/3 //Sempre use angulos em radianos


// Valores bons de sensor offset são entre o valor do sensor size até o 30x o valor do sensor size
//Valors bons de sensor angle estão entre pi/2 e pi/64

#define TURN_SPEED 1.0

struct Agent {
    float x;         // x coordinate of the slime command
    float y;         // y coordinate of the slime command
    float angle;  // whether to enable or disable zone
};

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// Output game of life grid buffer
layout(std430, binding = 1)  buffer slimeUpdateLayout
{
    
    Agent agentsOrr[];
};

// Command buffer
layout(std430, binding = 3) readonly restrict buffer golLayout
{
    
    float golBuffer[];
};

#define fetchGol(x, y) ((((x) < 0) || ((y) < 0) || ((x) > WIN_SIZE) || ((y) > WIN_SIZE)) \
    ? (0) \
    : golBuffer[(x) + WIN_SIZE * (y)])


#define isInside(x, y) (((x) > 5) && ((y) > 5) && ((x) < WIN_SIZE-5) && ((y) < WIN_SIZE-5))










// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}



// Compound versions of the hashing algorithm I whipped together.
uint hash( uvec2 v ) { return hash( v.x ^ hash(v.y)                         ); }
uint hash( uvec3 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z)             ); }
uint hash( uvec4 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z) ^ hash(v.w) ); }



// Construct a float with half-open range [0:1] using low 23 bits.
// All zeroes yields 0.0, all ones yields the next smallest representable value below 1.0.
float floatConstruct( uint m ) {
    const uint ieeeMantissa = 0x007FFFFFu; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000u; // 1.0 in IEEE binary32

    m &= ieeeMantissa;                     // Keep only mantissa bits (fractional part)
    m |= ieeeOne;                          // Add fractional part to 1.0

    float  f = uintBitsToFloat( m );       // Range [1:2]
    return f - 1.0;                        // Range [0:1]
}



// Pseudo-random value in half-open range [0:1].
float random( float x ) { return floatConstruct(hash(floatBitsToUint(x))); }
float random( vec2  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( vec3  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( vec4  v ) { return floatConstruct(hash(floatBitsToUint(v))); }

//Melhorar isso
float newAngle ( vec2 st){

    //return (random(st) * PI * 2.0);

    if(st.x <= 5){
        float rand = random(st);
        if(rand < 0.5){
            return (random(st) * PI/4.0);

        }else{
            return (random(st) * PI/4.0) + 7*(PI/4.0);

        }
    }else if(st.x >= WIN_SIZE-5){
        return ((random(st) * PI/2.0)) + 3.0 * (PI/4.0);
    }

    if(st.y <= 5){
        return  (PI/4.0) + (random(st) * PI/2.0); // 90 graus
    }else if(st.y >= WIN_SIZE-5){
        return 5.0 * (PI/4.0) + (random(st) * PI/2.0); // 90 graus
    }

    
}

float sense(uint agentInd, float angleOffset, float sensorOffsetDst){
    float sensorAngle = agentsOrr[agentInd].angle + angleOffset;
    vec2 sensorDir = vec2(cos(sensorAngle),sin(sensorAngle));
    vec2 sensorCenter = vec2(agentsOrr[agentInd].x,agentsOrr[agentInd].y) + (sensorDir * sensorOffsetDst);

    float sum = 0.0;

    // como paralelizar isso
    for(int i=-SENSOR_SIZE;i<SENSOR_SIZE;i++){
        for(int j=-SENSOR_SIZE;j<SENSOR_SIZE;j++){
            vec2 pos = sensorCenter + vec2(float(i),float(j));
            if(isInside(uint(pos.x),uint(pos.y))){
                sum += fetchGol(uint(pos.x),uint(pos.y));
            }
        }
    }
    return sum;
}



void steer( uint agentIndex, float turnSpeed){
    float weigthFoward = 0.0;
    float weigthLeft = 0.0;
    float weigthRigth = 0.0;

    // Otimizar aqui, maior gargalo
    weigthFoward = sense(agentIndex,0.0,SENSOR_OFFSET);
    weigthLeft = sense(agentIndex,SENSOR_ANGLE,SENSOR_OFFSET);
    weigthRigth = sense(agentIndex,-SENSOR_ANGLE,SENSOR_OFFSET);


    // weigthFoward = random(vec2(agentsOrr[agentIndex].x,agentsOrr[agentIndex].y)) * 100.0;
    // weigthLeft = random(vec2(agentsOrr[agentIndex].x,agentsOrr[agentIndex].y))* 100.0;
    // weigthRigth = random(vec2(agentsOrr[agentIndex].x,agentsOrr[agentIndex].y))* 100.0;



    float randomSteerStr = random(agentsOrr[agentIndex].angle)  + 1.0;
    //float randomSteerStr = 1.0;

    if(weigthFoward > weigthLeft && weigthFoward > weigthRigth){
        agentsOrr[agentIndex].angle += 0;
    }else if(weigthFoward < weigthLeft && weigthFoward < weigthRigth){
        agentsOrr[agentIndex].angle += ((randomSteerStr - 0.5) * 2.0) *turnSpeed;
        //agentsOrr[agentIndex].angle += 0;

    }else if( weigthRigth > weigthLeft){
        agentsOrr[agentIndex].angle -= randomSteerStr *turnSpeed;
    }
    else if(weigthLeft > weigthRigth){
        agentsOrr[agentIndex].angle += randomSteerStr *turnSpeed;
    }
}






void main()
{
    uint agentIndex = gl_GlobalInvocationID.x;
    
    

    
    if (isInside(uint(agentsOrr[agentIndex].x), uint(agentsOrr[agentIndex].y)))
    {
        steer(agentIndex, TURN_SPEED);
        agentsOrr[agentIndex].x += cos(agentsOrr[agentIndex].angle);
        agentsOrr[agentIndex].y += sin(agentsOrr[agentIndex].angle);
    }else{
        agentsOrr[agentIndex].angle = newAngle(vec2(uint(agentsOrr[agentIndex].x),uint(agentsOrr[agentIndex].y))) ;
        agentsOrr[agentIndex].x += cos(agentsOrr[agentIndex].angle) ;
        agentsOrr[agentIndex].y += sin(agentsOrr[agentIndex].angle) ;
    }
    
}